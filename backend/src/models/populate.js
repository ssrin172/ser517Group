import mongoose from "mongoose";
import { Sensor } from "./sensor.model.js"; 
import { BeaconGroup } from "./beaconGroup.model.js"; // Adjust path

const mongoURI = "mongodb://localhost:27017/FacultyGroup7"; 

async function populateDatabase() {
  try {
    // Connect to MongoDB
    await mongoose.connect(mongoURI, { useNewUrlParser: true, useUnifiedTopology: true });

    console.log("Connected to MongoDB...");

    // Clear existing data
    await Sensor.deleteMany({});
    await BeaconGroup.deleteMany({});

    // Insert dummy sensors
    const sensors = await Sensor.insertMany([
      {
        sensorId: "S001",
        sensorName: "Camera 1",
        coordinates: { x: 10, y: 20 },
        sensorTrackingRange: 50,
        deviceAngle: 90,
        description: "Security camera at entrance",
        mitigationDetails: "Blur sensitive areas",
        purpose: "Security monitoring",
        beaconGroupId: "BG001",
      },
      {
        sensorId: "S002",
        sensorName: "Motion Sensor 1",
        coordinates: { x: 15, y: 25 },
        sensorTrackingRange: 30,
        description: "Detects motion in hallway",
        mitigationDetails: "Deactivate after 10 PM",
        purpose: "Motion detection",
        beaconGroupId: "BG001",
      },
    ]);

    console.log("Inserted sensors:", sensors);

    // Insert dummy beacon groups
    const beaconGroups = await BeaconGroup.insertMany([
      {
        beaconGroupId: "BG001",
        beaconIds: ["B001", "B002"],
        sensors: sensors.map((s) => s._id),
      },
    ]);

    console.log("Inserted beacon groups:", beaconGroups);

    console.log("Database seeding complete.");
  } catch (error) {
    console.error("Error seeding database:", error);
  } finally {
    mongoose.connection.close();
  }
}

// 
populateDatabase();
