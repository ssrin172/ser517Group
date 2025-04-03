import express from 'express';
import cors from 'cors';
// import cookieParser from 'cookie-parser';

const app = express();

// configuring cors
app.use(cors({
    origin: process.env.CORS_ORIGIN || '*',
    credentials: true,
}));

// middlewares
app.use(express.json({ limit: "16kb" }));
app.use(express.urlencoded({ extended: true, limit: "16kb" }));
// app.use(express.static("public"));
// app.use(cookieParser());

// Route imports
import beaconRouter from "./routes/beacon.router.js";

// Routes declaration
app.use("/api/v1/beacons", beaconRouter); // Middleware (It means which route and what route to activate)


export default app;