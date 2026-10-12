package com.example.habit_tracker

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.widget.RemoteViews

class HabitWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.habit_widget_layout)

            // Read preferences stored by widgets_kit
            val prefs = context.getSharedPreferences("WidgetsKitPreferences", Context.MODE_PRIVATE)
            val totalCount = prefs.getInt("habit_total_count", 0)
            val completedCount = prefs.getInt("habit_completed_count", 0)
            val completionRate = prefs.getString("habit_completion_rate", "0%") ?: "0%"
            val streak = prefs.getInt("habit_active_streak", 0)
            val topPending = prefs.getString("habit_top_pending_title", "All done today! 🎉") ?: "All done today! 🎉"
            val topPendingEmoji = prefs.getString("habit_top_pending_emoji", "✨") ?: "✨"

            // Bind values to RemoteViews
            views.setTextViewText(R.id.widget_streak_badge, "🔥 $streak d")
            views.setTextViewText(R.id.widget_completion_count, "$completedCount / $totalCount")
            views.setTextViewText(R.id.widget_completion_percentage, "($completionRate)")
            views.setTextViewText(R.id.widget_top_pending, "$topPendingEmoji $topPending")

            // Setup click intent to launch MainActivity
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

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
