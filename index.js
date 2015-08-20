var hapi = require('hapi');

module.exports = (function (server) {
	server.connection({
		host : process.env.NODE_HOST || '127.0.0.1',
		port : process.env.NODE_PORT || 8000
	});

	server.route({
		config : {
			json : {
				space : 2
			}
		},
		method : 'GET',
		path : '/',
		handler : function (request, reply) {
			return reply(request.headers).code(200);
		}
	});

	server.start(function () {
		console.log('server running at %s', server.info.uri);
	});

}(new hapi.Server()));
