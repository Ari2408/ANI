package com.example.smriti_jyoti

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.os.Build
import android.os.IBinder
import android.util.Log
import androidx.core.app.NotificationCompat

class StepTrackingService : Service() {

    companion object {
        private const val TAG = "StepTrackingService"
        const val NOTIFICATION_ID = 98989
        const val CHANNEL_ID = "aninai_step_tracking"
        const val CHANNEL_NAME = "Elder Activity & Step Tracking"

        const val ACTION_START = "com.aninai.ACTION_START_STEP_TRACKING"
        const val ACTION_STOP = "com.aninai.ACTION_STOP_STEP_TRACKING"

        @Volatile
        var isServiceRunning: Boolean = false
            private set

        fun startService(context: Context) {
            try {
                val intent = Intent(context, StepTrackingService::class.java).apply {
                    action = ACTION_START
                }
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    context.startForegroundService(intent)
                } else {
                    context.startService(intent)
                }
            } catch (e: Exception) {
                Log.e(TAG, "Error starting StepTrackingService", e)
            }
        }

        fun stopService(context: Context) {
            try {
                val intent = Intent(context, StepTrackingService::class.java).apply {
                    action = ACTION_STOP
                }
                context.startService(intent)
            } catch (e: Exception) {
                Log.e(TAG, "Error stopping StepTrackingService", e)
            }
        }
    }

    private lateinit var stepManager: StepCounterManager

    override fun onCreate() {
        super.onCreate()
        stepManager = StepCounterManager.getInstance(applicationContext)
        createNotificationChannel()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val action = intent?.action

        if (action == ACTION_STOP) {
            Log.d(TAG, "Stopping step tracking service...")
            isServiceRunning = false
            stepManager.setTrackingEnabled(false)
            stopForeground(true)
            stopSelf()
            return START_NOT_STICKY
        }

        Log.d(TAG, "Starting step tracking service in foreground...")
        isServiceRunning = true

        val initialSteps = stepManager.getTodayStepsData()["steps"] as? Int ?: 0
        val notification = buildTrackingNotification(initialSteps)

        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                if (Build.VERSION.SDK_INT >= 34) {
                    startForeground(
                        NOTIFICATION_ID,
                        notification,
                        ServiceInfo.FOREGROUND_SERVICE_TYPE_HEALTH
                    )
                } else {
                    startForeground(
                        NOTIFICATION_ID,
                        notification,
                        ServiceInfo.FOREGROUND_SERVICE_TYPE_MANIFEST
                    )
                }
            } else {
                startForeground(NOTIFICATION_ID, notification)
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error in startForeground with type, falling back", e)
            try {
                startForeground(NOTIFICATION_ID, notification)
            } catch (e2: Exception) {
                Log.e(TAG, "Fallback startForeground failed", e2)
            }
        }

        stepManager.setTrackingEnabled(true)
        stepManager.addStepUpdateListener(stepListener)

        return START_STICKY
    }

    private val stepListener: (Int) -> Unit = { currentSteps ->
        updateNotification(currentSteps)
    }

    override fun onDestroy() {
        Log.d(TAG, "StepTrackingService onDestroy called")
        isServiceRunning = false
        stepManager.removeStepUpdateListener(stepListener)
        stepManager.unregisterSensorListener()
        super.onDestroy()
    }

    override fun onBind(intent: Intent?): IBinder? {
        return null
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            val channel = NotificationChannel(
                CHANNEL_ID,
                CHANNEL_NAME,
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Notifies that elder activity & step tracking is actively counting steps"
                enableVibration(false)
                setShowBadge(false)
            }
            notificationManager.createNotificationChannel(channel)
        }
    }

    private fun buildTrackingNotification(steps: Int): android.app.Notification {
        val launchIntent = packageManager.getLaunchIntentForPackage(packageName)?.apply {
            flags = Intent.FLAG_ACTIVITY_CLEAR_TOP or Intent.FLAG_ACTIVITY_SINGLE_TOP
        }

        val flags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        } else {
            PendingIntent.FLAG_UPDATE_CURRENT
        }
        val pendingIntent = PendingIntent.getActivity(this, NOTIFICATION_ID, launchIntent, flags)

        var iconRes = applicationInfo.icon
        if (iconRes == 0) {
            iconRes = R.mipmap.ic_launcher
        }

        val stepText = if (steps > 0) "Today: $steps steps" else "Counting your daily steps in the background"

        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setSmallIcon(iconRes)
            .setContentTitle("Activity tracking is active")
            .setContentText(stepText)
            .setContentIntent(pendingIntent)
            .setOngoing(true)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setCategory(NotificationCompat.CATEGORY_SERVICE)
            .build()
    }

    private fun updateNotification(steps: Int) {
        val notification = buildTrackingNotification(steps)
        val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        notificationManager.notify(NOTIFICATION_ID, notification)
    }
}
