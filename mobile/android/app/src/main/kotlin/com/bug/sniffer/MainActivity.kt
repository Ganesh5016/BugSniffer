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
            val statFile = File("/proc/self/stat")
            if (!statFile.exists()) return 0.0
            val stat = statFile.readText().trim().split("\\s+".toRegex())
            if (stat.size < 15) return 0.0
            
            val utime = stat[13].toLong()
            val stime = stat[14].toLong()
            val totalTicks = utime + stime
            val uptimeMillis = android.os.SystemClock.uptimeMillis()
            
            val diffTicks = totalTicks - lastTotalTicks
            val diffUptime = uptimeMillis - lastIdleTicks
            
            lastTotalTicks = totalTicks
            lastIdleTicks = uptimeMillis
            
            if (diffUptime <= 0 || lastIdleTicks == uptimeMillis) return 0.0
            
            // CPU usage % = (diffTicks * 10ms per tick) / diffUptime * 100 * num_cores
            val numCores = Runtime.getRuntime().availableProcessors()
            val usage = (diffTicks.toDouble() * 10.0 / diffUptime) * 100.0 * numCores
            return usage.coerceIn(0.0, 100.0)
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

    private var lastRxBytes = 0L
    private var lastTxBytes = 0L
    private var lastNetUptime = 0L

    private fun getNetworkStats(): Map<String, Any> {
        val rxBytes = TrafficStats.getTotalRxBytes()
        val txBytes = TrafficStats.getTotalTxBytes()
        val uptime = android.os.SystemClock.uptimeMillis()
        
        val diffRx = rxBytes - lastRxBytes
        val diffTx = txBytes - lastTxBytes
        val diffTime = uptime - lastNetUptime
        
        lastRxBytes = rxBytes
        lastTxBytes = txBytes
        lastNetUptime = uptime
        
        if (diffTime <= 0 || diffTime == uptime) {
            return mapOf("rx_bytes" to 0L, "tx_bytes" to 0L)
        }
        
        val rxBps = (diffRx * 1000) / diffTime
        val txBps = (diffTx * 1000) / diffTime
        
        return mapOf(
            "rx_bytes" to rxBps,
            "tx_bytes" to txBps
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
                val appInfo = packageInfo.applicationInfo ?: continue
                
                // Filter out system apps unless they have been updated
                if ((appInfo.flags and ApplicationInfo.FLAG_SYSTEM) != 0 &&
                    (appInfo.flags and ApplicationInfo.FLAG_UPDATED_SYSTEM_APP) == 0) {
                    continue
                }
                
                val appName = appInfo.loadLabel(pm).toString()
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
