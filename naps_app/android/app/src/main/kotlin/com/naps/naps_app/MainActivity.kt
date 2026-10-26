package com.naps.naps_app

import android.content.Context
import android.security.keystore.KeyGenParameterSpec
import android.security.keystore.KeyProperties
import android.util.Base64
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.security.KeyStore
import javax.crypto.Cipher
import javax.crypto.KeyGenerator
import javax.crypto.SecretKey
import javax.crypto.spec.GCMParameterSpec

class MainActivity : FlutterActivity() {
    private val channelName = "com.naps/session"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName).setMethodCallHandler { call, result ->
            try {
                when (call.method) {
                    "read" -> result.success(readToken())
                    "write" -> {
                        val token = call.argument<String>("value")
                        if (token == null) result.error("invalid_token", "Session token is missing", null)
                        else {
                            writeToken(token)
                            result.success(null)
                        }
                    }
                    "clear" -> {
                        val saved = getSharedPreferences("naps_secure_session", Context.MODE_PRIVATE).edit().remove("token").commit()
                        if (!saved) throw IllegalStateException("Could not clear the saved session")
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            } catch (error: Exception) {
                result.error("secure_storage_error", "Could not access the encrypted session", error.message)
            }
        }
    }

    private fun readToken(): String? {
        val stored = getSharedPreferences("naps_secure_session", Context.MODE_PRIVATE).getString("token", null) ?: return null
        val bytes = Base64.decode(stored, Base64.NO_WRAP)
        if (bytes.size <= 12) return null
        val cipher = Cipher.getInstance("AES/GCM/NoPadding")
        cipher.init(Cipher.DECRYPT_MODE, sessionKey(), GCMParameterSpec(128, bytes, 0, 12))
        return cipher.doFinal(bytes.copyOfRange(12, bytes.size)).toString(Charsets.UTF_8)
    }

    private fun writeToken(token: String) {
        val cipher = Cipher.getInstance("AES/GCM/NoPadding")
        cipher.init(Cipher.ENCRYPT_MODE, sessionKey())
        val encrypted = cipher.doFinal(token.toByteArray(Charsets.UTF_8))
        val value = Base64.encodeToString(cipher.iv + encrypted, Base64.NO_WRAP)
        val saved = getSharedPreferences("naps_secure_session", Context.MODE_PRIVATE).edit().putString("token", value).commit()
        if (!saved) throw IllegalStateException("Could not save the session")
    }

    private fun sessionKey(): SecretKey {
        val keyStore = KeyStore.getInstance("AndroidKeyStore").apply { load(null) }
        val existingKey = keyStore.getKey("naps_session_key", null) as? SecretKey
        if (existingKey != null) return existingKey
        val generator = KeyGenerator.getInstance(KeyProperties.KEY_ALGORITHM_AES, "AndroidKeyStore")
        generator.init(
            KeyGenParameterSpec.Builder(
                "naps_session_key",
                KeyProperties.PURPOSE_ENCRYPT or KeyProperties.PURPOSE_DECRYPT,
            )
                .setBlockModes(KeyProperties.BLOCK_MODE_GCM)
                .setEncryptionPaddings(KeyProperties.ENCRYPTION_PADDING_NONE)
                .setRandomizedEncryptionRequired(true)
                .build(),
        )
        return generator.generateKey()
    }
}
