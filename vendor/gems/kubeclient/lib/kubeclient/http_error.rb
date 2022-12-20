# TODO: remove this on next major version bump
# Deprected http exception
class KubeException < StandardError
  attr_reader :error_code, :message, :response

  def initialize(error_code, message, response)
    @error_code = error_code
    @message = message
    @response = response
  end

  def to_s
    string = "HTTP status code #{@error_code}, #{@message}"
    if @response.is_a?(RestClient::Response) && @response.request
      string << " for #{@response.request.method.upcase} #{@response.request.url}"
    end
    string
  end
end

module Kubeclient
  # Exception that is raised when a http request fails
  class HttpError < KubeException
  end
end
