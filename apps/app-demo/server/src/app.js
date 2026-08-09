// app.js → express configuration
import express from 'express';
import BookRoutes from './routes/book.routes.js';
import { globalErrorHandler } from './middlewares/error.middleware.js';

const app = express();

// Middleware -> express.json() to parse json data. Must be registered before routes
app.use(express.json()); // parse JSON first

// Routes here
app.use('/api/v1/books', BookRoutes); // then use routes

// Global error middleware (must come after routes). Error middleware MUST be last.
// This registers the middleware with Express.
app.use(globalErrorHandler);

export default app;
