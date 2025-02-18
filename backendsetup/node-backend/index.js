const express = require("express");
const cors = require("cors");
const dotenv = require("dotenv");

dotenv.config();

const app = express();
app.use(cors()); // Enable CORS for Flutter
app.use(express.json()); // Parse incoming JSON requests

const PORT = process.env.PORT || 8080;

app.get("/", (req, res) => {
    res.send("Backend code is Running!");
});

// Start Server
app.listen(PORT, () => {
    console.log(`Server is running on http://localhost:${PORT}`);
});
