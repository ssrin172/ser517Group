// src/scripts/seedSensors.js
import mongoose from "mongoose";
import dotenv from "dotenv";
import { Sensor } from "../models/sensor.model.js";
import { DB_NAME } from "../constants.js";

dotenv.config({ path: './.env' });

// Construct the connection string using the environment variable and DB name
const dbURI = `${process.env.MONGODB_URI}/${DB_NAME}?retryWrites=true&w=majority`;
console.log("Connecting to:", dbURI);

mongoose.connect(dbURI, { useNewUrlParser: true, useUnifiedTopology: true })
    .then(() => {
        console.log("Connected to MongoDB");

        const sensorsData = [{
                sensorId: "sensor001",
                sensorName: "Ceiling Camera",
                coordinates: { x: 10, y: 20 },
                sensorType: "Camera",
                sensorTrackingRange: 30,
                deviceAngle: 120,
                description: "A high-definition camera that monitors the room for security and activity tracking.",
                mitigationDetails: "Ensure proper lighting and enforce privacy protocols to prevent unauthorized access.",
                purpose: "To provide visual surveillance and enhance overall room security.",
                // Using canonical beaconGroupId ("3B807668" comes before "57944B02" when sorted)
                beaconGroupId: "3B807668-57944B02",
                dataCaptures: "Video/Image"
            },
            {
                sensorId: "sensor002",
                sensorName: "Ambient Microphone",
                coordinates: { x: 15, y: 25 },
                sensorType: "Microphone",
                sensorTrackingRange: 50,
                deviceAngle: 360,
                description: "A sensitive microphone that captures ambient audio data in the room.",
                mitigationDetails: "Audio processing is conducted with strict privacy protocols and local data handling.",
                purpose: "To detect voice commands and monitor environmental sound for smart responses.",
                beaconGroupId: "3B807668-57944B02",
                dataCaptures: "Audio"
            },
            {
                sensorId: "sensor003",
                sensorName: "Temperature Sensor",
                coordinates: { x: 5, y: 10 },
                sensorType: "Temperature",
                sensorTrackingRange: 20,
                deviceAngle: 360,
                description: "Monitors room temperature to ensure a comfortable climate.",
                mitigationDetails: "Regular calibration is performed to maintain accurate readings.",
                purpose: "To assist in climate control and energy efficiency within the room.",
                beaconGroupId: "3B807668-57944B02",
                dataCaptures: "Temperature Readings"
            },
            {
                sensorId: "sensor004",
                sensorName: "Motion Detector",
                coordinates: { x: 12, y: 18 },
                sensorType: "Motion",
                sensorTrackingRange: 25,
                deviceAngle: 360,
                description: "Detects movement within its range to trigger alerts or actions.",
                mitigationDetails: "Optimized to minimize false alarms from non-intrusive movements.",
                purpose: "To enhance room security by detecting unauthorized movement.",
                beaconGroupId: "3B807668-57944B02",
                dataCaptures: "Motion Events"
            }
        ];

        // Clear existing sensors to avoid duplicate key errors
        return Sensor.deleteMany({})
            .then(() => Sensor.insertMany(sensorsData));
    })
    .then((docs) => {
        console.log("Sensors added:", docs);
        mongoose.disconnect();
    })
    .catch((err) => {
        console.error("Error adding sensors:", err);
        mongoose.disconnect();
    });