import mongoose from "mongoose";

const BeaconGroupSchema = new mongoose.Schema({
    beaconGroupId: { type: String, required: true, unique: true }, // Combination of two beacon IDs
    beaconIds: [{ type: String, required: true }], // Array of exactly two beacon IDs
    sensors: [{ type: mongoose.Schema.Types.ObjectId, ref: "Sensor" }] // References Sensor model
});

export const BeaconGroup = mongoose.model("BeaconGroup", BeaconGroupSchema);