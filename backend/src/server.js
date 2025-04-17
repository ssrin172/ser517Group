import dotenv from "dotenv";
import connectDB from "./db/index.js";
import app from "./app.js";

dotenv.config({ path: "./.env" });

connectDB()
  .then(() => {
    app.on("error", (err) => {
      console.log("%ERROR% :", err);
      throw err;
    });

    const PORT = process.env.PORT || 8000;
    app.listen(
      PORT,
      "0.0.0.0", // ← bind to all interfaces
      () => {
        console.log(`Server Listening on 0.0.0.0:${PORT}`);
      }
    );
  })
  .catch((err) => {
    console.log("%ERROR% in connection to MONGODB !!!:", err);
  });
