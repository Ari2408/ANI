package com.example.smriti_jyoti

import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.speech.tts.TextToSpeech
import java.util.Locale

class NotificationActionReceiver : BroadcastReceiver() {

    companion object {
        private var actionTtsEngine: TextToSpeech? = null
    }

    override fun onReceive(context: Context?, intent: Intent?) {
        if (context == null || intent == null) return

        val reminderId = intent.getStringExtra("reminderId") ?: ""
        val notificationId = intent.getIntExtra("notificationId", -1)
        val action = intent.action ?: ""

        // Cancel notification when action button is tapped on drag-down tray
        if (notificationId != -1) {
            val notificationManager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.cancel(notificationId)
        }

        val title = intent.getStringExtra("title") ?: ""
        val isHydrationIntent = intent.getBooleanExtra("isHydration", false) || action.contains("ACTION_LOG_WATER") || reminderId == "hyd" || reminderId.startsWith("hyd_")
        val isRoutine = reminderId.startsWith("act_") || reminderId.contains("act") || reminderId.contains("routine") || title.contains("Daily Activity") || title.contains("தினசரி") || title.contains("dinasari")

        if (action == "com.purb_chetana.ACTION_TAKEN" && reminderId.isNotEmpty() && !isHydrationIntent) {
            val compPrefs = context.getSharedPreferences("purb_chetana_completed_reminders", Context.MODE_PRIVATE)
            compPrefs.edit().putBoolean(reminderId, true).apply()

            // Cancel scheduled alarm and follow-up 1-minute retry alarms for attempt 2 and attempt 3
            try {
                val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as android.app.AlarmManager
                val baseId = (reminderId.hashCode().let { if (it < 0) -it else it }) % 100000
                val alarmIds = listOf(baseId, baseId * 10 + 2, baseId * 10 + 3)
                for (retryId in alarmIds) {
                    val cancelIntent = Intent(context, AlarmReceiver::class.java).apply {
                        setAction("com.purb_chetana.ACTION_TRIGGER_ALARM")
                    }
                    val pi = PendingIntent.getBroadcast(
                        context,
                        retryId,
                        cancelIntent,
                        PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                    )
                    alarmManager.cancel(pi)
                }
            } catch (_: Exception) {}
        }

        // Speak native TTS response
        speakNativeActionVoice(context.applicationContext, isRoutine, isHydrationIntent, action)

        if (MainActivity.activityInstance != null) {
            MainActivity.sendNotificationActionToFlutter(reminderId, action)
        } else {
            val launchIntent = context.packageManager.getLaunchIntentForPackage(context.packageName)?.apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP
                putExtra("reminderId", reminderId)
                putExtra("actionType", action)
            }
            if (launchIntent != null) {
                context.startActivity(launchIntent)
            }
        }
    }

    private fun speakNativeActionVoice(appContext: Context, isRoutine: Boolean, isHydration: Boolean, action: String) {
        val isTaken = action.contains("ACTION_TAKEN") || action.contains("ACTION_STARTED") || action.contains("ACTION_LOG_WATER")
        val textToSpeak = if (isHydration || action.contains("ACTION_LOG_WATER")) {
            "Great job! 1 glass of water logged. Stay hydrated and healthy!"
        } else if (isRoutine) {
            if (isTaken) {
                "Great job! Completing your daily activity routine keeps you active and healthy!"
            } else {
                "Please complete your daily activity routine soon. Staying active is very important!"
            }
        } else {
            if (isTaken) {
                "Great job! Taking your medicine on time keeps you healthy and strong!"
            } else {
                "Please take your medicine soon. Your health and well-being are very important!"
            }
        }

        try {
            actionTtsEngine?.stop()
            actionTtsEngine?.shutdown()
        } catch (_: Exception) {}

        actionTtsEngine = TextToSpeech(appContext) { status ->
            if (status == TextToSpeech.SUCCESS && actionTtsEngine != null) {
                try {
                    actionTtsEngine?.setLanguage(Locale("en", "IN"))
                    actionTtsEngine?.setPitch(0.98f)
                    actionTtsEngine?.setSpeechRate(0.85f)
                    actionTtsEngine?.speak(textToSpeak, TextToSpeech.QUEUE_FLUSH, null, "ActionVoiceTTS")
                } catch (_: Exception) {}
            }
        }
    }
}
