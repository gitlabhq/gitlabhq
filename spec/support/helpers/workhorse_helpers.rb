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
    workhorse_request_with_file(:post, url,
                                file_key: file_key,
                                params: params,
                                env: { 'CONTENT_TYPE' => 'multipart/form-data' },
                                send_rewritten_field: true
    )
  end

  # workhorse_finalize will transform file_key inside params as if it was the finalize call of an inline object storage upload.
  # note that based on the content of the params it can simulate a disc acceleration or an object storage upload
  def workhorse_finalize(url, method: :post, file_key:, params:, headers: {})
    workhorse_request_with_file(method, url,
                                file_key: file_key,
                                params: params,
                                extra_headers: headers,
                                send_rewritten_field: false
    )
  end

  def workhorse_request_with_file(method, url, file_key:, params:, env: {}, extra_headers: {}, send_rewritten_field:)
    workhorse_params = params.dup
    file = workhorse_params.delete(file_key)

    workhorse_params = workhorse_disk_accelerated_file_params(file_key, file).merge(workhorse_params)

    headers = if send_rewritten_field
                workhorse_rewritten_fields_header(file_key => file.path)
              else
                {}
              end

    headers.merge!(extra_headers)

    process(method, url, params: workhorse_params, headers: headers, env: env)
  end

  private

  def jwt_token(data = {})
    JWT.encode({ 'iss' => 'gitlab-workhorse' }.merge(data), Gitlab::Workhorse.secret, 'HS256')
  end

  def workhorse_rewritten_fields_header(fields)
    { Gitlab::Middleware::Multipart::RACK_ENV_KEY => jwt_token('rewritten_fields' => fields) }
  end

  def workhorse_disk_accelerated_file_params(key, file)
    return {} unless file

    {
      "#{key}.name" => file.original_filename,
      "#{key}.size" => file.size
    }.tap do |params|
      params["#{key}.path"] = file.path if file.path
      params["#{key}.remote_id"] = file.remote_id if file.respond_to?(:remote_id) && file.remote_id
    end
  end

  def fog_to_uploaded_file(file)
    filename = File.basename(file.key)

    UploadedFile.new(nil,
                     filename: filename,
                     remote_id: filename,
                     size: file.content_length
                    )
  end
end
