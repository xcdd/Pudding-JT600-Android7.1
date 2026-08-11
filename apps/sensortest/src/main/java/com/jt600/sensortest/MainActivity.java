package com.jt600.sensortest;

import android.app.Activity;
import android.app.AlertDialog;
import android.content.ComponentName;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.content.ServiceConnection;
import android.hardware.Sensor;
import android.hardware.SensorEvent;
import android.hardware.SensorEventListener;
import android.hardware.SensorManager;
import android.os.BatteryManager;
import android.os.Binder;
import android.os.Bundle;
import android.os.Handler;
import android.os.IBinder;
import android.os.Parcel;
import android.os.RemoteException;
import android.view.KeyEvent;
import android.view.View;
import android.widget.Button;
import android.widget.EditText;
import android.widget.LinearLayout;
import android.widget.ScrollView;
import android.widget.TextView;

import java.util.List;
import java.util.Locale;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

import com.jt600.led.IJT600LedService;

/** JT600 硬件人工测试：光/距离/三键/触摸/电池 + 电机/LED（AIDL 真控制）。 */
public class MainActivity extends Activity implements SensorEventListener {

    private SensorManager sm;
    private TextView lightValue, proximityValue, keyValue, batteryValue, sensorList;
    private TextView motorStatus, ledStatus, rootStatus;
    private boolean hasLight = false, hasProximity = false;
    private final Handler h = new Handler();
    private final ExecutorService controlExecutor = Executors.newSingleThreadExecutor();
    private final IBinder ledToken = new Binder();
    private final IBinder motorToken = new Binder();
    private final IBinder motorListener = new MotorListenerBinder();
    private volatile IJT600LedService ledService;
    private volatile IBinder motorService;
    private volatile boolean motorRegistered;
    private boolean motorBound;
    private boolean ledBound;
    private final Runnable batteryRefresher = new Runnable() {
        @Override public void run() { showBattery(); h.postDelayed(this, 3000); }
    };
    private final ServiceConnection ledConnection = new ServiceConnection() {
        @Override public void onServiceConnected(ComponentName name, IBinder binder) {
            final IJT600LedService api = IJT600LedService.Stub.asInterface(binder);
            controlExecutor.execute(new Runnable() {
                @Override public void run() {
                    try {
                        api.registerClient(ledToken);
                        ledService = api;
                        showLedStatus("LED 服务已连接，可开始测试");
                    } catch (Exception e) {
                        ledService = null;
                        showLedStatus("LED 服务连接失败：" + errorText(e));
                    }
                }
            });
        }

        @Override public void onServiceDisconnected(ComponentName name) {
            ledService = null;
            showLedStatus("LED 服务已断开");
        }
    };
    private final ServiceConnection motorConnection = new ServiceConnection() {
        @Override public void onServiceConnected(ComponentName name, IBinder binder) {
            motorService = binder;
            motorRegistered = false;
            showMotorStatus("电机服务已连接，请点击“电机：连接”建立控制会话");
        }

        @Override public void onServiceDisconnected(ComponentName name) {
            motorRegistered = false;
            motorService = null;
            showMotorStatus("电机服务已断开");
        }
    };

    private static final class MotorListenerBinder extends Binder {
        private static final String DESCRIPTOR = "com.jt600.motor.IJT600MotorListener";

        MotorListenerBinder() {
            attachInterface(null, DESCRIPTOR);
        }

        @Override protected boolean onTransact(int code, Parcel data, Parcel reply, int flags)
                throws RemoteException {
            if (code == INTERFACE_TRANSACTION) {
                if (reply != null) reply.writeString(DESCRIPTOR);
                return true;
            }
            if (code == FIRST_CALL_TRANSACTION) {
                data.enforceInterface(DESCRIPTOR);
                // MotorStatus is intentionally left opaque; receipt of the callback is sufficient.
                if (reply != null) reply.writeNoException();
                return true;
            }
            return super.onTransact(code, data, reply, flags);
        }
    }

