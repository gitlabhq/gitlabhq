def api_prefix
  "/api/#{Gitlab::API::VERSION}"
end

def json_response
  JSON.parse(response.body)
end
