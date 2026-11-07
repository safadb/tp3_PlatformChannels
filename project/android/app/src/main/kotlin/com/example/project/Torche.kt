package com.example.project

import android.content.Context
import android.hardware.camera2.CameraCharacteristics
import android.hardware.camera2.CameraManager
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class Torche(context: Context) : MethodChannel.MethodCallHandler {

    private val cameraManager =
        context.getSystemService(Context.CAMERA_SERVICE) as CameraManager

    override fun onMethodCall(
        call: MethodCall,
        result: MethodChannel.Result
    ) {
        when (call.method) {
            "allumer" -> {
                val etat = call.argument<Boolean>("etat") ?: false

                try {
                    var cameraFlash: String? = null

                    for (cameraId in cameraManager.cameraIdList) {
                        val caracteristiques =
                            cameraManager.getCameraCharacteristics(cameraId)

                        val flashDisponible =
                            caracteristiques.get(
                                CameraCharacteristics.FLASH_INFO_AVAILABLE
                            ) == true

                        if (flashDisponible) {
                            cameraFlash = cameraId
                            break
                        }
                    }

                    if (cameraFlash == null) {
                        result.error(
                            "PAS_DE_FLASH",
                            "Aucun flash disponible sur cet appareil",
                            null
                        )
                        return
                    }

                    cameraManager.setTorchMode(cameraFlash, etat)
                    result.success(null)

                } catch (e: Exception) {
                    result.error("ERREUR_TORCHE", e.message, null)
                }
            }

            else -> result.notImplemented()
        }
    }
}