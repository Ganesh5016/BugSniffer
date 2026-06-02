package com.bug.sniffer

import android.app.ActivityManager
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.ApplicationInfo
import android.content.pm.PackageManager
import android.net.TrafficStats
import android.os.BatteryManager
import android.os.Build
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.RandomAccessFile

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.bug.sniffer/native"

    // CPU Tracking
    private var lastTotalTicks = 0L
    private var lastIdleTicks = 0L

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getHardwareMetrics" -> result.success(getHardwareMetrics())
                "getNetworkStats" -> result.success(getNetworkStats())
                "getActiveConnections" -> result.success(getActiveConnections())
                "getInstalledApps" -> result.success(getInstalledApps())
                else -> result.notImplemented()
            }
        }
    }

    private fun getHardwareMetrics(): Map<String, Any> {
        return mapOf(
            "cpu" to getCpuUsage(),
            "memory" to getMemoryUsage(),
            "temperature" to getBatteryTemperature()
        )
    }

    private fun getCpuUsage(): Double {
        try {
            val reader = RandomAccessFile("/proc/stat", "r")
            val load = reader.readLine()
            reader.close()
            
            val toks = load.split(" +".toRegex()).toTypedArray()
            val idle1 = toks[4].toLong()
            val cpu1 = toks[1].toLong() + toks[2].toLong() + toks[3].toLong() +
                    toks[5].toLong() + toks[6].toLong() + toks[7].toLong() + toks[8].toLong()

            val diffIdle = idle1 - lastIdleTicks
            val diffTotal = cpu1 - lastTotalTicks
            val total = diffTotal + diffIdle

            lastIdleTicks = idle1
            lastTotalTicks = cpu1

            if (total == 0L) return 0.0
            var usage = (diffTotal.toDouble() / total) * 100.0
            if (usage < 0.0) usage = 0.0
            if (usage > 100.0) usage = 100.0
            return usage
        } catch (e: Exception) {
            e.printStackTrace()
            return 0.0
        }
    }

    private fun getMemoryUsage(): Double {
        val actManager = getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
        val memInfo = ActivityManager.MemoryInfo()
        actManager.getMemoryInfo(memInfo)
        
        val totalMem = memInfo.totalMem.toDouble()
        val availMem = memInfo.availMem.toDouble()
        val usedMem = totalMem - availMem
        
        return (usedMem / totalMem) * 100.0
    }

    private fun getBatteryTemperature(): Double {
        val intent = registerReceiver(null, IntentFilter(Intent.ACTION_BATTERY_CHANGED))
        val temp = intent?.getIntExtra(BatteryManager.EXTRA_TEMPERATURE, 0) ?: 0
        return temp / 10.0 // It's in tenths of a degree Celsius
    }

    private fun getNetworkStats(): Map<String, Any> {
        val rxBytes = TrafficStats.getTotalRxBytes()
        val txBytes = TrafficStats.getTotalTxBytes()
        return mapOf(
            "rx_bytes" to rxBytes,
            "tx_bytes" to txBytes
        )
    }

    private fun getActiveConnections(): List<Map<String, Any>> {
        val connections = mutableListOf<Map<String, Any>>()
        try {
            val file = File("/proc/net/tcp")
            if (file.exists()) {
                val lines = file.readLines()
                for (i in 1 until lines.size) { // Skip header
                    val line = lines[i].trim().split("\\s+".toRegex())
                    if (line.size >= 4) {
                        val localAddress = parseIpPort(line[1])
                        val remoteAddress = parseIpPort(line[2])
                        val stateHex = line[3]
                        
                        // State 01 is ESTABLISHED
                        if (stateHex == "01" && remoteAddress["ip"] != "0.0.0.0") {
                            connections.add(mapOf(
                                "local_ip" to localAddress["ip"]!!,
                                "local_port" to localAddress["port"]!!,
                                "remote_ip" to remoteAddress["ip"]!!,
                                "remote_port" to remoteAddress["port"]!!,
                                "state" to "ESTABLISHED"
                            ))
                        }
                    }
                }
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
        return connections
    }

    private fun parseIpPort(hexStr: String): Map<String, Any> {
        try {
            val parts = hexStr.split(":")
            if (parts.size == 2) {
                val ipHex = parts[0]
                val portHex = parts[1]
                
                // Parse IP (little endian)
                val ipLong = ipHex.toLong(16)
                val ip1 = (ipLong and 0xFF).toString()
                val ip2 = ((ipLong shr 8) and 0xFF).toString()
                val ip3 = ((ipLong shr 16) and 0xFF).toString()
                val ip4 = ((ipLong shr 24) and 0xFF).toString()
                val ip = "$ip1.$ip2.$ip3.$ip4"
                
                // Parse Port
                val port = portHex.toInt(16)
                return mapOf("ip" to ip, "port" to port)
            }
        } catch (e: Exception) {}
        return mapOf("ip" to "0.0.0.0", "port" to 0)
    }

    private fun getInstalledApps(): List<Map<String, Any>> {
        val pm = packageManager
        val apps = mutableListOf<Map<String, Any>>()
        
        try {
            val packages = pm.getInstalledPackages(PackageManager.GET_PERMISSIONS)
            for (packageInfo in packages) {
                // Filter out system apps unless they have been updated
                if ((packageInfo.applicationInfo.flags and ApplicationInfo.FLAG_SYSTEM) != 0 &&
                    (packageInfo.applicationInfo.flags and ApplicationInfo.FLAG_UPDATED_SYSTEM_APP) == 0) {
                    continue
                }
                
                val appName = packageInfo.applicationInfo.loadLabel(pm).toString()
                val packageName = packageInfo.packageName
                val permissions = packageInfo.requestedPermissions?.toList() ?: emptyList()
                
                apps.add(mapOf(
                    "name" to appName,
                    "package" to packageName,
                    "permissions" to permissions
                ))
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
        
        return apps
    }
}
