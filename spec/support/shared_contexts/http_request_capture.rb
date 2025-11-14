# frozen_string_literal: true

RSpec.shared_context 'with http requests' do
  let(:http_requests) { [] }

  # Capture request details by overriding the request methods
  def get(path, **options)
    capture_request_details('GET', path, options)
    super
  end

  def post(path, **options)
    capture_request_details('POST', path, options)
    super
  end

  def put(path, **options)
    capture_request_details('PUT', path, options)
    super
  end

  def patch(path, **options)
    capture_request_details('PATCH', path, options)
    super
  end

  def delete(path, **options)
    capture_request_details('DELETE', path, options)
    super
  end

  def head(path, **options)
    capture_request_details('HEAD', path, options)
    super
  end

  private

  def capture_request_details(method, path, options)
    params = options[:params] || {}
    headers = options[:headers] || {}
    content_type = headers['CONTENT_TYPE'] || headers['Content-Type']

    # Set query params for GET requests
    query_params = method == 'GET' && params.present? ? params : {}

    # Add request hash to the array
    http_requests << {
      method: method,
      path: path,
      params: params,
      headers: headers,
      query_params: query_params,
      content_type: content_type
    }
  end
end

RSpec.shared_context 'with last http request' do
  include_context 'with http requests'

  let(:last_request_params) { http_requests.last&.dig(:params) || {} }
  let(:last_request_headers) { http_requests.last&.dig(:headers) || {} }
  let(:last_request_method) { http_requests.last&.dig(:method) }
  let(:last_request_path) { http_requests.last&.dig(:path) }
  let(:last_request_query_params) { http_requests.last&.dig(:query_params) || {} }
  let(:last_request_content_type) { http_requests.last&.dig(:content_type) }
end
