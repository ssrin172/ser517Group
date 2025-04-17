// src/controllers/beacon.controller.js
import { asyncHandler } from "../utils/asyncHandler.js";
import { ApiError } from "../utils/ApiError.js";
import { ApiResponse } from "../utils/ApiResponse.js";
import { Sensor } from "../models/sensor.model.js";

/**
 * Helper function to normalize a beaconGroupId.
 * This ensures the two beacon IDs are always sorted in a consistent order.
 */
const normalizeBeaconGroupId = (beaconGroupId) => {
    return beaconGroupId.split('-').sort().join('-');
};

/**
 * Create or update sensors for a given beacon group.
 * The request body must contain:
 * {
 *   "beaconGroupId": "112456485-143285168", // or any order, it will be normalized
 *   "sensors": [
 *     {
 *       "sensorId": "sensor001",
 *       "sensorName": "Ceiling Camera",
 *       "coordinates": { "x": 10, "y": 20 },
 *       "sensorType": "Camera",
 *       "sensorTrackingRange": 30,
 *       "deviceAngle": 120,
 *       "description": "...",
 *       "mitigationDetails": "...",
 *       "purpose": "...",
 *       "dataCaptures": "Video/Image"
 *     },
 *     { ... }
 *   ]
 * }
 */
const createOrUpdateSensors = asyncHandler(async(req, res) => {
    let { beaconGroupId, sensors } = req.body;
    if (!beaconGroupId || !sensors || !Array.isArray(sensors)) {
        throw new ApiError(400, "beaconGroupId and a sensors array are required");
    }

    // Normalize the beaconGroupId to ensure consistency
    beaconGroupId = normalizeBeaconGroupId(beaconGroupId);

    // For each sensor, set the normalized beaconGroupId and perform an upsert operation
    const sensorPromises = sensors.map(sensorData => {
        sensorData.beaconGroupId = beaconGroupId;
        return Sensor.findOneAndUpdate({ sensorId: sensorData.sensorId },
            sensorData, { new: true, upsert: true }
        );
    });

    const updatedSensors = await Promise.all(sensorPromises);

    return res.status(200).json(
        new ApiResponse(200, updatedSensors, "Sensors created/updated successfully")
    );
});

/**
 * Get sensors for a given beacon group.
 * The beaconGroupId is provided as a URL parameter.
 */
const getSensorsForBeaconGroup = asyncHandler(async(req, res) => {
    // Normalize the beaconGroupId from the URL parameter
    const normalizedBeaconGroupId = normalizeBeaconGroupId(req.params.beaconGroupId);
    const sensors = await Sensor.find({ beaconGroupId: normalizedBeaconGroupId });
    if (!sensors || sensors.length === 0) {
        throw new ApiError(404, "No sensors found for this beacon group");
    }
    return res.status(200).json(
        new ApiResponse(200, sensors, "Sensors fetched successfully")
    );
});

export { createOrUpdateSensors, getSensorsForBeaconGroup  };