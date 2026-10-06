package com.example.smriti_jyoti

import android.content.Context
import android.content.SharedPreferences
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import android.util.Log
import org.json.JSONArray
import org.json.JSONObject
import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.Date
import java.util.Locale
import kotlin.math.max

class StepCounterManager private constructor(private val context: Context) : SensorEventListener {

    companion object {
        private const val TAG = "StepCounterManager"
        private const val PREFS_NAME = "aninai_steps"

        private const val KEY_TRACKING_ENABLED = "tracking_enabled"
        private const val KEY_DAILY_GOAL = "daily_goal"
        private const val KEY_CURRENT_DATE = "current_date"
        private const val KEY_TODAY_STEPS = "today_steps"
        private const val KEY_TODAY_MORNING = "today_morning"
        private const val KEY_TODAY_AFTERNOON = "today_afternoon"
        private const val KEY_TODAY_EVENING = "today_evening"
        private const val KEY_BASELINE_SENSOR_VAL = "baseline_sensor_val"
        private const val KEY_ACCUMULATED_BEFORE_BASELINE = "accumulated_before_baseline"
        private const val KEY_LAST_SENSOR_VAL = "last_sensor_val"
        private const val KEY_DAILY_HISTORY = "daily_history_json"

        @Volatile
        private var INSTANCE: StepCounterManager? = null

        fun getInstance(context: Context): StepCounterManager {
            return INSTANCE ?: synchronized(this) {
                INSTANCE ?: StepCounterManager(context.applicationContext).also { INSTANCE = it }
            }
        }
    }

    private val prefs: SharedPreferences = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
    private val sensorManager: SensorManager? = context.getSystemService(Context.SENSOR_SERVICE) as? SensorManager
    private val stepCounterSensor: Sensor? = sensorManager?.getDefaultSensor(Sensor.TYPE_STEP_COUNTER)
    private val stepDetectorSensor: Sensor? = sensorManager?.getDefaultSensor(Sensor.TYPE_STEP_DETECTOR)

    private var isListening = false
    private var onStepUpdateListener: ((Int) -> Unit)? = null
    private val stepUpdateListeners = java.util.concurrent.CopyOnWriteArrayList<(Int) -> Unit>()

    init {
        checkDateRollover()
    }

    fun isSensorAvailable(): Boolean {
        return stepCounterSensor != null || stepDetectorSensor != null
    }

    fun isTrackingEnabled(): Boolean {
        return prefs.getBoolean(KEY_TRACKING_ENABLED, false)
    }

    fun setTrackingEnabled(enabled: Boolean) {
        prefs.edit().putBoolean(KEY_TRACKING_ENABLED, enabled).apply()
        if (enabled) {
            registerSensorListener()
        } else {
            unregisterSensorListener()
        }
    }

    fun setStepUpdateListener(listener: ((Int) -> Unit)?) {
        onStepUpdateListener = listener
    }

    fun addStepUpdateListener(listener: (Int) -> Unit) {
        if (!stepUpdateListeners.contains(listener)) {
            stepUpdateListeners.add(listener)
        }
    }

    fun removeStepUpdateListener(listener: (Int) -> Unit) {
        stepUpdateListeners.remove(listener)
    }

    private fun notifyStepListeners(steps: Int) {
        try {
            onStepUpdateListener?.invoke(steps)
        } catch (e: Exception) {
            Log.e(TAG, "Error in legacy step update listener", e)
        }
        for (listener in stepUpdateListeners) {
            try {
                listener.invoke(steps)
            } catch (e: Exception) {
                Log.e(TAG, "Error in step update listener", e)
            }
        }
    }

    @Synchronized
    fun registerSensorListener() {
        if (isListening || sensorManager == null) return

        checkDateRollover()

        var registered = false
        if (stepCounterSensor != null) {
            registered = sensorManager.registerListener(
                this,
                stepCounterSensor,
                SensorManager.SENSOR_DELAY_UI
            )
            Log.d(TAG, "Registered TYPE_STEP_COUNTER: $registered")
        }

        if (!registered && stepDetectorSensor != null) {
            registered = sensorManager.registerListener(
                this,
                stepDetectorSensor,
                SensorManager.SENSOR_DELAY_UI
            )
            Log.d(TAG, "Registered TYPE_STEP_DETECTOR fallback: $registered")
        }

        isListening = registered
    }

    @Synchronized
    fun unregisterSensorListener() {
        if (!isListening || sensorManager == null) return
        try {
            sensorManager.unregisterListener(this)
        } catch (e: Exception) {
            Log.e(TAG, "Error unregistering sensor listener", e)
        }
        isListening = false
    }

    override fun onSensorChanged(event: SensorEvent?) {
        if (event == null) return

        checkDateRollover()

        when (event.sensor.type) {
            Sensor.TYPE_STEP_COUNTER -> {
                handleStepCounterEvent(event.values[0])
            }
            Sensor.TYPE_STEP_DETECTOR -> {
                handleStepDetectorEvent()
            }
        }
    }

