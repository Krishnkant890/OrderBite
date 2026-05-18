package com.gcany.gc_any_order

import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.os.Build
import java.io.FileOutputStream
import java.util.*
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.ServiceConnection
import android.util.Log
import android.os.IBinder
import net.nyx.printerservice.print.IPrinterService
import net.nyx.printerservice.print.PrintTextFormat

class MainActivity : FlutterActivity() {
    private val CHANNEL = "printer"
    private val TAG = "NYX_PRINTER"
    private var printerService: IPrinterService? = null

    private val connService = object : ServiceConnection {
        override fun onServiceDisconnected(name: ComponentName?) {
            Log.d(TAG, "Printer service disconnected, try reconnect")
            printerService = null
        }

        override fun onServiceConnected(name: ComponentName?, service: IBinder?) {
            Log.d(TAG, "Printer service connected: $name")
            printerService = IPrinterService.Stub.asInterface(service)
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        bindPrinterService()
    }

    private fun bindPrinterService() {
        val packages = listOf(
            "net.nyx.printerservice",
            "com.goodcom.printerservice",
            "com.gc.printerservice",
            "com.goodcom.gc_printer"
        )
        
        for (pkg in packages) {
            Log.d(TAG, "Attempting to bind printer service: $pkg")
            val intent = Intent()
            intent.`package` = pkg
            intent.action = "$pkg.IPrinterService"
            
            try {
                val result = bindService(intent, connService, Context.BIND_AUTO_CREATE)
                Log.d(TAG, "Bind service result for $pkg: $result")
                if (result) {
                    return // Found one
                }
            } catch (e: Exception) {
                Log.e(TAG, "Error binding to $pkg: ${e.message}")
            }
        }
        Log.e(TAG, "Failed to bind to any known printer service")
    }

    override fun onDestroy() {
        super.onDestroy()
        try {
            unbindService(connService)
        } catch (e: Exception) {
            // ignore
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "printReceipt" -> {
                    val bytes = call.argument<ByteArray>("bytes")
                    if (bytes != null) {
                        Log.d(TAG, "Starting print task for ${bytes.size} bytes")
                        // 1. Try NYX Printer Service (SDK)
                        if (printerService != null) {
                            try {
                                Log.d(TAG, "Attempting to print via NYX SDK...")
                                val ret = printerService?.printEscposData(bytes)
                                
                                // In this SDK version, ret is a ByteArray? (Response buffer)
                                if (ret != null) {
                                    Log.d(TAG, "SDK Response: ${ret.joinToString()}")
                                    Log.d(TAG, "Print operation accepted by SDK")
                                    // Feed paper
                                    printerService?.printEndAutoOut()
                                    result.success("NYX_SDK_SUCCESS")
                                    return@setMethodCallHandler
                                } else {
                                    Log.e(TAG, "SDK Print returned null. Trying fallback...")
                                }
                            } catch (e: Exception) {
                                Log.e(TAG, "SDK Print Exception: ${e.message}")
                            }
                        }

                        // 2. Fallback to direct file paths
                        Log.d(TAG, "Falling back to direct path printing...")
                        val paths = listOf(
                            "/dev/usb/lp0", "/dev/usb/lp1", 
                            "/dev/ttyS0", "/dev/ttyS1", "/dev/ttyS2", "/dev/ttyS3", "/dev/ttyS4", "/dev/ttyS7",
                            "/dev/ttyMT0", "/dev/ttyMT1", "/dev/ttyMT2", "/dev/ttyMT3",
                            "/dev/ttyHS0", "/dev/ttyHS1"
                        )
                        
                        for (path in paths) {
                            try {
                                val file = java.io.File(path)
                                if (file.exists() && file.canWrite()) {
                                    Log.d(TAG, "Trying hardware path: $path")
                                    val outputStream = FileOutputStream(file)
                                    outputStream.write(bytes)
                                    outputStream.flush()
                                    outputStream.close()
                                    Log.d(TAG, "Print successful via path: $path")
                                    result.success("Path:$path")
                                    return@setMethodCallHandler
                                }
                            } catch (e: Exception) {
                                Log.e(TAG, "Path $path access failed: ${e.message}")
                                continue
                            }
                        }
                        
                        Log.e(TAG, "All internal printing methods exhausted")
                        result.success(null)
                    } else {
                        result.success(null)
                    }
                }
                "getDeviceInfo" -> {
                    val info = mutableMapOf(
                        "model" to Build.MODEL,
                        "manufacturer" to Build.MANUFACTURER,
                        "brand" to Build.BRAND,
                        "device" to Build.DEVICE,
                        "product" to Build.PRODUCT,
                        "hardware" to Build.HARDWARE,
                        "version" to Build.VERSION.RELEASE,
                        "sdk_connected" to (printerService != null)
                    )
                    
                    // Add SDK specific info if available
                    printerService?.let { service ->
                        try {
                            info["service_version"] = service.serviceVersion ?: "Unknown"
                            val verArr = arrayOf("")
                            if (service.getPrinterVersion(verArr) == 0) {
                                info["printer_version"] = verArr[0]
                            }
                            val modelArr = arrayOf("")
                            if (service.getPrinterModel(modelArr) == 0) {
                                info["printer_model"] = modelArr[0]
                            }
                        } catch (e: Exception) {
                            Log.e(TAG, "Error getting SDK device info: ${e.message}")
                        }
                    }
                    
                    result.success(info)
                }
                "checkPrinterStatus" -> {
                    if (printerService != null) {
                        try {
                            val status = printerService?.getPrinterStatus() ?: -1
                            Log.d(TAG, "Printer status check: $status")
                            result.success(status == 0) // 0 is usually success/ready
                        } catch (e: Exception) {
                            Log.e(TAG, "Error checking status: ${e.message}")
                            result.success(false)
                        }
                    } else {
                        result.success(true) // Fallback to true if SDK not used
                    }
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }
}
