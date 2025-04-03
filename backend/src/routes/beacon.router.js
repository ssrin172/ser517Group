import { Router } from "express";
import {
    createOrUpdateBeacon,
    getSensorsForBeaconGroup,
    groupBeaconsAndGetSensors
} from "../controllers/beacon.controller.js";

const router = Router();

router.route("/").post(createOrUpdateBeacon);
router.route("/:beaconGroupId/sensors").get(getSensorsForBeaconGroup);
router.route("/group").post(groupBeaconsAndGetSensors);

export default router;