/*
 * This file is auto-generated.  DO NOT MODIFY.
 */
package com.jt600.led;
public interface IJT600LedService extends android.os.IInterface
{
  /** Default implementation for IJT600LedService. */
  public static class Default implements com.jt600.led.IJT600LedService
  {
    @Override public void registerClient(android.os.IBinder token) throws android.os.RemoteException
    {
    }
    @Override public void setBrightness(android.os.IBinder token, int side, int channel, int brightness) throws android.os.RemoteException
    {
    }
    @Override public int getBrightness(int side, int channel) throws android.os.RemoteException
    {
      return 0;
    }
    @Override public void runChase(android.os.IBinder token, int brightness, int dwellMillis, int cycles) throws android.os.RemoteException
    {
    }
    @Override public void allOff(android.os.IBinder token) throws android.os.RemoteException
    {
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
  public static abstract class Stub extends android.os.Binder implements com.jt600.led.IJT600LedService
  {
    /** Construct the stub at attach it to the interface. */
    public Stub()
    {
      this.attachInterface(this, DESCRIPTOR);
    }
    /**
     * Cast an IBinder object into an com.jt600.led.IJT600LedService interface,
     * generating a proxy if needed.
     */
    public static com.jt600.led.IJT600LedService asInterface(android.os.IBinder obj)
    {
      if ((obj==null)) {
        return null;
      }
      android.os.IInterface iin = obj.queryLocalInterface(DESCRIPTOR);
      if (((iin!=null)&&(iin instanceof com.jt600.led.IJT600LedService))) {
        return ((com.jt600.led.IJT600LedService)iin);
      }
      return new com.jt600.led.IJT600LedService.Stub.Proxy(obj);
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
          this.registerClient(_arg0);
          reply.writeNoException();
          break;
        }
        case TRANSACTION_setBrightness:
        {
          android.os.IBinder _arg0;
          _arg0 = data.readStrongBinder();
          int _arg1;
          _arg1 = data.readInt();
          int _arg2;
          _arg2 = data.readInt();
          int _arg3;
          _arg3 = data.readInt();
          this.setBrightness(_arg0, _arg1, _arg2, _arg3);
          reply.writeNoException();
          break;
        }
        case TRANSACTION_getBrightness:
        {
          int _arg0;
          _arg0 = data.readInt();
          int _arg1;
          _arg1 = data.readInt();
          int _result = this.getBrightness(_arg0, _arg1);
          reply.writeNoException();
          reply.writeInt(_result);
          break;
        }
        case TRANSACTION_runChase:
        {
          android.os.IBinder _arg0;
          _arg0 = data.readStrongBinder();
          int _arg1;
          _arg1 = data.readInt();
          int _arg2;
          _arg2 = data.readInt();
          int _arg3;
          _arg3 = data.readInt();
          this.runChase(_arg0, _arg1, _arg2, _arg3);
          reply.writeNoException();
          break;
        }
        case TRANSACTION_allOff:
        {
          android.os.IBinder _arg0;
          _arg0 = data.readStrongBinder();
          this.allOff(_arg0);
          reply.writeNoException();
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
    private static class Proxy implements com.jt600.led.IJT600LedService
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
      @Override public void registerClient(android.os.IBinder token) throws android.os.RemoteException
      {
        android.os.Parcel _data = android.os.Parcel.obtain();
        android.os.Parcel _reply = android.os.Parcel.obtain();
        try {
          _data.writeInterfaceToken(DESCRIPTOR);
          _data.writeStrongBinder(token);
          boolean _status = mRemote.transact(Stub.TRANSACTION_registerClient, _data, _reply, 0);
          _reply.readException();
        }
        finally {
          _reply.recycle();
          _data.recycle();
        }
      }
      @Override public void setBrightness(android.os.IBinder token, int side, int channel, int brightness) throws android.os.RemoteException
      {
        android.os.Parcel _data = android.os.Parcel.obtain();
        android.os.Parcel _reply = android.os.Parcel.obtain();
        try {
          _data.writeInterfaceToken(DESCRIPTOR);
          _data.writeStrongBinder(token);
          _data.writeInt(side);
          _data.writeInt(channel);
          _data.writeInt(brightness);
          boolean _status = mRemote.transact(Stub.TRANSACTION_setBrightness, _data, _reply, 0);
          _reply.readException();
        }
        finally {
          _reply.recycle();
          _data.recycle();
        }
      }
      @Override public int getBrightness(int side, int channel) throws android.os.RemoteException
      {
        android.os.Parcel _data = android.os.Parcel.obtain();
        android.os.Parcel _reply = android.os.Parcel.obtain();
        int _result;
        try {
          _data.writeInterfaceToken(DESCRIPTOR);
          _data.writeInt(side);
          _data.writeInt(channel);
          boolean _status = mRemote.transact(Stub.TRANSACTION_getBrightness, _data, _reply, 0);
          _reply.readException();
          _result = _reply.readInt();
        }
        finally {
          _reply.recycle();
          _data.recycle();
        }
        return _result;
      }
      @Override public void runChase(android.os.IBinder token, int brightness, int dwellMillis, int cycles) throws android.os.RemoteException
      {
        android.os.Parcel _data = android.os.Parcel.obtain();
        android.os.Parcel _reply = android.os.Parcel.obtain();
        try {
          _data.writeInterfaceToken(DESCRIPTOR);
          _data.writeStrongBinder(token);
          _data.writeInt(brightness);
          _data.writeInt(dwellMillis);
          _data.writeInt(cycles);
          boolean _status = mRemote.transact(Stub.TRANSACTION_runChase, _data, _reply, 0);
          _reply.readException();
        }
        finally {
          _reply.recycle();
          _data.recycle();
        }
      }
      @Override public void allOff(android.os.IBinder token) throws android.os.RemoteException
      {
        android.os.Parcel _data = android.os.Parcel.obtain();
        android.os.Parcel _reply = android.os.Parcel.obtain();
        try {
          _data.writeInterfaceToken(DESCRIPTOR);
          _data.writeStrongBinder(token);
          boolean _status = mRemote.transact(Stub.TRANSACTION_allOff, _data, _reply, 0);
          _reply.readException();
        }
        finally {
          _reply.recycle();
          _data.recycle();
        }
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
    static final int TRANSACTION_setBrightness = (android.os.IBinder.FIRST_CALL_TRANSACTION + 1);
    static final int TRANSACTION_getBrightness = (android.os.IBinder.FIRST_CALL_TRANSACTION + 2);
    static final int TRANSACTION_runChase = (android.os.IBinder.FIRST_CALL_TRANSACTION + 3);
    static final int TRANSACTION_allOff = (android.os.IBinder.FIRST_CALL_TRANSACTION + 4);
    static final int TRANSACTION_releaseClient = (android.os.IBinder.FIRST_CALL_TRANSACTION + 5);
  }
  public static final java.lang.String DESCRIPTOR = "com.jt600.led.IJT600LedService";
  public void registerClient(android.os.IBinder token) throws android.os.RemoteException;
  public void setBrightness(android.os.IBinder token, int side, int channel, int brightness) throws android.os.RemoteException;
  public int getBrightness(int side, int channel) throws android.os.RemoteException;
  public void runChase(android.os.IBinder token, int brightness, int dwellMillis, int cycles) throws android.os.RemoteException;
  public void allOff(android.os.IBinder token) throws android.os.RemoteException;
  public void releaseClient(android.os.IBinder token) throws android.os.RemoteException;
}