    @Override protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        sm = (SensorManager) getSystemService(SENSOR_SERVICE);

        ScrollView scroll = new ScrollView(this);
        LinearLayout root = new LinearLayout(this);
        root.setOrientation(LinearLayout.VERTICAL);
        root.setPadding(24, 24, 24, 24);
        scroll.addView(root);

        sensorList = addText(root, "传感器总览（设备实际枚举）", 13);
        StringBuilder sb = new StringBuilder();
        List<Sensor> all = sm.getSensorList(Sensor.TYPE_ALL);
        for (Sensor s : all) {
            sb.append(String.format(Locale.US,
                "%s\n  type=%d vendor=%s ver=%d range=%.1f res=%.3f power=%.2fmA minDelay=%dus\n",
                s.getName(), s.getType(), s.getVendor(), s.getVersion(),
                s.getMaximumRange(), s.getResolution(), s.getPower(), s.getMinDelay()));
        }
        if (all.isEmpty()) sb.append("（无传感器）");
        sensorList.setText(sb.toString());

        lightValue = addText(root, "光传感器（遮挡/移开观察 lux 变化）\n  当前值：等待采样…", 16);
        proximityValue = addText(root, "距离传感器（遮挡/移开观察 近/远 切换）\n  当前值：等待采样…", 16);
        keyValue = addText(root, "三独立触摸键（依次触摸 头顶→左耳→右耳，各按下再松开）\n  状态：等待按键…", 16);

        batteryValue = addText(root, "电池信息（每 3 秒自动刷新）\n  读取中…", 16);

        addMotorSection(root);
        addLedSection(root);


