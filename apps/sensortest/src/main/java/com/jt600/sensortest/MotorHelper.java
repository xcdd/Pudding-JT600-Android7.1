package com.jt600.sensortest;

import android.content.ComponentName;
import android.content.Context;
import android.content.Intent;
import android.content.ServiceConnection;
import android.os.Binder;
import android.os.IBinder;
import android.os.Looper;
import android.os.RemoteException;

import com.jt600.motor.IJT600MotorListener;
import com.jt600.motor.IJT600MotorService;
import com.jt600.motor.MotorStatus;

/** 以 UID 1000 运行：绑定电机服务并执行一次相对旋转（自定义角度）。 */
public final class MotorHelper {

    public static void main(String[] args) throws Exception {
        int angleLocal = 0;
        try { angleLocal = args.length > 0 ? Integer.parseInt(args[0]) : 0; } catch (Exception e) { angleLocal = 0; }
        final int angle = angleLocal;
        System.out.println("HELPER_START angle=" + angle);

        Looper.prepareMainLooper();
        Object atObj = null;
        try {
            java.lang.reflect.Constructor<?> ctor = Class.forName("android.app.ActivityThread").getDeclaredConstructor();
            ctor.setAccessible(true);
            atObj = ctor.newInstance();
        } catch (Exception e) {
            System.out.println("ERR at-ctor " + e);
            return;
        }
        final android.app.ContextImpl ctx;
        try {
            java.lang.reflect.Method m = Class.forName("android.app.ContextImpl").getDeclaredMethod(
                    "createSystemContext", Class.forName("android.app.ActivityThread"));
            m.setAccessible(true);
            ctx = (android.app.ContextImpl) m.invoke(null, atObj);
        } catch (Exception e) {
            System.out.println("ERR ctx " + e);
            return;
        }

        final Object done = new Object();
        final IBinder token = new Binder();
        ServiceConnection conn = new ServiceConnection() {
            @Override public void onServiceConnected(ComponentName n, IBinder b) {
                try {
                    IJT600MotorService svc = IJT600MotorService.Stub.asInterface(b);
                    svc.registerClient(token, new IJT600MotorListener.Stub() {
                        @Override public void onStatusChanged(MotorStatus s) { }
                    });
                    svc.moveRelative(token, angle);
                    Thread.sleep(500);
                    MotorStatus st = svc.getStatus();
                    System.out.println("OK angle=" + angle + " state=" + st.state
                            + " measured=" + st.measuredDegree
                            + " lastResult=" + st.lastResult);
                    svc.releaseClient(token);
                } catch (Exception e) {
                    System.out.println("ERR move " + e.getClass().getSimpleName() + ": " + e.getMessage());
                } finally {
                    synchronized (done) { done.notifyAll(); }
                    Looper.myLooper().quitSafely();
                }
            }
            @Override public void onServiceDisconnected(ComponentName n) { }
        };

        new Thread(new Runnable() {
            @Override public void run() {
                Intent i = new Intent();
                i.setComponent(new ComponentName("com.jt600.motor", "com.jt600.motor.JT600MotorService"));
                boolean ok = false;
                try {
                    java.lang.reflect.Method bm = Class.forName("android.app.ContextImpl").getMethod("bindServiceAsUser", Intent.class, ServiceConnection.class, int.class, android.os.UserHandle.class);
                    Object uh = Class.forName("android.os.UserHandle").getField("SYSTEM").get(null);
                    ok = ((Boolean) bm.invoke(ctx, i, conn, Integer.valueOf(Context.BIND_AUTO_CREATE), uh)).booleanValue();
                } catch (Exception e) { System.out.println("STEP: bind err " + e); }
                System.out.println("STEP: bind=" + ok);
                if (!ok) { Looper.myLooper().quitSafely(); return; }
                synchronized (done) {
                    try { done.wait(10000); } catch (InterruptedException e) { }
                }
                try { ctx.unbindService(conn); } catch (Exception e) { }
            }
        }).start();

        Looper.loop();
        System.out.println("HELPER_END");
    }
}