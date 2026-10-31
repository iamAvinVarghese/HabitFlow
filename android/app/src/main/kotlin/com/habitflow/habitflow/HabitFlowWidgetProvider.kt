package com.habitflow.habitflow

import android.app.AlarmManager
import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.graphics.Color
import android.net.Uri
import android.os.Bundle
import android.util.Log
import android.view.View
import android.widget.RemoteViews
import org.json.JSONArray
import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.Date
import java.util.Locale

/**
 * HabitFlowWidgetProvider
 *
 * Android AppWidgetProvider for the HabitFlow home screen widget.
 * Reads serialized task/habit data written by Flutter's WidgetService
 * via the home_widget package (SharedPreferences).
 *
 * Three visual sizes are supported:
 *   - Small  (2×2): counts + progress bar
 *   - Medium (4×2): up to 3 task rows + progress bar
 *   - Large  (4×4): up to 5 tasks + 4 habits + quick-add button
 */
class HabitFlowWidgetProvider : AppWidgetProvider() {

    companion object {
        private const val TAG = "HabitFlowWidget"

        /** Must match the app group ID set in WidgetService.dart */
        private const val PREFS_NAME = "FlutterSharedPreferences"

        // Custom intent actions for widget taps
        const val ACTION_OPEN_TASKS = "com.habitflow.habitflow.OPEN_TASKS"
        const val ACTION_OPEN_HABITS = "com.habitflow.habitflow.OPEN_HABITS"
        const val ACTION_ADD_TASK = "com.habitflow.habitflow.ADD_TASK"
        const val ACTION_OPEN_TASK = "com.habitflow.habitflow.OPEN_TASK"
        const val ACTION_COMPLETE_TASK = "com.habitflow.habitflow.COMPLETE_TASK"
        const val ACTION_COMPLETE_HABIT = "com.habitflow.habitflow.COMPLETE_HABIT"
        const val EXTRA_TASK_ID = "task_id"
        const val EXTRA_HABIT_ID = "habit_id"

        // SharedPreferences keys (must match WidgetService.dart)
        private const val KEY_TASKS_JSON = "flutter.widget_tasks_json"
        private const val KEY_HABITS_JSON = "flutter.widget_habits_json"
        private const val KEY_PENDING_TASKS = "flutter.widget_pending_tasks"
        private const val KEY_COMPLETED_TASKS = "flutter.widget_completed_tasks"
        private const val KEY_TOTAL_HABITS = "flutter.widget_total_habits"
        private const val KEY_COMPLETED_HABITS = "flutter.widget_completed_habits"
        private const val KEY_COMPLETION_PCT = "flutter.widget_completion_pct"
        private const val KEY_STREAK = "flutter.widget_streak"

        // Priority index values (must match TaskPriority enum order in Dart)
        private const val PRIORITY_HIGH = 0
        private const val PRIORITY_MEDIUM = 1
        // PRIORITY_LOW = 2

        // Priority colors
        private val PRIORITY_COLORS = mapOf(
            PRIORITY_HIGH to "#FFFF6B6B",    // red
            PRIORITY_MEDIUM to "#FFFF9F43",  // orange
            2 to "#FF6BCB77"                 // green (low)
        )

        /**
         * Called externally to force all widget instances to redraw.
         */
        fun requestUpdate(context: Context) {
            val manager = AppWidgetManager.getInstance(context)
            val ids = manager.getAppWidgetIds(
                ComponentName(context, HabitFlowWidgetProvider::class.java)
            )
            if (ids.isNotEmpty()) {
                val intent = Intent(context, HabitFlowWidgetProvider::class.java).apply {
                    action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
                    putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, ids)
                }
                context.sendBroadcast(intent)
            }
        }

