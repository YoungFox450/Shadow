package com.shadow.shadow

import android.accessibilityservice.AccessibilityService
import android.view.accessibility.AccessibilityEvent

/**
 * Service d'accessibilité minimal pour Shadow.
 *
 * Il doit exister et être déclaré dans AndroidManifest.xml pour que
 * l'option apparaisse dans Réglages > Accessibilité, et pour que
 * MainActivity.isAccessibilityServiceEnabled() puisse la détecter.
 */
class LockdownAccessibilityService : AccessibilityService() {

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        val packageName = event?.packageName?.toString() ?: return
        // TODO: comparer packageName à la liste des apps bloquées
        // (à stocker par ex. dans SharedPreferences, synchronisée
        // depuis le côté Flutter).
    }

    override fun onInterrupt() {
        // Rien à faire pour l'instant.
    }
}
