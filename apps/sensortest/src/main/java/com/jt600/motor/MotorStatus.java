package com.jt600.motor;

import android.os.Parcel;
import android.os.Parcelable;

public final class MotorStatus implements Parcelable {
    public static final int STATE_IDLE = 0;
    public static final int STATE_MOVING = 1;
    public static final int STATE_FAULT = 2;

    public final int state;
    public final int measuredDegree;
    public final int commandedDegree;
    public final int requestedDegree;
    public final int effectiveTargetDegree;
    public final int lastResult;
    public final long deadlineMs;

    public MotorStatus(int state, int measuredDegree, int commandedDegree,
            int requestedDegree, int effectiveTargetDegree, int lastResult,
            long deadlineMs) {
        this.state = state;
        this.measuredDegree = measuredDegree;
        this.commandedDegree = commandedDegree;
        this.requestedDegree = requestedDegree;
        this.effectiveTargetDegree = effectiveTargetDegree;
        this.lastResult = lastResult;
        this.deadlineMs = deadlineMs;
    }

    private MotorStatus(Parcel in) {
        state = in.readInt();
        measuredDegree = in.readInt();
        commandedDegree = in.readInt();
        requestedDegree = in.readInt();
        effectiveTargetDegree = in.readInt();
        lastResult = in.readInt();
        deadlineMs = in.readLong();
    }

    public static final Creator<MotorStatus> CREATOR = new Creator<MotorStatus>() {
        @Override
        public MotorStatus createFromParcel(Parcel in) {
            return new MotorStatus(in);
        }

        @Override
        public MotorStatus[] newArray(int size) {
            return new MotorStatus[size];
        }
    };

    @Override
    public int describeContents() {
        return 0;
    }

    @Override
    public void writeToParcel(Parcel dest, int flags) {
        dest.writeInt(state);
        dest.writeInt(measuredDegree);
        dest.writeInt(commandedDegree);
        dest.writeInt(requestedDegree);
        dest.writeInt(effectiveTargetDegree);
        dest.writeInt(lastResult);
        dest.writeLong(deadlineMs);
    }
}