    override fun onAccuracyChanged(sensor: Sensor?, accuracy: Int) {
        // No action required for step counter accuracy changes
    }

    private fun getTodayDateString(): String {
        val sdf = SimpleDateFormat("yyyy-MM-dd", Locale.getDefault())
        return sdf.format(Date())
    }

    @Synchronized
    fun checkDateRollover() {
        val todayStr = getTodayDateString()
        val savedDate = prefs.getString(KEY_CURRENT_DATE, "") ?: ""

        if (savedDate.isEmpty()) {
            prefs.edit()
                .putString(KEY_CURRENT_DATE, todayStr)
                .putInt(KEY_TODAY_STEPS, 0)
                .putInt(KEY_TODAY_MORNING, 0)
                .putInt(KEY_TODAY_AFTERNOON, 0)
                .putInt(KEY_TODAY_EVENING, 0)
                .putFloat(KEY_BASELINE_SENSOR_VAL, -1f)
                .putInt(KEY_ACCUMULATED_BEFORE_BASELINE, 0)
                .apply()
            return
        }

        if (savedDate != todayStr) {
            // Archive previous day's data into history
            val prevSteps = prefs.getInt(KEY_TODAY_STEPS, 0)
            val prevGoal = getDailyGoal()
            val prevMorning = prefs.getInt(KEY_TODAY_MORNING, 0)
            val prevAfternoon = prefs.getInt(KEY_TODAY_AFTERNOON, 0)
            val prevEvening = prefs.getInt(KEY_TODAY_EVENING, 0)

            archiveDayToHistory(
                dateStr = savedDate,
                steps = prevSteps,
                goal = prevGoal,
                morning = prevMorning,
                afternoon = prevAfternoon,
                evening = prevEvening
            )

            // Start clean new day record
            val lastSensorVal = prefs.getFloat(KEY_LAST_SENSOR_VAL, -1f)
            prefs.edit()
                .putString(KEY_CURRENT_DATE, todayStr)
                .putInt(KEY_TODAY_STEPS, 0)
                .putInt(KEY_TODAY_MORNING, 0)
                .putInt(KEY_TODAY_AFTERNOON, 0)
                .putInt(KEY_TODAY_EVENING, 0)
                .putFloat(KEY_BASELINE_SENSOR_VAL, lastSensorVal) // Reset baseline to current reading
                .putInt(KEY_ACCUMULATED_BEFORE_BASELINE, 0)
                .apply()

            Log.d(TAG, "Date rolled over from $savedDate to $todayStr. Archived $prevSteps steps.")
        }
    }

    @Synchronized
    private fun handleStepCounterEvent(sensorValue: Float) {
        if (sensorValue <= 0) return

        var baseline = prefs.getFloat(KEY_BASELINE_SENSOR_VAL, -1f)
        var accumulated = prefs.getInt(KEY_ACCUMULATED_BEFORE_BASELINE, 0)
        var currentToday = prefs.getInt(KEY_TODAY_STEPS, 0)
        val lastSensor = prefs.getFloat(KEY_LAST_SENSOR_VAL, -1f)

        // Case 1: First reading of the day
        if (baseline < 0) {
            baseline = sensorValue
            accumulated = currentToday
            prefs.edit()
                .putFloat(KEY_BASELINE_SENSOR_VAL, baseline)
                .putInt(KEY_ACCUMULATED_BEFORE_BASELINE, accumulated)
                .putFloat(KEY_LAST_SENSOR_VAL, sensorValue)
                .apply()
            Log.d(TAG, "Initialized baseline: $baseline, accumulated: $accumulated")
            return
        }

        // Case 2: Device reboot or sensor reset detected (current reading < last known reading)
        if (sensorValue < lastSensor) {
            Log.d(TAG, "Reboot/sensor reset detected! sensorValue: $sensorValue < lastSensor: $lastSensor")
            accumulated = currentToday
            baseline = sensorValue
            prefs.edit()
                .putFloat(KEY_BASELINE_SENSOR_VAL, baseline)
                .putInt(KEY_ACCUMULATED_BEFORE_BASELINE, accumulated)
                .putFloat(KEY_LAST_SENSOR_VAL, sensorValue)
                .apply()
        }

        val deltaFromBaseline = max(0, (sensorValue - baseline).toInt())
        val calculatedTodaySteps = accumulated + deltaFromBaseline
        val newStepsDiff = calculatedTodaySteps - currentToday

        if (newStepsDiff > 0) {
            distributeStepsToTimeSlot(newStepsDiff)
            prefs.edit()
                .putInt(KEY_TODAY_STEPS, calculatedTodaySteps)
                .putFloat(KEY_LAST_SENSOR_VAL, sensorValue)
                .apply()

            Log.d(TAG, "Steps updated: $calculatedTodaySteps (+$newStepsDiff)")
            notifyStepListeners(calculatedTodaySteps)
        } else {
            prefs.edit().putFloat(KEY_LAST_SENSOR_VAL, sensorValue).apply()
        }
    }