        setContentView(scroll);
        showBattery();
        h.postDelayed(batteryRefresher, 3000);
        bindMotorService();
        bindLedService();
    }

    private static final class OperationResult {
        final boolean success;
        final String message;

        OperationResult(boolean success, String message) {
            this.success = success;
            this.message = message;
        }
    }

    // ---------------- 电机 ----------------

    private OperationResult motorState() {
        try {
            return new OperationResult(motorBooleanCall(9),
                motorRegistered ? "硬件可用，控制会话已建立" : "硬件可用，控制会话未建立");
        } catch (Exception e) {
            return new OperationResult(false, "状态读取失败：" + e.getMessage());
        }
    }

    private void bindMotorService() {
        Intent intent = new Intent();
        intent.setComponent(new ComponentName("com.jt600.motor", "com.jt600.motor.JT600MotorService"));
        motorBound = bindService(intent, motorConnection, Context.BIND_AUTO_CREATE);
        if (!motorBound) showMotorStatus("电机服务绑定失败");
    }

    private void showMotorStatus(final String message) {
        runOnUiThread(new Runnable() {
            @Override public void run() { motorStatus.setText(message); }
        });
    }

    private OperationResult connectMotor() {
        try {
            if (motorService == null) return new OperationResult(false, "电机服务尚未连接");
            // Registration is idempotent for the same token. Reassert it before every
            // command because MotorService may drop ownership independently of this UI.
            motorRegister();
            motorRegistered = true;
            return motorState();
        } catch (Exception e) {
            return new OperationResult(false, "连接失败：" + e.getMessage());
        }
    }

    private void motorAction(final int tx, final String msg) {
        controlExecutor.execute(new Runnable() {
            @Override public void run() {
                OperationResult connection = connectMotor();
                String status;
                try {
                    if (!connection.success) {
                        status = connection.message;
                    } else {
                        if (tx == 20 || tx == -20) motorRelativeCall(tx);
                        else motorTokenCall(tx);
                        // Keep every UI action bounded. Endpoint presets can overshoot
                        // the driver's accepted range and leave MotorService in cleanup.
                        if (tx == 20 || tx == -20) {
                            try { Thread.sleep(250); } catch (InterruptedException ignored) { }
                            motorTokenCall(6);
                        }
                        status = msg;
                    }
                } catch (Exception e) {
                    status = "执行失败：" + e.getMessage();
                }
                final String displayStatus = status;
                runOnUiThread(new Runnable() {
                    @Override public void run() {
                        motorStatus.setText(displayStatus);
                    }
                });
            }
        });
    }

    private Parcel motorTransact(int transaction, boolean writeToken, IBinder listener)
            throws RemoteException {
        IBinder remote = motorService;
        if (remote == null) throw new RemoteException("JT600MotorService not connected");
        Parcel data = Parcel.obtain();
        Parcel reply = Parcel.obtain();
        try {
            data.writeInterfaceToken("com.jt600.motor.IJT600MotorService");
            if (writeToken) data.writeStrongBinder(motorToken);
            if (listener != null) data.writeStrongBinder(listener);
            if (!remote.transact(transaction, data, reply, 0)) {
                throw new RemoteException("motor transaction rejected: " + transaction);
            }
            reply.readException();
            return reply;
        } catch (RemoteException e) {
            reply.recycle();
            throw e;
        } finally {
            data.recycle();
        }
    }

    private void motorRegister() throws RemoteException {
        Parcel reply = motorTransact(1, true, motorListener);
        reply.recycle();
    }

    private void motorTokenCall(int transaction) throws RemoteException {
        Parcel reply = motorTransact(transaction, true, null);
        reply.recycle();
    }

    private void motorRelativeCall(int delta) throws RemoteException {
        Parcel data = Parcel.obtain();
        Parcel reply = Parcel.obtain();
        try {
            data.writeInterfaceToken("com.jt600.motor.IJT600MotorService");
            data.writeStrongBinder(motorToken);
            data.writeInt(delta);
            if (!motorService.transact(2, data, reply, 0))
                throw new RemoteException("motor transaction rejected: 2");
            reply.readException();
        } finally {
            reply.recycle();
            data.recycle();
        }
    }

    private void motorAbsoluteCall(int target) throws RemoteException {
        IBinder remote = motorService;
        if (remote == null) throw new RemoteException("JT600MotorService not connected");
        Parcel data = Parcel.obtain();
        Parcel reply = Parcel.obtain();
        try {
            data.writeInterfaceToken("com.jt600.motor.IJT600MotorService");
            data.writeStrongBinder(motorToken);
            data.writeInt(target);
            if (!remote.transact(10, data, reply, 0))
                throw new RemoteException("absolute motor transaction rejected");
            reply.readException();
        } finally {
            reply.recycle();
            data.recycle();
        }
    }

    private boolean motorBooleanCall(int transaction) throws RemoteException {
        Parcel reply = motorTransact(transaction, false, null);
        try {
            return reply.readInt() != 0;
        } finally {
            reply.recycle();
        }
    }

    private void addMotorSection(LinearLayout root) {
        rootStatus = addText(root, "硬件服务检测中…（不需要 root 授权）", 15);
        motorStatus = addText(root, "电机测试（真人监督，每次只做一个动作；异常立即按停止）\n"
            + "  角度：回中=0° 最左=-146° 最右=+146°（系统安全预设，不需要 root）\n"
            + "  状态：空闲(IDLE)", 15);
        addButton(root, "电机：连接", new View.OnClickListener() {
            @Override public void onClick(View v) {
                motorStatus.setText("正在连接…");
                controlExecutor.execute(new Runnable() {
                    @Override public void run() {
                        final OperationResult result = connectMotor();
                        runOnUiThread(new Runnable() {
                            @Override public void run() {
                                motorStatus.setText(result.success
                                    ? "电机已连接，状态：" + result.message : result.message);
                            }
                        });
                    }
                });
            }
        });
        addButton(root, "电机：读取状态", new View.OnClickListener() {
            @Override public void onClick(View v) {
                controlExecutor.execute(new Runnable() {
                    @Override public void run() {
                        final OperationResult state = motorState();
                        runOnUiThread(new Runnable() {
                            @Override public void run() {
                                motorStatus.setText(state.success
                                    ? "电机状态：" + state.message : "状态读取失败：" + state.message);
                            }
                        });
                    }
                });
            }
        });
        addButton(root, "电机：回中（0°）", new View.OnClickListener() {
            @Override public void onClick(View v) { motorStatus.setText("正在回中…"); motorAction(5, "已执行：回中 0°"); }
        });
        addButton(root, "电机：转到最左（-146°）", new View.OnClickListener() {
            @Override public void onClick(View v) { motorStatus.setText("正在转到最左…"); motorAction(3, "已执行：转到最左 -146°"); }
        });
        addButton(root, "电机：转到最右（+146°）", new View.OnClickListener() {
            @Override public void onClick(View v) { motorStatus.setText("正在转到最右…"); motorAction(4, "已执行：转到最右 +146°"); }
        });
        addButton(root, "电机：紧急停止", new View.OnClickListener() {
            @Override public void onClick(View v) { motorStatus.setText("正在停止…"); motorAction(6, "已执行：停止"); }
        });
        addButton(root, "电机：旋转到指定角度", new View.OnClickListener() {
            @Override public void onClick(View v) {
                final EditText input = new EditText(MainActivity.this);
                input.setHint("-146 到 +146，支持任意整数角度");
                input.setInputType(2 | 4096);
                new AlertDialog.Builder(MainActivity.this).setTitle("电机目标角度").setView(input)
                    .setNegativeButton("取消", null).setPositiveButton("执行", (d, w) -> {
                        final int target;
                        try { target = Integer.parseInt(input.getText().toString().trim()); }
                        catch (Exception e) { motorStatus.setText("角度格式错误"); return; }
                        if (target < -146 || target > 146) {
                            motorStatus.setText("角度必须在 -146..146"); return;
                        }
                        controlExecutor.execute(() -> {
                            try {
                                connectMotor();
                                motorAbsoluteCall(target);
                                showMotorStatus("已到达指定角度：" + target + "°");
                            } catch (Exception e) { showMotorStatus("角度旋转失败：" + e.getMessage()); }
                        });
                    }).show();
            }
        });
    }

    // ---------------- LED ----------------

    private void bindLedService() {
        Intent intent = new Intent();
        intent.setComponent(new ComponentName("com.jt600.led", "com.jt600.led.JT600LedService"));
        ledBound = bindService(intent, ledConnection, Context.BIND_AUTO_CREATE);
        if (!ledBound) ledStatus.setText("LED 服务绑定失败");
    }

    private String errorText(Exception e) {
        String message = e.getMessage();
        return e.getClass().getSimpleName() + (message == null ? "" : "：" + message);
    }

    private void showLedStatus(final String message) {
        runOnUiThread(new Runnable() {
            @Override public void run() { ledStatus.setText(message); }
        });
    }

    private void ledRun(final int action, final String doneMsg) {
        controlExecutor.execute(new Runnable() {
            @Override public void run() {
                IJT600LedService api = ledService;
                if (api == null) {
                    showLedStatus("LED 服务尚未连接");
                    return;
                }
                try {
                    if (action == 0) {
                        api.allOff(ledToken);
                    } else {
                        api.runChase(ledToken, 255, 80, 3);
                    }
                    showLedStatus(doneMsg);
                } catch (Exception e) {
                    showLedStatus("LED 执行失败：" + errorText(e));
                }
            }
        });
    }

    private void ledAll(final int startIdx, final int endIdx, final String msg) {
        controlExecutor.execute(new Runnable() {
            @Override public void run() {
                IJT600LedService api = ledService;
                if (api == null) {
                    showLedStatus("LED 服务尚未连接");
                    return;
                }
                StringBuilder bad = new StringBuilder();
                String firstFailure = "";
                for (int i = startIdx; i <= endIdx; i++) {
                    try {
                        api.setBrightness(ledToken, i / 16, i % 16, 255);
                    } catch (Exception e) {
                        bad.append(i).append(' ');
                        if (firstFailure.length() == 0) firstFailure = errorText(e);
                    }
                }
                final String fail = bad.toString();
                final String reason = firstFailure;
                runOnUiThread(new Runnable() {
                    @Override public void run() {
                        ledStatus.setText(fail.length() == 0 ? msg
                            : "LED 点亮失败；通道：" + fail + "；原因：" + reason);
                    }
                });
            }
        });
    }

    private void addLedSection(LinearLayout root) {
        ledStatus = addText(root, "LED 测试（左侧 0-15，右侧 16-31；以实际点亮的灯为准）\n  状态：未操作", 16);
        addButton(root, "LED：全部点亮（32 个）", new View.OnClickListener() {
            @Override public void onClick(View v) { ledStatus.setText("正在全部点亮…"); ledAll(0, 31, "已执行：全部点亮"); }
        });
        addButton(root, "LED：左侧点亮（0-15）", new View.OnClickListener() {
            @Override public void onClick(View v) { ledStatus.setText("正在点亮左侧…"); ledAll(0, 15, "已执行：左侧点亮"); }
        });
        addButton(root, "LED：右侧点亮（16-31）", new View.OnClickListener() {
            @Override public void onClick(View v) { ledStatus.setText("正在点亮右侧…"); ledAll(16, 31, "已执行：右侧点亮"); }
        });
        addButton(root, "LED：全部关闭", new View.OnClickListener() {
            @Override public void onClick(View v) { ledRun(0, "已执行：LED 全部关闭"); }
        });
        addButton(root, "LED：跑马灯（触发，左右两侧 3 轮）", new View.OnClickListener() {
            @Override public void onClick(View v) { ledRun(1, "已执行：跑马灯触发（255, 80ms, 3 轮）"); }
        });
    }

    // ---------------- UI helpers ----------------

    private TextView addText(LinearLayout root, String title, float size) {
        TextView tv = new TextView(this);
        tv.setText(title);
        tv.setTextSize(size);
        tv.setPadding(0, 20, 0, 4);
        root.addView(tv);
        return tv;
    }

    private void addButton(LinearLayout root, String label, View.OnClickListener l) {
        Button b = new Button(this);
        b.setText(label);
        b.setOnClickListener(l);
        root.addView(b);
    }

    private void showBattery() {
        Intent b = registerReceiver(null, new IntentFilter(Intent.ACTION_BATTERY_CHANGED));
        int level = b == null ? -1 : b.getIntExtra(BatteryManager.EXTRA_LEVEL, -1);
        int scale = b == null ? 100 : b.getIntExtra(BatteryManager.EXTRA_SCALE, 100);
        int voltage = b == null ? -1 : b.getIntExtra(BatteryManager.EXTRA_VOLTAGE, -1);
        int temp = b == null ? 0 : b.getIntExtra(BatteryManager.EXTRA_TEMPERATURE, 0);
        int status = b == null ? 0 : b.getIntExtra(BatteryManager.EXTRA_STATUS, 0);
        BatteryManager bm = (BatteryManager) getSystemService(BATTERY_SERVICE);
        int current = bm.getIntProperty(BatteryManager.BATTERY_PROPERTY_CURRENT_NOW);
        batteryValue.setText("电池信息（每 3 秒自动刷新）\n"
            + "  电量=" + level + "%/" + scale + "  电压=" + voltage + "mV\n"
            + "  温度=" + (temp / 10.0) + "C  电流=" + current + "uA（本机内核驱动不提供电流，恒 0）"
            + "  status=" + status);
    }

    @Override protected void onResume() {
        super.onResume();
        List<Sensor> sensors = sm.getSensorList(Sensor.TYPE_ALL);
        for (Sensor s : sensors) {
            if (s.getType() == Sensor.TYPE_LIGHT) { hasLight = true; sm.registerListener(this, s, SensorManager.SENSOR_DELAY_NORMAL); }
            if (s.getType() == Sensor.TYPE_PROXIMITY) { hasProximity = true; sm.registerListener(this, s, SensorManager.SENSOR_DELAY_NORMAL); }
        }
        if (!hasLight) lightValue.append("\n  （本机无光传感器）");
        if (!hasProximity) proximityValue.append("\n  （本机无距离传感器）");
    }

    @Override protected void onPause() {
        super.onPause();
        sm.unregisterListener(this);
    }

    @Override protected void onDestroy() {
        super.onDestroy();
        h.removeCallbacks(batteryRefresher);
        IJT600LedService api = ledService;
        if (api != null) {
            try { api.allOff(ledToken); } catch (RemoteException ignored) { }
            try { api.releaseClient(ledToken); } catch (RemoteException ignored) { }
        }
        ledService = null;
        if (ledBound) {
            unbindService(ledConnection);
            ledBound = false;
        }
        if (motorService != null) {
            if (motorRegistered) {
                try { motorTokenCall(6); } catch (RemoteException ignored) { }
                try { motorTokenCall(8); } catch (RemoteException ignored) { }
            }
        }
        motorRegistered = false;
        motorService = null;
        if (motorBound) {
            unbindService(motorConnection);
            motorBound = false;
        }
        controlExecutor.shutdownNow();
    }

    @Override public void onSensorChanged(SensorEvent e) {
        final float v = e.values[0];
        final float max = e.sensor.getMaximumRange();
        final int t = e.sensor.getType();
        runOnUiThread(new Runnable() {
            @Override public void run() {
                if (t == Sensor.TYPE_LIGHT) {
                    lightValue.setText("光传感器（遮挡/移开观察 lux 变化）\n  当前值：" + String.format(Locale.US, "%.1f lux", v));
                } else if (t == Sensor.TYPE_PROXIMITY) {
                    String nearFar = (v < max * 0.5f) ? "近 (遮挡)" : "远 (移开)";
                    proximityValue.setText("距离传感器（遮挡/移开观察 近/远 切换）\n  当前值：raw="
                        + String.format(Locale.US, "%.1f", v) + "  range="
                        + String.format(Locale.US, "%.1f", max) + "  → " + nearFar);
                }
            }
        });
    }

    @Override public void onAccuracyChanged(Sensor sensor, int accuracy) { }

    @Override public boolean onKeyDown(int keyCode, KeyEvent event) {
        if (keyCode == KeyEvent.KEYCODE_F1 || keyCode == KeyEvent.KEYCODE_F2 || keyCode == KeyEvent.KEYCODE_F3) {
            recordKey(keyCode, "DOWN");
            return true;
        }
        return super.onKeyDown(keyCode, event);
    }

    @Override public boolean onKeyUp(int keyCode, KeyEvent event) {
        if (keyCode == KeyEvent.KEYCODE_F1 || keyCode == KeyEvent.KEYCODE_F2 || keyCode == KeyEvent.KEYCODE_F3) {
            recordKey(keyCode, "UP");
            return true;
        }
        return super.onKeyUp(keyCode, event);
    }

    private String keyName(int keyCode) {
        switch (keyCode) {
            case KeyEvent.KEYCODE_F1: return "F1/头顶";
            case KeyEvent.KEYCODE_F2: return "F2/左耳";
            case KeyEvent.KEYCODE_F3: return "F3/右耳";
            default: return "key" + keyCode;
        }
    }

    private void recordKey(final int keyCode, final String state) {
        runOnUiThread(new Runnable() {
            @Override public void run() {
                keyValue.setText("三独立触摸键（依次触摸 头顶→左耳→右耳，各按下再松开）\n  最近："
                    + keyName(keyCode) + " " + state + "  (keycode " + keyCode + ")");
            }
        });
    }


}
