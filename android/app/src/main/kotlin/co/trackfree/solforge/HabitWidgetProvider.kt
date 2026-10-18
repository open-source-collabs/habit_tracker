package co.trackfree.solforge

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.net.Uri
import android.widget.RemoteViews
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

/**
 * "Today's progress" home-screen widget. Data is written by the Flutter side
 * (HabitWidgetSyncService) into widgets_kit's shared preferences.
 */
class HabitWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (appWidgetId in appWidgetIds) {
            appWidgetManager.updateAppWidget(appWidgetId, buildViews(context))
        }
    }

    private fun buildViews(context: Context): RemoteViews {
        val views = RemoteViews(context.packageName, R.layout.habit_widget_layout)
        val prefs = context.getSharedPreferences("WidgetsKitPreferences", Context.MODE_PRIVATE)
        val now = Date()
        views.setTextViewText(
            R.id.widget_date,
            SimpleDateFormat("EEE, d MMM", Locale.getDefault()).format(now)
        )

        // Data from a previous day must not pose as today's progress.
        val todayKey = SimpleDateFormat("yyyy-MM-dd", Locale.US).format(now)
        val isFresh = prefs.text("habit_date_key") == todayKey

        if (!isFresh) {
            views.setTextViewText(R.id.widget_completion_count, "–")
            views.setTextViewText(R.id.widget_completion_percentage, "")
            views.setProgressBar(R.id.widget_progress, 100, 0, false)
            views.setTextViewText(R.id.widget_top_pending, context.getString(R.string.widget_stale))
            views.setTextViewText(
                R.id.widget_streak_badge,
                context.getString(R.string.widget_streak_days, prefs.number("habit_active_streak"))
            )
        } else {
            val total = prefs.number("habit_total_count")
            val done = prefs.number("habit_completed_count")
            val percent = if (total > 0) (done * 100 / total) else 0
            val allDone = total > 0 && done >= total

            views.setTextViewText(R.id.widget_completion_count, "$done / $total")
            views.setTextViewText(R.id.widget_completion_percentage, "$percent%")
            views.setProgressBar(R.id.widget_progress, 100, percent, false)
            views.setTextViewText(
                R.id.widget_streak_badge,
                context.getString(R.string.widget_streak_days, prefs.number("habit_active_streak"))
            )

            val footer = when {
                total == 0 -> context.getString(R.string.widget_no_habits)
                allDone -> context.getString(R.string.widget_all_done)
                else -> {
                    val emoji = prefs.text("habit_top_pending_emoji") ?: ""
                    val title = prefs.text("habit_top_pending_title") ?: ""
                    context.getString(R.string.widget_next_habit, "$emoji $title".trim())
                }
            }
            views.setTextViewText(R.id.widget_top_pending, footer)
        }

        // Tap anywhere: open the app on today's habits.
        val intent = Intent(context, MainActivity::class.java).apply {
            action = Intent.ACTION_VIEW
            data = Uri.parse("habittracker://open")
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        val pendingIntent = PendingIntent.getActivity(
            context,
            0,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        views.setOnClickPendingIntent(R.id.widget_container, pendingIntent)
        return views
    }
}

/**
 * widgets_kit may store a number as Int, Long, Double or String depending on
 * the Dart value; getInt() on any other type throws ClassCastException and
 * crashes the widget, so read whatever is there.
 */
private fun SharedPreferences.number(key: String): Int = when (val value = all[key]) {
    is Number -> value.toInt()
    is String -> value.toDoubleOrNull()?.toInt() ?: 0
    else -> 0
}

private fun SharedPreferences.text(key: String): String? =
    all[key]?.toString()?.takeIf { it.isNotBlank() }
