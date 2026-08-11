package android.app;

import android.content.ComponentName;
import android.content.Context;
import android.content.Intent;
import android.content.ServiceConnection;
import android.os.UserHandle;

/** Compile-time stub; the framework ContextImpl is used at runtime. */
public class ContextImpl {
    public static Context createSystemContext(ActivityThread at) { return null; }
    public boolean bindServiceAsUser(Intent service, ServiceConnection conn, int flags, UserHandle user) { return false; }
    public void unbindService(ServiceConnection conn) { }
}