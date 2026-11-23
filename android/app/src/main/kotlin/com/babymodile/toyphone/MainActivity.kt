package com.babymodile.toyphone

import android.media.AudioManager
import android.media.ToneGenerator
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val sfxToneGenerator: ToneGenerator? by lazy {
        runCatching { ToneGenerator(AudioManager.STREAM_MUSIC, 100) }.getOrNull()
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "babymodile/sound_effects",
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "playDialKey" -> {
                    val key = call.argument<String>("key")
                    val tone = key?.let(::dtmfToneForKey)
                    if (tone == null) {
                        result.success(false)
                        return@setMethodCallHandler
                    }
                    result.success(startTone(tone, 120))
                }
                "play" -> {
                    val sound = call.argument<String>("sound")
                    val durationMs = call.argument<Int>("durationMs") ?: 160
                    val tone = sound?.let(::toneForSound)
                    if (tone == null) {
                        result.success(false)
                        return@setMethodCallHandler
                    }
                    result.success(startTone(tone, durationMs))
                }
                "stop" -> {
                    runCatching { sfxToneGenerator?.stopTone() }
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onDestroy() {
        runCatching { sfxToneGenerator?.release() }
        super.onDestroy()
    }

    private fun startTone(tone: Int, durationMs: Int): Boolean {
        val generator = sfxToneGenerator ?: return false
        return try {
            generator.startTone(tone, durationMs)
            true
        } catch (_: RuntimeException) {
            false
        }
    }

    private fun toneForSound(sound: String): Int? =
        when (sound) {
            "tap" -> ToneGenerator.TONE_PROP_BEEP
            "erase" -> ToneGenerator.TONE_PROP_BEEP2
            "dialing" -> ToneGenerator.TONE_SUP_DIAL
            "ringback" -> ToneGenerator.TONE_SUP_RINGTONE
            "connected" -> ToneGenerator.TONE_SUP_CONFIRM
            "success" -> ToneGenerator.TONE_PROP_ACK
            "error" -> ToneGenerator.TONE_SUP_ERROR
            "hangUp" -> ToneGenerator.TONE_PROP_NACK
            else -> null
        }

    private fun dtmfToneForKey(key: String): Int? =
        when (key) {
            "0" -> ToneGenerator.TONE_DTMF_0
            "1" -> ToneGenerator.TONE_DTMF_1
            "2" -> ToneGenerator.TONE_DTMF_2
            "3" -> ToneGenerator.TONE_DTMF_3
            "4" -> ToneGenerator.TONE_DTMF_4
            "5" -> ToneGenerator.TONE_DTMF_5
            "6" -> ToneGenerator.TONE_DTMF_6
            "7" -> ToneGenerator.TONE_DTMF_7
            "8" -> ToneGenerator.TONE_DTMF_8
            "9" -> ToneGenerator.TONE_DTMF_9
            else -> null
        }
}
