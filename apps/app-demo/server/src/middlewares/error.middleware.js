// This middleware catches all errors and sends a consistent JSON response:
export const globalErrorHandler = (err, _req, res, _next) => {
  // Because of the err parameter first, Express treats it as an error middleware.
  console.error(err); // optional: log error
  const statusCode = err.statusCode || 500;

  res.status(statusCode).json({
    success: false,
    message: err.message || 'Internal Server Error',
    timestamp: new Date().toISOString(),
    ...(process.env.NODE_ENV === 'development' && { stack: err.stack }),
  });
};
