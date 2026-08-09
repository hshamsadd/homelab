export class ApiError extends Error {
  constructor(statusCode, message) {
    super(message);
    this.statusCode = statusCode;
    this.isOperational = true; // for distinguishing expected errors vs bugs
    Error.captureStackTrace(this, this.constructor);
  }
}
