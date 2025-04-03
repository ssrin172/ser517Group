import { asyncHandler } from "../utils/asyncHandler.js";
import { ApiError } from "../utils/ApiError.js";
import { ApiResponse } from "../utils/ApiResponse.js";
import { BeaconGroup } from "../models/beaconGroup.model.js";
import { Sensor } from "../models/sensor.model.js";

// Create or Update a Beacon with linked sensors and coordinates
const createOrUpdateBeacon = asyncHandler(async(req, res) => {
    const { beaconGroupId, coordinates } = req.body;

    // Check if the beacon group already exists
    let beacon = await BeaconGroup.findOne({ beaconGroupId });

    if (!beacon) {
        // If beacon doesn't exist, create a new one
        beacon = new BeaconGroup({
            beaconGroupId,
            beaconIds: [],
            coordinates,
            sensors: [],
        });
    } else {
        // If beacon exists, update coordinates
        beacon.coordinates = coordinates;
    }

    // Save the beacon to the database
    await beacon.save();

    return res.status(200).json(
        new ApiResponse(200, beacon, "Beacon data saved/updated successfully")
    );
});

// Fetch sensors linked to the given beacon group ID
const getSensorsForBeaconGroup = asyncHandler(async(req, res) => {
    const { beaconGroupId } = req.params;

    // Find the beacon with the given group ID
    const beacon = await BeaconGroup.findOne({ beaconGroupId }).populate("sensors");

    if (!beacon) {
        throw new ApiError(404, "Beacon group not found");
    }

    // Send back the linked sensors data
    return res.status(200).json(
        new ApiResponse(200, beacon.sensors, "Sensors fetched successfully")
    );
});

// Group two beacons and fetch linked sensors
const groupBeaconsAndGetSensors = asyncHandler(async(req, res) => {
    const { beaconId1, beaconId2, coordinates } = req.body;

    // Generate a unique Beacon Group ID
    const beaconGroupId = `${beaconId1}-${beaconId2}`;

    // Check if the beacon group already exists
    let beacon = await BeaconGroup.findOne({ beaconGroupId });

    if (!beacon) {
        // If beacon doesn't exist, create a new one
        beacon = new BeaconGroup({
            beaconGroupId,
            beaconIds: [beaconId1, beaconId2],
            coordinates,
            sensors: [],
        });
    } else {
        // If beacon exists, update coordinates
        beacon.coordinates = coordinates;
    }

    // Save or update the beacon in the database
    await beacon.save();

    // Fetch the linked sensors for the new or updated beacon group
    const sensors = await Sensor.find({ beaconGroupId });

    return res.status(200).json(
        new ApiResponse(200, { beacon, sensors }, "Beacon group and sensors updated")
    );
});

export {
    createOrUpdateBeacon,
    getSensorsForBeaconGroup,
    groupBeaconsAndGetSensors,
};