        /**
         * Schedule midnight AlarmManager to reset the widget display every day.
         */
        fun scheduleMidnightRefresh(context: Context) {
            val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager

            val intent = Intent(context, WidgetRefreshReceiver::class.java).apply {
                action = WidgetRefreshReceiver.ACTION_MIDNIGHT_REFRESH
            }
            val pendingIntent = PendingIntent.getBroadcast(
                context, 1001, intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )

            // Fire at next midnight
            val midnight = Calendar.getInstance().apply {
                add(Calendar.DAY_OF_YEAR, 1)
                set(Calendar.HOUR_OF_DAY, 0)
                set(Calendar.MINUTE, 0)
                set(Calendar.SECOND, 0)
                set(Calendar.MILLISECOND, 0)
            }

            try {
                alarmManager.setExact(
                    AlarmManager.RTC_WAKEUP,
                    midnight.timeInMillis,
                    pendingIntent
                )
                Log.d(TAG, "Midnight refresh scheduled for ${midnight.time}")
            } catch (e: SecurityException) {
                // Fallback: use inexact alarm
                alarmManager.set(AlarmManager.RTC_WAKEUP, midnight.timeInMillis, pendingIntent)
            }
        }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Lifecycle
    // ─────────────────────────────────────────────────────────────────────────

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        Log.d(TAG, "onUpdate: ${appWidgetIds.size} widget(s)")
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)

        for (widgetId in appWidgetIds) {
            val options = appWidgetManager.getAppWidgetOptions(widgetId)
            val views = buildViews(context, prefs, widgetId, options)
            appWidgetManager.updateAppWidget(widgetId, views)
        }

        // Ensure midnight refresh is scheduled
        scheduleMidnightRefresh(context)
    }

    override fun onAppWidgetOptionsChanged(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int,
        newOptions: Bundle
    ) {
        // Called when user resizes the widget — rebuild with new size
        Log.d(TAG, "onAppWidgetOptionsChanged: widget $appWidgetId resized")
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val views = buildViews(context, prefs, appWidgetId, newOptions)
        appWidgetManager.updateAppWidget(appWidgetId, views)
    }

    override fun onEnabled(context: Context) {
        super.onEnabled(context)
        scheduleMidnightRefresh(context)
        Log.d(TAG, "Widget enabled — midnight refresh scheduled")
    }

    override fun onDisabled(context: Context) {
        super.onDisabled(context)
        // Cancel midnight alarm when last widget is removed
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val intent = Intent(context, WidgetRefreshReceiver::class.java).apply {
            action = WidgetRefreshReceiver.ACTION_MIDNIGHT_REFRESH
        }
        val pendingIntent = PendingIntent.getBroadcast(
            context, 1001, intent,
            PendingIntent.FLAG_NO_CREATE or PendingIntent.FLAG_IMMUTABLE
        )
        pendingIntent?.let { alarmManager.cancel(it) }
        Log.d(TAG, "All widgets removed — midnight refresh cancelled")
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)

        when (intent.action) {
            ACTION_OPEN_TASKS -> openApp(context, "habitflow://tasks")
            ACTION_OPEN_HABITS -> openApp(context, "habitflow://habits")
            ACTION_ADD_TASK -> openApp(context, "habitflow://tasks/add")
            ACTION_OPEN_TASK -> {
                val taskId = intent.getStringExtra(EXTRA_TASK_ID) ?: return
                openApp(context, "habitflow://tasks?id=$taskId")
            }
            ACTION_COMPLETE_TASK -> {
                val taskId = intent.getStringExtra(EXTRA_TASK_ID) ?: return
                openApp(context, "habitflow://complete-task?id=$taskId")
            }
            ACTION_COMPLETE_HABIT -> {
                val habitId = intent.getStringExtra(EXTRA_HABIT_ID) ?: return
                openApp(context, "habitflow://complete-habit?id=$habitId")
            }
        }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // View Building
    // ─────────────────────────────────────────────────────────────────────────

    /**
     * Determines widget size from options bundle and builds the appropriate RemoteViews.
     * Thresholds:
     *   - Width >= 250dp AND Height >= 250dp → Large
     *   - Width >= 200dp → Medium
     *   - Otherwise → Small
     */
    private fun buildViews(
        context: Context,
        prefs: SharedPreferences,
        widgetId: Int,
        options: Bundle
    ): RemoteViews {
        val minWidth = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH, 110)
        val minHeight = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_HEIGHT, 110)

        return when {
            minWidth >= 250 && minHeight >= 250 -> buildLargeViews(context, prefs, widgetId)
            minWidth >= 200 -> buildMediumViews(context, prefs, widgetId)
            else -> buildSmallViews(context, prefs, widgetId)
        }
    }

    // ── Small ─────────────────────────────────────────────────────────────

    private fun buildSmallViews(
        context: Context,
        prefs: SharedPreferences,
        widgetId: Int
    ): RemoteViews {
        val views = RemoteViews(context.packageName, R.layout.widget_small)

        val pendingTasks = prefs.getInt(KEY_PENDING_TASKS, 0)
        val completionPct = prefs.getInt(KEY_COMPLETION_PCT, 0)
        val streak = prefs.getInt(KEY_STREAK, 0)

        views.setTextViewText(R.id.tv_pending_count_small, pendingTasks.toString())
        views.setTextViewText(R.id.tv_habit_pct_small, "$completionPct%")
        views.setProgressBar(R.id.progress_habits_small, 100, completionPct, false)
        views.setTextViewText(R.id.tv_streak_small, "$streak day streak")

        // Tap whole widget → open tasks
        views.setOnClickPendingIntent(
            R.id.widget_small_root,
            makeOpenPendingIntent(context, ACTION_OPEN_TASKS, widgetId * 10 + 1)
        )

        return views
    }

    // ── Medium ────────────────────────────────────────────────────────────

    private fun buildMediumViews(
        context: Context,
        prefs: SharedPreferences,
        widgetId: Int
    ): RemoteViews {
        val views = RemoteViews(context.packageName, R.layout.widget_medium)

        val pendingTasks = prefs.getInt(KEY_PENDING_TASKS, 0)
        val completionPct = prefs.getInt(KEY_COMPLETION_PCT, 0)
        val completedHabits = prefs.getInt(KEY_COMPLETED_HABITS, 0)
        val totalHabits = prefs.getInt(KEY_TOTAL_HABITS, 0)
        val streak = prefs.getInt(KEY_STREAK, 0)
        val tasksJson = prefs.getString(KEY_TASKS_JSON, "[]") ?: "[]"

        // Header
        views.setTextViewText(R.id.tv_date_medium, todayLabel())
        views.setTextViewText(R.id.tv_pending_count_medium, pendingTasks.toString())
        views.setTextViewText(R.id.tv_habit_pct_medium, "$completionPct%")

        // Progress
        views.setProgressBar(R.id.progress_habits_medium, 100, completionPct, false)
        views.setTextViewText(R.id.tv_habits_done_medium, "$completedHabits/$totalHabits habits")
        views.setTextViewText(R.id.tv_streak_medium, "$streak day streak")

        // Task rows
        val tasks = parseTasks(tasksJson).filter { !it.isCompleted }.take(3)

        val rowIds = listOf(
            Triple(R.id.task_row_1, R.id.task_title_1, R.id.task_time_1),
            Triple(R.id.task_row_2, R.id.task_title_2, R.id.task_time_2),
            Triple(R.id.task_row_3, R.id.task_title_3, R.id.task_time_3)
        )
        val dotIds = listOf(R.id.task_priority_dot_1, R.id.task_priority_dot_2, R.id.task_priority_dot_3)

        var hasTasks = false
        for (i in rowIds.indices) {
            if (i < tasks.size) {
                hasTasks = true
                val task = tasks[i]
                val (rowId, titleId, timeId) = rowIds[i]
                views.setViewVisibility(rowId, View.VISIBLE)
                views.setTextViewText(titleId, task.title)
                views.setTextViewText(timeId, task.reminderTime ?: "")
                views.setInt(dotIds[i], "setBackgroundColor",
                    Color.parseColor(PRIORITY_COLORS[task.priority] ?: "#FF6BCB77"))
                // Tap → open task
                views.setOnClickPendingIntent(
                    rowId,
                    makeTaskPendingIntent(context, ACTION_OPEN_TASK, task.id, widgetId * 100 + i)
                )
            } else {
                views.setViewVisibility(rowIds[i].first, View.GONE)
            }
        }

        views.setViewVisibility(R.id.tv_no_tasks_medium, if (hasTasks) View.GONE else View.VISIBLE)

        // Tap header → open app
        views.setOnClickPendingIntent(
            R.id.widget_medium_root,
            makeOpenPendingIntent(context, ACTION_OPEN_TASKS, widgetId * 10 + 2)
        )

        return views
    }

    // ── Large ─────────────────────────────────────────────────────────────

    private fun buildLargeViews(
        context: Context,
        prefs: SharedPreferences,
        widgetId: Int
    ): RemoteViews {
        val views = RemoteViews(context.packageName, R.layout.widget_large)

        val pendingTasks = prefs.getInt(KEY_PENDING_TASKS, 0)
        val completedTasks = prefs.getInt(KEY_COMPLETED_TASKS, 0)
        val completionPct = prefs.getInt(KEY_COMPLETION_PCT, 0)
        val streak = prefs.getInt(KEY_STREAK, 0)
        val completedHabits = prefs.getInt(KEY_COMPLETED_HABITS, 0)
        val totalHabits = prefs.getInt(KEY_TOTAL_HABITS, 0)
        val tasksJson = prefs.getString(KEY_TASKS_JSON, "[]") ?: "[]"
        val habitsJson = prefs.getString(KEY_HABITS_JSON, "[]") ?: "[]"

        // Header
        views.setTextViewText(R.id.tv_date_large, todayLabel())
        views.setTextViewText(
            R.id.tv_task_summary_large,
            "$pendingTasks pending · $completedTasks done"
        )

        // Tasks (up to 5)
        val tasks = parseTasks(tasksJson).filter { !it.isCompleted }.take(5)
        val taskRowIds = listOf(
            Triple(R.id.task_row_l1, R.id.title_l1, R.id.time_l1),
            Triple(R.id.task_row_l2, R.id.title_l2, R.id.time_l2),
            Triple(R.id.task_row_l3, R.id.title_l3, R.id.time_l3),
            Triple(R.id.task_row_l4, R.id.title_l4, R.id.time_l4),
            Triple(R.id.task_row_l5, R.id.title_l5, R.id.time_l5),
        )
        val taskDotIds = listOf(R.id.dot_l1, R.id.dot_l2, R.id.dot_l3, R.id.dot_l4, R.id.dot_l5)

        var hasTasks = false
        for (i in taskRowIds.indices) {
            if (i < tasks.size) {
                hasTasks = true
                val task = tasks[i]
                val (rowId, titleId, timeId) = taskRowIds[i]
                views.setViewVisibility(rowId, View.VISIBLE)
                views.setTextViewText(titleId, task.title)
                views.setTextViewText(timeId, task.reminderTime ?: "")
                views.setInt(taskDotIds[i], "setBackgroundColor",
                    Color.parseColor(PRIORITY_COLORS[task.priority] ?: "#FF6BCB77"))
                // Tap row → open task in app
                views.setOnClickPendingIntent(
                    rowId,
                    makeTaskPendingIntent(context, ACTION_OPEN_TASK, task.id, widgetId * 1000 + i)
                )
            } else {
                views.setViewVisibility(taskRowIds[i].first, View.GONE)
            }
        }
        views.setViewVisibility(R.id.tv_no_tasks_large, if (hasTasks) View.GONE else View.VISIBLE)

        // Habits (up to 4)
        val habits = parseHabits(habitsJson).take(4)
        val habitRowIds = listOf(
            listOf(R.id.habit_row_l1, R.id.habit_check_l1, R.id.habit_title_l1, R.id.habit_streak_l1),
            listOf(R.id.habit_row_l2, R.id.habit_check_l2, R.id.habit_title_l2, R.id.habit_streak_l2),
            listOf(R.id.habit_row_l3, R.id.habit_check_l3, R.id.habit_title_l3, R.id.habit_streak_l3),
            listOf(R.id.habit_row_l4, R.id.habit_check_l4, R.id.habit_title_l4, R.id.habit_streak_l4),
        )

        var hasHabits = false
        for (i in habitRowIds.indices) {
            if (i < habits.size) {
                hasHabits = true
                val habit = habits[i]
                val (rowId, checkId, titleId, streakId) = habitRowIds[i].let {
                    Quadruple(it[0], it[1], it[2], it[3])
                }
                views.setViewVisibility(rowId, View.VISIBLE)
                views.setTextViewText(titleId, habit.title)
                views.setTextViewText(checkId, if (habit.isCompletedToday) "●" else "○")
                views.setTextColor(checkId,
                    Color.parseColor(if (habit.isCompletedToday) "#FF6C63FF" else "#55FFFFFF"))
                views.setTextViewText(streakId,
                    if (habit.streak > 0) "${habit.streak}d" else "")
                // Tap habit → complete/open in app
                val habitAction = if (habit.isCompletedToday) ACTION_COMPLETE_HABIT else ACTION_COMPLETE_HABIT
                views.setOnClickPendingIntent(
                    rowId,
                    makeHabitPendingIntent(context, habitAction, habit.id, widgetId * 2000 + i)
                )
            } else {
                views.setViewVisibility(habitRowIds[i][0], View.GONE)
            }
        }
        views.setViewVisibility(R.id.tv_no_habits_large, if (hasHabits) View.GONE else View.VISIBLE)

        // Progress + streak
        views.setProgressBar(R.id.progress_habits_large, 100, completionPct, false)
        views.setTextViewText(R.id.tv_streak_large, "$streak day streak")

        // Quick Add Task button
        views.setOnClickPendingIntent(
            R.id.btn_add_task_large,
            makeOpenPendingIntent(context, ACTION_ADD_TASK, widgetId * 10 + 3)
        )

        // Tap header → open app
        views.setOnClickPendingIntent(
            R.id.widget_large_root,
            makeOpenPendingIntent(context, ACTION_OPEN_TASKS, widgetId * 10 + 4)
        )

        return views
    }

    // ─────────────────────────────────────────────────────────────────────────
    // PendingIntent helpers
    // ─────────────────────────────────────────────────────────────────────────

    private fun makeOpenPendingIntent(context: Context, action: String, requestCode: Int): PendingIntent {
        val intent = Intent(context, HabitFlowWidgetProvider::class.java).apply {
            this.action = action
        }
        return PendingIntent.getBroadcast(
            context, requestCode, intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
    }

    private fun makeTaskPendingIntent(
        context: Context, action: String, taskId: String, requestCode: Int
    ): PendingIntent {
        val intent = Intent(context, HabitFlowWidgetProvider::class.java).apply {
            this.action = action
            putExtra(EXTRA_TASK_ID, taskId)
        }
        return PendingIntent.getBroadcast(
            context, requestCode, intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
    }

    private fun makeHabitPendingIntent(
        context: Context, action: String, habitId: String, requestCode: Int
    ): PendingIntent {
        val intent = Intent(context, HabitFlowWidgetProvider::class.java).apply {
            this.action = action
            putExtra(EXTRA_HABIT_ID, habitId)
        }
        return PendingIntent.getBroadcast(
            context, requestCode, intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
    }

    /** Opens the Flutter app with a deep-link URI. */
    private fun openApp(context: Context, deepLink: String) {
        val intent = Intent(Intent.ACTION_VIEW, Uri.parse(deepLink)).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            setPackage(context.packageName)
        }
        try {
            context.startActivity(intent)
        } catch (e: Exception) {
            // Fallback: launch main activity
            val fallback = context.packageManager.getLaunchIntentForPackage(context.packageName)
            fallback?.flags = Intent.FLAG_ACTIVITY_NEW_TASK
            fallback?.let { context.startActivity(it) }
        }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // JSON parsing helpers
    // ─────────────────────────────────────────────────────────────────────────

    private data class WidgetTask(
        val id: String,
        val title: String,
        val priority: Int,
        val isCompleted: Boolean,
        val reminderTime: String?
    )

    private data class WidgetHabit(
        val id: String,
        val title: String,
        val isCompletedToday: Boolean,
        val streak: Int
    )

    private fun parseTasks(json: String): List<WidgetTask> {
        return try {
            val arr = JSONArray(json)
            (0 until arr.length()).map { i ->
                val obj = arr.getJSONObject(i)
                WidgetTask(
                    id = obj.optString("id", ""),
                    title = obj.optString("title", ""),
                    priority = obj.optInt("priority", 2),
                    isCompleted = obj.optBoolean("isCompleted", false),
                    reminderTime = formatTime(obj.optString("reminderTime", ""))
                )
            }
        } catch (e: Exception) {
            Log.e(TAG, "parseTasks error: $e")
            emptyList()
        }
    }

    private fun parseHabits(json: String): List<WidgetHabit> {
        return try {
            val arr = JSONArray(json)
            (0 until arr.length()).map { i ->
                val obj = arr.getJSONObject(i)
                WidgetHabit(
                    id = obj.optString("id", ""),
                    title = obj.optString("title", ""),
                    isCompletedToday = obj.optBoolean("isCompletedToday", false),
                    streak = obj.optInt("streak", 0)
                )
            }
        } catch (e: Exception) {
            Log.e(TAG, "parseHabits error: $e")
            emptyList()
        }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Formatting helpers
    // ─────────────────────────────────────────────────────────────────────────

    /** Formats an ISO-8601 date string to "h:mm a" for display. */
    private fun formatTime(iso: String): String? {
        if (iso.isBlank()) return null
        return try {
            val parser = SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS", Locale.US)
            val formatter = SimpleDateFormat("h:mm a", Locale.US)
            formatter.format(parser.parse(iso) ?: return null)
        } catch (e: Exception) {
            null
        }
    }

    /** Returns "Mon, Jul 26" style label for today. */
    private fun todayLabel(): String {
        val fmt = SimpleDateFormat("EEE, MMM d", Locale.US)
        return fmt.format(Date())
    }
}

// Kotlin doesn't have a Quadruple, define inline
private data class Quadruple<A, B, C, D>(val first: A, val second: B, val third: C, val fourth: D)

private operator fun <A, B, C, D> Quadruple<A, B, C, D>.component1() = first
private operator fun <A, B, C, D> Quadruple<A, B, C, D>.component2() = second
private operator fun <A, B, C, D> Quadruple<A, B, C, D>.component3() = third
private operator fun <A, B, C, D> Quadruple<A, B, C, D>.component4() = fourth