    @Synchronized
    private fun handleStepDetectorEvent() {
        val currentToday = prefs.getInt(KEY_TODAY_STEPS, 0) + 1
        distributeStepsToTimeSlot(1)
        prefs.edit().putInt(KEY_TODAY_STEPS, currentToday).apply()
        notifyStepListeners(currentToday)
    }

    private fun distributeStepsToTimeSlot(stepsToAdd: Int) {
        val hour = Calendar.getInstance().get(Calendar.HOUR_OF_DAY)
        when (hour) {
            in 6..11 -> {
                val current = prefs.getInt(KEY_TODAY_MORNING, 0)
                prefs.edit().putInt(KEY_TODAY_MORNING, current + stepsToAdd).apply()
            }
            in 12..17 -> {
                val current = prefs.getInt(KEY_TODAY_AFTERNOON, 0)
                prefs.edit().putInt(KEY_TODAY_AFTERNOON, current + stepsToAdd).apply()
            }
            else -> {
                // Evening & Night (18..23 and 0..5)
                val current = prefs.getInt(KEY_TODAY_EVENING, 0)
                prefs.edit().putInt(KEY_TODAY_EVENING, current + stepsToAdd).apply()
            }
        }
    }

    private fun archiveDayToHistory(
        dateStr: String,
        steps: Int,
        goal: Int,
        morning: Int,
        afternoon: Int,
        evening: Int
    ) {
        try {
            val historyRaw = prefs.getString(KEY_DAILY_HISTORY, "{}") ?: "{}"
            val historyJson = JSONObject(historyRaw)

            val dayRecord = JSONObject().apply {
                put("date", dateStr)
                put("steps", steps)
                put("goal", goal)
                put("distanceKm", calculateDistanceKm(steps))
                put("activeMinutes", calculateActiveMinutes(steps))
                put("calories", calculateCalories(steps))
                put("morning", morning)
                put("afternoon", afternoon)
                put("evening", evening)
                put("updatedAt", SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss'Z'", Locale.US).format(Date()))
            }

            historyJson.put(dateStr, dayRecord)
            prefs.edit().putString(KEY_DAILY_HISTORY, historyJson.toString()).apply()
        } catch (e: Exception) {
            Log.e(TAG, "Error archiving day to history", e)
        }
    }

    fun getDailyGoal(): Int {
        return prefs.getInt(KEY_DAILY_GOAL, 10000)
    }

    fun setDailyGoal(goal: Int) {
        val cleanGoal = if (goal <= 0) 10000 else goal
        prefs.edit().putInt(KEY_DAILY_GOAL, cleanGoal).apply()
    }

    fun calculateDistanceKm(steps: Int): Double {
        // Average stride length assumed ~0.762m
        val meters = steps * 0.762
        return (meters / 1000.0 * 100).toInt() / 100.0
    }

    fun calculateActiveMinutes(steps: Int): Int {
        // Standard walking cadence is approx 100-110 steps per minute
        return steps / 100
    }

    fun calculateCalories(steps: Int): Int {
        // Approx 0.04 calories burned per step walking
        return (steps * 0.04).toInt()
    }

    fun getTodayStepsData(): Map<String, Any> {
        checkDateRollover()
        val steps = prefs.getInt(KEY_TODAY_STEPS, 0)
        val goal = getDailyGoal()
        val morning = prefs.getInt(KEY_TODAY_MORNING, 0)
        val afternoon = prefs.getInt(KEY_TODAY_AFTERNOON, 0)
        val evening = prefs.getInt(KEY_TODAY_EVENING, 0)

        return mapOf(
            "date" to getTodayDateString(),
            "steps" to steps,
            "goal" to goal,
            "distanceKm" to calculateDistanceKm(steps),
            "activeMinutes" to calculateActiveMinutes(steps),
            "calories" to calculateCalories(steps),
            "morning" to morning,
            "afternoon" to afternoon,
            "evening" to evening,
            "isSensorAvailable" to isSensorAvailable(),
            "isTrackingEnabled" to isTrackingEnabled()
        )
    }

    fun getDailyStepHistory(): Map<String, Any> {
        checkDateRollover()
        val historyRaw = prefs.getString(KEY_DAILY_HISTORY, "{}") ?: "{}"
        val result = mutableMapOf<String, Any>()
        try {
            val historyJson = JSONObject(historyRaw)
            val keys = historyJson.keys()
            while (keys.hasNext()) {
                val key = keys.next()
                val record = historyJson.getJSONObject(key)
                val map = mutableMapOf<String, Any>()
                val innerKeys = record.keys()
                while (innerKeys.hasNext()) {
                    val k = innerKeys.next()
                    map[k] = record.get(k)
                }
                result[key] = map
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error parsing history JSON", e)
        }
        return result
    }
}
