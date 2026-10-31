package com.habitflow.habitflow

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log

/**
 * WidgetRefreshReceiver
 *
 * Handles system broadcasts to keep the HabitFlow home screen widget updated:
 *  - MY_PACKAGE_REPLACED / PACKAGE_REPLACED (app update)
 *  - BOOT_COMPLETED / QUICKBOOT_POWERON (device reboot)
 *  - ACTION_MIDNIGHT_REFRESH (daily midnight AlarmManager trigger)
 */
class WidgetRefreshReceiver : BroadcastReceiver() {

    companion object {
        private const val TAG = "WidgetRefreshReceiver"
        const val ACTION_MIDNIGHT_REFRESH = "com.habitflow.habitflow.ACTION_MIDNIGHT_REFRESH"
    }

    override fun onReceive(context: Context, intent: Intent) {
        Log.d(TAG, "Broadcast received: ${intent.action}")

        when (intent.action) {
            Intent.ACTION_BOOT_COMPLETED,
            "android.intent.action.QUICKBOOT_POWERON",
            "com.htc.intent.action.QUICKBOOT_POWERON",
            Intent.ACTION_MY_PACKAGE_REPLACED -> {
                Log.d(TAG, "Device rebooted or package replaced — refreshing widget & rescheduling midnight alarm")
                HabitFlowWidgetProvider.requestUpdate(context)
                HabitFlowWidgetProvider.scheduleMidnightRefresh(context)
            }

            ACTION_MIDNIGHT_REFRESH -> {
                Log.d(TAG, "Midnight refresh triggered — updating widget & scheduling next midnight alarm")
                HabitFlowWidgetProvider.requestUpdate(context)
                HabitFlowWidgetProvider.scheduleMidnightRefresh(context)
            }
        }
    }
}
