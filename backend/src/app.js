import express from 'express';
import cors from 'cors';

const app = express();

// configuring cors
app.use(cors({
    origin: process.env.CORS_ORIGIN || '*',
    credentials: true,
}));

// middlewares
app.use(express.json({ limit: "16kb" }));
app.use(express.urlencoded({ extended: true, limit: "16kb" }));

// Route imports
import beaconRouter from "./routes/beacon.router.js";

// Routes declaration
app.use("/api/v1/beacons", beaconRouter);

export default app;