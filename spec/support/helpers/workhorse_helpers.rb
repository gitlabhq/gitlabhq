# frozen_string_literal: true

module WorkhorseHelpers
  extend self

  def workhorse_send_data
    @_workhorse_send_data ||= begin
      header = response.headers[Gitlab::Workhorse::SEND_DATA_HEADER]
      split_header = header.split(':')
      type = split_header.shift
      header = split_header.join(':')
      [
        type,
        JSON.parse(Base64.urlsafe_decode64(header))
      ]
    end
  end

  def workhorse_internal_api_request_header
    { 'HTTP_' + Gitlab::Workhorse::INTERNAL_API_REQUEST_HEADER.upcase.tr('-', '_') => jwt_token }
  end

  # workhorse_post_with_file will transform file_key inside params as if it was disk accelerated by workhorse
  def workhorse_post_with_file(url, file_key:, params:)
    workhorse_params = params.dup
    file = workhorse_params.delete(file_key)

    workhorse_params.merge!(workhorse_disk_accelerated_file_params(file_key, file))

    post(url,
         params: workhorse_params,
         headers: workhorse_rewritten_fields_header('file' => file.path)
        )
  end

  private

  def jwt_token(data = {})
    JWT.encode({ 'iss' => 'gitlab-workhorse' }.merge(data), Gitlab::Workhorse.secret, 'HS256')
  end

  def workhorse_rewritten_fields_header(fields)
    { Gitlab::Middleware::Multipart::RACK_ENV_KEY => jwt_token('rewritten_fields' => fields) }
  end

  def workhorse_disk_accelerated_file_params(key, file)
    {
      "#{key}.name" => file.original_filename,
      "#{key}.path" => file.path
    }
  end
end
