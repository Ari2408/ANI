package com.example.smriti_jyoti

import android.animation.AnimatorSet
import android.animation.ArgbEvaluator
import android.animation.ObjectAnimator
import android.animation.ValueAnimator
import android.app.Activity
import android.app.KeyguardManager
import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.graphics.Typeface
import android.graphics.drawable.GradientDrawable
import android.os.Build
import android.os.Bundle
import android.os.PowerManager
import android.view.Gravity
import android.view.View
import android.view.WindowInsets
import android.view.WindowInsetsController
import android.view.WindowManager
import android.view.animation.AccelerateDecelerateInterpolator
import android.view.animation.OvershootInterpolator
import android.graphics.BitmapFactory
import android.widget.ImageView
import android.widget.Button
import android.widget.FrameLayout
import android.widget.LinearLayout
import android.widget.ScrollView
import android.widget.TextView
import android.widget.Toast

class FullScreenAlarmActivity : Activity() {

    private var wakeLock: PowerManager.WakeLock? = null
    private var currentLangCode: String = "en"
    private var isAcknowledged: Boolean = false
    private var isLockTaskActive: Boolean = false

    private var bgAnimator: ValueAnimator? = null
    private var iconAnimatorSet: AnimatorSet? = null
    private var ringAnimatorSet: AnimatorSet? = null
    private var btnPulseAnimatorSet: AnimatorSet? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // 1. Configure Window Flags to Turn Screen On and Show Over Lockscreen
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
            setShowWhenLocked(true)
            setTurnScreenOn(true)
        } else {
            @Suppress("DEPRECATION")
            window.addFlags(
                WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
                        WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON or
                        WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON
            )
        }

        window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)

        // 2. Enable Immersive Sticky Mode to hide navigation bar & status bar
        enableImmersiveMode()

        // 3. Acquire Partial WakeLock
        try {
            val powerManager = getSystemService(Context.POWER_SERVICE) as PowerManager
            wakeLock = powerManager.newWakeLock(
                PowerManager.PARTIAL_WAKE_LOCK or PowerManager.ACQUIRE_CAUSES_WAKEUP,
                "Aninai:FullScreenAlarmWakeLock"
            )
            wakeLock?.acquire(30000)
        } catch (e: Exception) {
            android.util.Log.e("AninaiAlarm", "Error acquiring WakeLock in FullScreenAlarmActivity", e)
        }

        // 4. Extract Intent Extras
        val reminderId = intent.getStringExtra("reminderId") ?: ""
        val notificationId = intent.getIntExtra("notificationId", (System.currentTimeMillis() % 100000).toInt())
        val title = intent.getStringExtra("title") ?: "Aninai Scheduled Reminder"
        val body = intent.getStringExtra("body") ?: "Time for your scheduled reminder."
        val rawTakenLabel = intent.getStringExtra("takenLabel") ?: ""
        val rawYetToTakeLabel = intent.getStringExtra("yetToTakeLabel") ?: ""
        val isHydration = intent.getBooleanExtra("isHydration", false)
        val langCode = intent.getStringExtra("langCode") ?: "en"
        val medicineImagePath = intent.getStringExtra("medicineImagePath") ?: ""
        val pillsCount = intent.getStringExtra("pillsCount") ?: ""
        currentLangCode = langCode

        val isRoutine = reminderId.startsWith("act_") || reminderId.contains("act") || reminderId.contains("routine") ||
                title.contains("Daily Activity") || title.contains("தினசரி") || title.contains("dinasari")
        val isAppt = reminderId.startsWith("apt_") || reminderId.contains("apt") || reminderId.contains("appointment") ||
                title.contains("Appointment") || title.contains("சந்திப்பு") || title.contains("sandhippu") || title.contains("Doctor")
        val disableAnimation = isRoutine || isAppt

        val takenLabel = if (isHydration) {
            if (langCode == "ta") "💧 1 டம்ளர் தண்ணீர் பதிவுசெய்" else "💧 Log 1 Glass Water"
        } else if (isAppt) {
            if (langCode == "ta") "✅ சென்றேன்" else "✅ Attended"
        } else if (isRoutine) {
            if (langCode == "ta") "✅ தொடங்கப்பட்டது" else "✅ Started"
        } else if (rawTakenLabel.isNotEmpty() && rawTakenLabel != "takenBtn" && rawTakenLabel != "startedBtn" && rawTakenLabel != "attendedBtn" && rawTakenLabel != "Taken") {
            rawTakenLabel
        } else {
            if (langCode == "ta") "✅ எடுத்துக்கொண்டேன்" else "✅ Taken"
        }

        val yetToTakeLabel = if (isHydration) {
            if (langCode == "ta") "⏰ பின்னர் நினைவூட்டு" else "⏰ Remind Later"
        } else if (isAppt) {
            if (langCode == "ta") "⏳ செல்லவில்லை" else "⏳ Not Attended"
        } else if (isRoutine) {
            if (langCode == "ta") "⏳ தொடங்கவில்லை" else "⏳ Not Started"
        } else if (rawYetToTakeLabel.isNotEmpty() && rawYetToTakeLabel != "yetToTakeBtn" && rawYetToTakeLabel != "notStartedBtn" && rawYetToTakeLabel != "notAttendedBtn" && rawYetToTakeLabel != "Yet to Take") {
            rawYetToTakeLabel
        } else {
            if (langCode == "ta") "⏳ எடுக்கவில்லை" else "⏳ Yet to Take"
        }

        // 5. Build Root View with Animated Gradient Background
        val rootLayout = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER_HORIZONTAL
            setPadding(48, 64, 48, 64)
        }

        val gradient = GradientDrawable(
            GradientDrawable.Orientation.TOP_BOTTOM,
            intArrayOf(Color.parseColor("#0D1B2A"), Color.parseColor("#1B263B"), Color.parseColor("#0D1B2A"))
        )
        rootLayout.background = gradient

        val scrollView = ScrollView(this).apply {
            isFillViewport = true
            addView(rootLayout)
        }

        // Animated Background Evaluator
        if (!disableAnimation) {
            val colorStart = Color.parseColor("#0D1B2A")
            val colorMid = Color.parseColor("#1E3A8A")
            val colorEnd = Color.parseColor("#311B92")

            bgAnimator = ValueAnimator.ofObject(ArgbEvaluator(), colorStart, colorMid, colorEnd, colorStart).apply {
                duration = 4000
                repeatCount = ValueAnimator.INFINITE
                repeatMode = ValueAnimator.REVERSE
                addUpdateListener { anim ->
                    val current = anim.animatedValue as Int
                    val animatedGrad = GradientDrawable(
                        GradientDrawable.Orientation.TOP_BOTTOM,
                        intArrayOf(current, Color.parseColor("#1B263B"), Color.parseColor("#0F172A"))
                    )
                    rootLayout.background = animatedGrad
                }
                start()
            }
        }

        // 7. Icon Badge Container with Pulsing Glow Ring
        val iconContainer = FrameLayout(this).apply {
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.WRAP_CONTENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
            ).apply {
                gravity = Gravity.CENTER_HORIZONTAL
                setMargins(0, 16, 0, 24)
            }
        }

        val ringView = View(this).apply {
            layoutParams = FrameLayout.LayoutParams(260, 260, Gravity.CENTER)
            background = GradientDrawable().apply {
                shape = GradientDrawable.OVAL
                setColor(Color.parseColor("#1E40AF"))
                setStroke(6, Color.parseColor("#38BDF8"))
            }
            alpha = 0.5f
        }
        iconContainer.addView(ringView)

        val iconBadge = TextView(this).apply {
            text = if (isHydration) "💧" else if (isRoutine) "🏃‍♂️" else if (isAppt) "🏥" else "💊"
            textSize = 72f
            gravity = Gravity.CENTER
            layoutParams = FrameLayout.LayoutParams(
                FrameLayout.LayoutParams.WRAP_CONTENT,
                FrameLayout.LayoutParams.WRAP_CONTENT,
                Gravity.CENTER
            )
        }
        iconContainer.addView(iconBadge)
        rootLayout.addView(iconContainer)

        // Display Uploaded Medicine Image from Gallery (if available)
        if (medicineImagePath.isNotEmpty() && java.io.File(medicineImagePath).exists()) {
            try {
                val bitmap = BitmapFactory.decodeFile(medicineImagePath)
                if (bitmap != null) {
                    val density = resources.displayMetrics.density
                    val imgPx = (200 * density).toInt()
                    val imgView = ImageView(this).apply {
                        layoutParams = LinearLayout.LayoutParams(imgPx, imgPx).apply {
                            gravity = Gravity.CENTER_HORIZONTAL
                            setMargins(0, 8, 0, 20)
                        }
                        scaleType = ImageView.ScaleType.CENTER_CROP
                        setImageBitmap(bitmap)
                        background = GradientDrawable().apply {
                            cornerRadius = 32f
                            setStroke(6, Color.parseColor("#38BDF8"))
                        }
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
                            clipToOutline = true
                        }
                    }
                    rootLayout.addView(imgView)
                }
            } catch (e: Exception) {
                android.util.Log.e("AninaiAlarm", "Error decoding medicine image in FullScreenAlarmActivity", e)
            }
        }

        // Display Pills Count Badge on Lock Screen
        val effectivePills = if (pillsCount.isNotEmpty()) pillsCount else ""
        if (effectivePills.isNotEmpty() || (!isRoutine && !isAppt && !isHydration)) {
            val pillsBadgeText = if (effectivePills.isNotEmpty()) {
                if (langCode == "ta") "💊 மாத்திரைகளின் எண்ணிக்கை: $effectivePills" else "💊 Number of Pills: $effectivePills"
            } else {
                ""
            }
            if (pillsBadgeText.isNotEmpty()) {
                val pillsBadgeTv = TextView(this).apply {
                    text = pillsBadgeText
                    textSize = 18f
                    setTextColor(Color.parseColor("#38BDF8"))
                    typeface = Typeface.DEFAULT_BOLD
                    gravity = Gravity.CENTER
                    setPadding(32, 14, 32, 14)
                    background = GradientDrawable().apply {
                        setColor(Color.parseColor("#1E293B"))
                        cornerRadius = 24f
                        setStroke(3, Color.parseColor("#38BDF8"))
                    }
                    layoutParams = LinearLayout.LayoutParams(
                        LinearLayout.LayoutParams.WRAP_CONTENT,
                        LinearLayout.LayoutParams.WRAP_CONTENT
                    ).apply {
                        gravity = Gravity.CENTER_HORIZONTAL
                        setMargins(0, 4, 0, 20)
                    }
                }
                rootLayout.addView(pillsBadgeTv)
            }
        }

        // Pulsing Icon & Ring Animations
        if (!disableAnimation) {
            val iconScaleX = ObjectAnimator.ofFloat(iconBadge, View.SCALE_X, 1.0f, 1.22f, 1.0f)
            val iconScaleY = ObjectAnimator.ofFloat(iconBadge, View.SCALE_Y, 1.0f, 1.22f, 1.0f)
            iconScaleX.repeatCount = ValueAnimator.INFINITE
            iconScaleY.repeatCount = ValueAnimator.INFINITE

            iconAnimatorSet = AnimatorSet().apply {
                playTogether(iconScaleX, iconScaleY)
                duration = 1400
                interpolator = AccelerateDecelerateInterpolator()
                start()
            }

            val ringScaleX = ObjectAnimator.ofFloat(ringView, View.SCALE_X, 0.95f, 1.45f, 0.95f)
            val ringScaleY = ObjectAnimator.ofFloat(ringView, View.SCALE_Y, 0.95f, 1.45f, 0.95f)
            val ringAlpha = ObjectAnimator.ofFloat(ringView, View.ALPHA, 0.6f, 0.1f, 0.6f)
            ringScaleX.repeatCount = ValueAnimator.INFINITE
            ringScaleY.repeatCount = ValueAnimator.INFINITE
            ringAlpha.repeatCount = ValueAnimator.INFINITE

            ringAnimatorSet = AnimatorSet().apply {
                playTogether(ringScaleX, ringScaleY, ringAlpha)
                duration = 1400
                interpolator = AccelerateDecelerateInterpolator()
                start()
            }
        }

        // 8. Reminder Title with Animated Slide-Up
        val titleTv = TextView(this).apply {
            text = title
            textSize = 28f
            setTextColor(Color.WHITE)
            typeface = Typeface.DEFAULT_BOLD
            gravity = Gravity.CENTER
            setPadding(0, 16, 0, 16)
            alpha = if (disableAnimation) 1f else 0f
            translationY = if (disableAnimation) 0f else 60f
        }
        rootLayout.addView(titleTv)

        // 9. Reminder Body with Animated Slide-Up
        val bodyTv = TextView(this).apply {
            text = body
            textSize = 18f
            setTextColor(Color.parseColor("#CBD5E1"))
            gravity = Gravity.CENTER
            setPadding(0, 0, 0, 40)
            alpha = if (disableAnimation) 1f else 0f
            translationY = if (disableAnimation) 0f else 60f
        }
        rootLayout.addView(bodyTv)

        // 10. Instruction Tag
        val noticeTv = TextView(this).apply {
            text = if (langCode == "ta") "தயவுசெய்து ஒரு விருப்பத்தைத் தேர்ந்தெடுக்கவும்" else "Please select one of the two options below to acknowledge:"
            textSize = 14f
            setTextColor(Color.parseColor("#FBBF24"))
            gravity = Gravity.CENTER
            setPadding(0, 8, 0, 48)
            alpha = if (disableAnimation) 1f else 0f
            translationY = if (disableAnimation) 0f else 60f
        }
        rootLayout.addView(noticeTv)

        // 11. Button Container & Action Buttons
        val buttonLayout = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
            )
            alpha = if (disableAnimation) 1f else 0f
            translationY = if (disableAnimation) 0f else 80f
        }

        // Option 1 Button (Green / Taken)
        val btnTaken = Button(this).apply {
            text = takenLabel
            textSize = 20f
            setTextColor(Color.WHITE)
            typeface = Typeface.DEFAULT_BOLD
            val bgDrawable = GradientDrawable().apply {
                setColor(Color.parseColor("#15803D"))
                cornerRadius = 28f
                setStroke(4, Color.parseColor("#4ADE80"))
            }
            background = bgDrawable
            setPadding(24, 36, 24, 36)
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
            ).apply {
                setMargins(0, 0, 0, 24)
            }
            setOnClickListener {
                handleOptionSelection(reminderId, notificationId, isHydration, isTaken = true, title = title)
            }
        }
        buttonLayout.addView(btnTaken)

        // Option 2 Button (Amber/Orange / Yet to Take)
        val btnYetToTake = Button(this).apply {
            text = yetToTakeLabel
            textSize = 20f
            setTextColor(Color.WHITE)
            typeface = Typeface.DEFAULT_BOLD
            val bgDrawable = GradientDrawable().apply {
                setColor(Color.parseColor("#C2410C"))
                cornerRadius = 28f
                setStroke(4, Color.parseColor("#FB923C"))
            }
            background = bgDrawable
            setPadding(24, 36, 24, 36)
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
            )
            setOnClickListener {
                handleOptionSelection(reminderId, notificationId, isHydration, isTaken = false, title = title)
            }
        }
        buttonLayout.addView(btnYetToTake)

        rootLayout.addView(buttonLayout)
        setContentView(scrollView)

        // 12. Entrance Staggered Slide-In Animations
        if (!disableAnimation) {
            titleTv.animate().alpha(1f).translationY(0f).setDuration(600).setStartDelay(200).setInterpolator(OvershootInterpolator(1.2f)).start()
            bodyTv.animate().alpha(1f).translationY(0f).setDuration(600).setStartDelay(350).start()
            noticeTv.animate().alpha(1f).translationY(0f).setDuration(600).setStartDelay(450).start()
            buttonLayout.animate().alpha(1f).translationY(0f).setDuration(700).setStartDelay(600).setInterpolator(OvershootInterpolator(1.1f)).start()

            // 13. Subtle Continuous Pulse on Option 1 Button
            val btnScaleX = ObjectAnimator.ofFloat(btnTaken, View.SCALE_X, 1.0f, 1.03f, 1.0f)
            val btnScaleY = ObjectAnimator.ofFloat(btnTaken, View.SCALE_Y, 1.0f, 1.03f, 1.0f)
            btnScaleX.repeatCount = ValueAnimator.INFINITE
            btnScaleY.repeatCount = ValueAnimator.INFINITE

            btnPulseAnimatorSet = AnimatorSet().apply {
                playTogether(btnScaleX, btnScaleY)
                duration = 1200
                interpolator = AccelerateDecelerateInterpolator()
                start()
            }
        }
    }

    override fun onResume() {
        super.onResume()
        enableImmersiveMode()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP && !isAcknowledged) {
            try {
                startLockTask()
                isLockTaskActive = true
            } catch (e: Exception) {
                android.util.Log.e("AninaiAlarm", "startLockTask error in onResume", e)
            }
        }
    }

    override fun onWindowFocusChanged(hasFocus: Boolean) {
        super.onWindowFocusChanged(hasFocus)
        if (!hasFocus && !isAcknowledged) {
            enableImmersiveMode()
            try {
                @Suppress("DEPRECATION")
                sendBroadcast(Intent(Intent.ACTION_CLOSE_SYSTEM_DIALOGS))
            } catch (_: Exception) {}
        }
    }

    override fun onUserLeaveHint() {
        super.onUserLeaveHint()
        if (!isAcknowledged) {
            val msg = if (currentLangCode == "ta") "நினைவூட்டலை உறுதிப்படுத்த ஏதேனும் 2 விருப்பங்களில் ஒன்றை அழுத்தவும்!" else "Please select one of the two options to acknowledge!"
            Toast.makeText(this, msg, Toast.LENGTH_SHORT).show()
            val reorderIntent = Intent(this, FullScreenAlarmActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_REORDER_TO_FRONT
            }
            startActivity(reorderIntent)
        }
    }

    override fun onPause() {
        super.onPause()
        if (!isAcknowledged) {
            val reorderIntent = Intent(this, FullScreenAlarmActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_REORDER_TO_FRONT
            }
            startActivity(reorderIntent)
        }
    }

    override fun onStop() {
        super.onStop()
        if (!isAcknowledged) {
            val reorderIntent = Intent(this, FullScreenAlarmActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_REORDER_TO_FRONT
            }
            startActivity(reorderIntent)
        }
    }

    override fun onKeyDown(keyCode: Int, event: android.view.KeyEvent?): Boolean {
        if (!isAcknowledged) {
            if (keyCode == android.view.KeyEvent.KEYCODE_BACK ||
                keyCode == android.view.KeyEvent.KEYCODE_HOME ||
                keyCode == android.view.KeyEvent.KEYCODE_APP_SWITCH ||
                keyCode == android.view.KeyEvent.KEYCODE_MENU) {
                val msg = if (currentLangCode == "ta") "நினைவூட்டலை உறுதிப்படுத்த ஏதேனும் 2 விருப்பங்களில் ஒன்றை அழுத்தவும்!" else "Please select one of the two options to acknowledge!"
                Toast.makeText(this, msg, Toast.LENGTH_SHORT).show()
                return true
            }
        }
        return super.onKeyDown(keyCode, event)
    }

    @Suppress("DEPRECATION")
    @Deprecated("Deprecated in Java")
    override fun onBackPressed() {
        val msg = if (currentLangCode == "ta") "நினைவூட்டலை உறுதிப்படுத்த ஏதேனும் 2 விருப்பங்களில் ஒன்றை அழுத்தவும்!" else "Please select one of the two options to acknowledge!"
        Toast.makeText(this, msg, Toast.LENGTH_SHORT).show()
    }

    private fun enableImmersiveMode() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            window.setDecorFitsSystemWindows(false)
            window.insetsController?.let { controller ->
                controller.hide(WindowInsets.Type.statusBars() or WindowInsets.Type.navigationBars())
                controller.systemBarsBehavior = WindowInsetsController.BEHAVIOR_SHOW_TRANSIENT_BARS_BY_SWIPE
            }
        } else {
            @Suppress("DEPRECATION")
            window.decorView.systemUiVisibility = (
                View.SYSTEM_UI_FLAG_IMMERSIVE_STICKY
                or View.SYSTEM_UI_FLAG_LAYOUT_STABLE
                or View.SYSTEM_UI_FLAG_LAYOUT_HIDE_NAVIGATION
                or View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN
                or View.SYSTEM_UI_FLAG_HIDE_NAVIGATION
                or View.SYSTEM_UI_FLAG_FULLSCREEN
            )
        }
    }

    private fun handleOptionSelection(reminderId: String, notificationId: Int, isHydration: Boolean, isTaken: Boolean, title: String) {
        isAcknowledged = true
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP && isLockTaskActive) {
            try {
                stopLockTask()
                isLockTaskActive = false
            } catch (e: Exception) {
                android.util.Log.e("AninaiAlarm", "stopLockTask error", e)
            }
        }
        try {
            val actionName = if (isHydration && isTaken) {
                "com.aninai.ACTION_LOG_WATER"
            } else if (isTaken) {
                "com.aninai.ACTION_TAKEN"
            } else {
                "com.aninai.ACTION_YET_TO_TAKE"
            }

            val broadcastIntent = Intent(this, NotificationActionReceiver::class.java).apply {
                action = actionName
                putExtra("reminderId", reminderId)
                putExtra("notificationId", notificationId)
                putExtra("title", title)
                putExtra("isHydration", isHydration)
            }
            sendBroadcast(broadcastIntent)
        } catch (e: Exception) {
            android.util.Log.e("AninaiAlarm", "Error sending broadcast from FullScreenAlarmActivity", e)
        } finally {
            stopAllAnimators()
            releaseWakeLock()
            finishAndRemoveTask()
        }
    }

    private fun stopAllAnimators() {
        try { bgAnimator?.cancel() } catch (_: Exception) {}
        try { iconAnimatorSet?.cancel() } catch (_: Exception) {}
        try { ringAnimatorSet?.cancel() } catch (_: Exception) {}
        try { btnPulseAnimatorSet?.cancel() } catch (_: Exception) {}
    }

    private fun releaseWakeLock() {
        try {
            if (wakeLock?.isHeld == true) {
                wakeLock?.release()
                wakeLock = null
            }
        } catch (_: Exception) {}
    }

    override fun onDestroy() {
        super.onDestroy()
        stopAllAnimators()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP && isLockTaskActive) {
            try {
                stopLockTask()
                isLockTaskActive = false
            } catch (_: Exception) {}
        }
        releaseWakeLock()
    }
}
