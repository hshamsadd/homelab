// meta can be used for pagination info, counts, or other extra info
// Keeps the controller ultra-thin and consistent
export const sendResponse = (
  res,
  data = null,
  message = 'Success',
  statusCode = 200,
  meta = {},
) => {
  res.status(statusCode).json({
    success: true,
    message,
    data,
    ...(Object.keys(meta).length ? { meta } : {}), // include meta only if provided // should only include business-level info, like totals, pagination, or other aggregates
    timestamp: new Date().toISOString(), // API response timestamp
  });
};

// meta is optional (for pagination, counts, etc.)
// If meta is empty, it won’t appear in the response
