/*
 * This file is auto-generated.  DO NOT MODIFY.
 */
package com.jt600.motor;
public interface IJT600MotorService extends android.os.IInterface
{
  /** Default implementation for IJT600MotorService. */
  public static class Default implements com.jt600.motor.IJT600MotorService
  {
    @Override public void registerClient(android.os.IBinder token, com.jt600.motor.IJT600MotorListener listener) throws android.os.RemoteException
    {
    }
    @Override public void moveRelative(android.os.IBinder token, int deltaDegree) throws android.os.RemoteException
    {
    }
    @Override public void stop(android.os.IBinder token) throws android.os.RemoteException
    {
    }
    @Override public com.jt600.motor.MotorStatus getStatus() throws android.os.RemoteException
    {
      return null;
    }
    @Override public void releaseClient(android.os.IBinder token) throws android.os.RemoteException
    {
    }
    @Override
    public android.os.IBinder asBinder() {
      return null;
    }
  }
  /** Local-side IPC implementation stub class. */
  public static abstract class Stub extends android.os.Binder implements com.jt600.motor.IJT600MotorService
  {
    /** Construct the stub at attach it to the interface. */
    public Stub()
    {
      this.attachInterface(this, DESCRIPTOR);
    }
    /**
     * Cast an IBinder object into an com.jt600.motor.IJT600MotorService interface,
     * generating a proxy if needed.
     */
    public static com.jt600.motor.IJT600MotorService asInterface(android.os.IBinder obj)
    {
      if ((obj==null)) {
        return null;
      }
      android.os.IInterface iin = obj.queryLocalInterface(DESCRIPTOR);
      if (((iin!=null)&&(iin instanceof com.jt600.motor.IJT600MotorService))) {
        return ((com.jt600.motor.IJT600MotorService)iin);
      }
      return new com.jt600.motor.IJT600MotorService.Stub.Proxy(obj);
    }
    @Override public android.os.IBinder asBinder()
    {
      return this;
    }
    @Override public boolean onTransact(int code, android.os.Parcel data, android.os.Parcel reply, int flags) throws android.os.RemoteException
    {
      java.lang.String descriptor = DESCRIPTOR;
      if (code >= android.os.IBinder.FIRST_CALL_TRANSACTION && code <= android.os.IBinder.LAST_CALL_TRANSACTION) {
        data.enforceInterface(descriptor);
      }
      switch (code)
      {
        case INTERFACE_TRANSACTION:
        {
          reply.writeString(descriptor);
          return true;
        }
      }
      switch (code)
      {
        case TRANSACTION_registerClient:
        {
          android.os.IBinder _arg0;
          _arg0 = data.readStrongBinder();
          com.jt600.motor.IJT600MotorListener _arg1;
          _arg1 = com.jt600.motor.IJT600MotorListener.Stub.asInterface(data.readStrongBinder());
          this.registerClient(_arg0, _arg1);
          reply.writeNoException();
          break;
        }
        case TRANSACTION_moveRelative:
        {
          android.os.IBinder _arg0;
          _arg0 = data.readStrongBinder();
          int _arg1;
          _arg1 = data.readInt();
          this.moveRelative(_arg0, _arg1);
          reply.writeNoException();
          break;
        }
        case TRANSACTION_stop:
        {
          android.os.IBinder _arg0;
          _arg0 = data.readStrongBinder();
          this.stop(_arg0);
          reply.writeNoException();
          break;
        }
        case TRANSACTION_getStatus:
        {
          com.jt600.motor.MotorStatus _result = this.getStatus();
          reply.writeNoException();
          _Parcel.writeTypedObject(reply, _result, android.os.Parcelable.PARCELABLE_WRITE_RETURN_VALUE);
          break;
        }
        case TRANSACTION_releaseClient:
        {
          android.os.IBinder _arg0;
          _arg0 = data.readStrongBinder();
          this.releaseClient(_arg0);
          reply.writeNoException();
          break;
        }
        default:
        {
          return super.onTransact(code, data, reply, flags);
        }
      }
      return true;
    }
    private static class Proxy implements com.jt600.motor.IJT600MotorService
    {
      private android.os.IBinder mRemote;
      Proxy(android.os.IBinder remote)
      {
        mRemote = remote;
      }
      @Override public android.os.IBinder asBinder()
      {
        return mRemote;
      }
      public java.lang.String getInterfaceDescriptor()
      {
        return DESCRIPTOR;
      }
      @Override public void registerClient(android.os.IBinder token, com.jt600.motor.IJT600MotorListener listener) throws android.os.RemoteException
      {
        android.os.Parcel _data = android.os.Parcel.obtain();
        android.os.Parcel _reply = android.os.Parcel.obtain();
        try {
          _data.writeInterfaceToken(DESCRIPTOR);
          _data.writeStrongBinder(token);
          _data.writeStrongInterface(listener);
          boolean _status = mRemote.transact(Stub.TRANSACTION_registerClient, _data, _reply, 0);
          _reply.readException();
        }
        finally {
          _reply.recycle();
          _data.recycle();
        }
      }
      @Override public void moveRelative(android.os.IBinder token, int deltaDegree) throws android.os.RemoteException
      {
        android.os.Parcel _data = android.os.Parcel.obtain();
        android.os.Parcel _reply = android.os.Parcel.obtain();
        try {
          _data.writeInterfaceToken(DESCRIPTOR);
          _data.writeStrongBinder(token);
          _data.writeInt(deltaDegree);
          boolean _status = mRemote.transact(Stub.TRANSACTION_moveRelative, _data, _reply, 0);
          _reply.readException();
        }
        finally {
          _reply.recycle();
          _data.recycle();
        }
      }
      @Override public void stop(android.os.IBinder token) throws android.os.RemoteException
      {
        android.os.Parcel _data = android.os.Parcel.obtain();
        android.os.Parcel _reply = android.os.Parcel.obtain();
        try {
          _data.writeInterfaceToken(DESCRIPTOR);
          _data.writeStrongBinder(token);
          boolean _status = mRemote.transact(Stub.TRANSACTION_stop, _data, _reply, 0);
          _reply.readException();
        }
        finally {
          _reply.recycle();
          _data.recycle();
        }
      }
      @Override public com.jt600.motor.MotorStatus getStatus() throws android.os.RemoteException
      {
        android.os.Parcel _data = android.os.Parcel.obtain();
        android.os.Parcel _reply = android.os.Parcel.obtain();
        com.jt600.motor.MotorStatus _result;
        try {
          _data.writeInterfaceToken(DESCRIPTOR);
          boolean _status = mRemote.transact(Stub.TRANSACTION_getStatus, _data, _reply, 0);
          _reply.readException();
          _result = _Parcel.readTypedObject(_reply, com.jt600.motor.MotorStatus.CREATOR);
        }
        finally {
          _reply.recycle();
          _data.recycle();
        }
        return _result;
      }
      @Override public void releaseClient(android.os.IBinder token) throws android.os.RemoteException
      {
        android.os.Parcel _data = android.os.Parcel.obtain();
        android.os.Parcel _reply = android.os.Parcel.obtain();
        try {
          _data.writeInterfaceToken(DESCRIPTOR);
          _data.writeStrongBinder(token);
          boolean _status = mRemote.transact(Stub.TRANSACTION_releaseClient, _data, _reply, 0);
          _reply.readException();
        }
        finally {
          _reply.recycle();
          _data.recycle();
        }
      }
    }
    static final int TRANSACTION_registerClient = (android.os.IBinder.FIRST_CALL_TRANSACTION + 0);
    static final int TRANSACTION_moveRelative = (android.os.IBinder.FIRST_CALL_TRANSACTION + 1);
    static final int TRANSACTION_stop = (android.os.IBinder.FIRST_CALL_TRANSACTION + 2);
    static final int TRANSACTION_getStatus = (android.os.IBinder.FIRST_CALL_TRANSACTION + 3);
    static final int TRANSACTION_releaseClient = (android.os.IBinder.FIRST_CALL_TRANSACTION + 4);
  }
  public static final java.lang.String DESCRIPTOR = "com.jt600.motor.IJT600MotorService";
  public void registerClient(android.os.IBinder token, com.jt600.motor.IJT600MotorListener listener) throws android.os.RemoteException;
  public void moveRelative(android.os.IBinder token, int deltaDegree) throws android.os.RemoteException;
  public void stop(android.os.IBinder token) throws android.os.RemoteException;
  public com.jt600.motor.MotorStatus getStatus() throws android.os.RemoteException;
  public void releaseClient(android.os.IBinder token) throws android.os.RemoteException;
  /** @hide */
  static class _Parcel {
    static private <T> T readTypedObject(
        android.os.Parcel parcel,
        android.os.Parcelable.Creator<T> c) {
      if (parcel.readInt() != 0) {
          return c.createFromParcel(parcel);
      } else {
          return null;
      }
    }
    static private <T extends android.os.Parcelable> void writeTypedObject(
        android.os.Parcel parcel, T value, int parcelableFlags) {
      if (value != null) {
        parcel.writeInt(1);
        value.writeToParcel(parcel, parcelableFlags);
      } else {
        parcel.writeInt(0);
      }
    }
  }
}
