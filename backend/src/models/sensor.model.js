import mongoose from "mongoose";

const SensorSchema = new mongoose.Schema({
    sensor_id: { type: String, required: true, unique: true },
    sensor_name: { type: String, required: true },
    coordinates: {
        x: { type: Number, required: true },
        y: { type: Number, required: true }
    },
    sensor_tracking_range: { type: Number, required: true },
    device_angle: {
        type: Number,
        default: 360, // Default to 360 degrees for non-camera sensors
        min: 0,
        max: 360
    },
    description: { type: String },
    mitigation_details: { type: String },
    purpose: { type: String }
});

// Middleware to enforce device_angle for camera sensors
SensorSchema.pre("save", function(next) {
    if (this.sensor_name.toLowerCase().includes("camera") && (this.device_angle === undefined || this.device_angle === 360)) {
        return next(new Error("Camera sensors must have a valid device_angle between 0 and 360 degrees."));
    }
    next();
});

const Sensor = mongoose.model("Sensor", SensorSchema);
export default Sensor;