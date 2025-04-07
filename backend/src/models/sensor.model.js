import mongoose from "mongoose";

const SensorSchema = new mongoose.Schema({
    sensorId: { type: String, required: true, unique: true },
    sensorName: { type: String, required: true },
    coordinates: {
        x: { type: Number, required: true },
        y: { type: Number, required: true }
    },
    sensorType: { type: String, required: true },
    sensorTrackingRange: { type: Number, required: true },
    deviceAngle: {
        type: Number,
        default: 360, // Default to 360 degrees for non-camera sensors
        min: 0,
        max: 360
    },
    description: { type: String },
    mitigationDetails: { type: String },
    purpose: { type: String },
    beaconGroupId: { type: String, required: true },
    dataCaptures: { type: String, required: true } // Linked to BeaconGroup
});

// Middleware to enforce deviceAngle for camera sensors
SensorSchema.pre("save", function(next) {
    if (this.sensorName.toLowerCase().includes("camera") && (this.deviceAngle === undefined || this.deviceAngle === 360)) {
        return next(new Error("Camera sensors must have a valid deviceAngle between 0 and 360 degrees."));
    }
    next();
});

export const Sensor = mongoose.model("Sensor", SensorSchema);