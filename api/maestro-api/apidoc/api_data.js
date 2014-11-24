define({ api: [
  {
    "type": "get",
    "url": "/api/v1.0/ping",
    "title": "",
    "version": "1.0.0",
    "description": "<p>Returns a health status of the endpoint.</p>",
    "success": {
      "examples": [
        {
          "title": "Success-Response:",
          "content": "   HTTP/1.1 200 OK\n   {\n     \"ping\": \"pong\"\n   }\n",
          "type": "json"
        }
      ]
    },
    "group": "index_js",
    "filename": "middleware/v1.0/health/index.js"
  },
  {
    "type": "get",
    "url": "/api/v1.0/metric/:host/:metric",
    "title": "",
    "version": "1.0.0",
    "parameter": {
      "fields": {
        "Parameter": [
          {
            "group": "Parameter",
            "type": "String",
            "field": "host",
            "optional": false,
            "description": "<p>Name of the host</p>"
          },
          {
            "group": "Parameter",
            "type": "String",
            "field": "metric",
            "optional": false,
            "description": "<p>Name of the metric</p>"
          }
        ]
      }
    },
    "description": "<p>Returns a health status of the endpoint.</p>",
    "success": {
      "examples": [
        {
          "title": "Success-Response:",
          "content": "   HTTP/1.1 200 OK\n   {\n     \"metric\": \"20\"\n   }\n",
          "type": "json"
        }
      ]
    },
    "group": "index_js",
    "filename": "middleware/v1.0/monitor/index.js"
  }
] });