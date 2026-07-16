// server.js → entry point
import dotenv from 'dotenv';
import app from './app.js';
import connectToDb from './config/db.js';

dotenv.config();

const PORT = process.env.PORT || 5000;

// Connect database
connectToDb();

app.listen(PORT, () => {
  console.log(`🚀 Server is running on http://localhost:${PORT}`);
});
