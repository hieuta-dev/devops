exports.handler = (event, context, callback) => {
  const path = event.rawPath || event.path;

  if (path === "/name") {
    return callback(null, {statusCode: 200, body: "Hieu"});
  }

  callback(null, {statusCode: 200, body: "Hello, World!"});
};