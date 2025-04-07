// src/routes/beacon.routes.js
import { Router } from "express";
import { createOrUpdateSensors, getSensorsForBeaconGroup } from "../controllers/beacon.controller.js";

const router = Router();

// POST endpoint to create or update sensors for a beacon group.
// The request body must include beaconGroupId and an array of sensor objects.
router.post("/", createOrUpdateSensors);

// GET endpoint to retrieve sensors for a given beacon group.
// The beaconGroupId in the URL will be normalized.
router.get("/:beaconGroupId/sensors", getSensorsForBeaconGroup);

export  default  router;