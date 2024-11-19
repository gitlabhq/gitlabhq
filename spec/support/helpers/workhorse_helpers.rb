# frozen_string_literal: true

module WorkhorseHelpers
  extend self

  UPLOAD_PARAM_NAMES = %w[name size path remote_id sha256 sha1 md5 type].freeze

  def workhorse_send_data
    @_workhorse_send_data ||= begin
      header = response.headers[Gitlab::Workhorse::SEND_DATA_HEADER]
      split_header = header.split(':')
      type = split_header.shift
      header = split_header.join(':')
      [
        type,
        Gitlab::Json.parse(Base64.urlsafe_decode64(header))
      ]
    end
  end

  def workhorse_internal_api_request_header
    { 'HTTP_' + Gitlab::Workhorse::INTERNAL_API_REQUEST_HEADER.upcase.tr('-', '_') => jwt_token }
  end

  # workhorse_post_with_file will transform file_key inside params as if it was disk accelerated by workhorse
  def workhorse_post_with_file(url, file_key:, params:)
    workhorse_form_with_file(url, method: :post, file_key: file_key, params: params)
  end

  # workhorse_form_with_file will transform file_key inside params as if it was disk accelerated by workhorse
  def workhorse_form_with_file(url, file_key:, params:, method: :post)
    workhorse_request_with_file(
      method, url,
      file_key: file_key,
      params: params,
      env: { 'CONTENT_TYPE' => 'multipart/form-data' },
      send_rewritten_field: true
    )
  end

  # workhorse_finalize will transform file_key inside params as if it was the finalize call of an inline object storage upload.
  # note that based on the content of the params it can simulate a disc acceleration or an object storage upload
  def workhorse_finalize(url, file_key:, params:, method: :post, headers: {}, send_rewritten_field: false)
    workhorse_finalize_with_multiple_files(
      url,
      method: method,
      file_keys: file_key,
      params: params,
      headers: headers,
      send_rewritten_field: send_rewritten_field
    )
  end

  def workhorse_finalize_with_multiple_files(url, file_keys:, params:, method: :post, headers: {}, send_rewritten_field: false)
    workhorse_request_with_multiple_files(
      method, url,
      file_keys: file_keys,
      params: params,
      extra_headers: headers,
      send_rewritten_field: send_rewritten_field
    )
  end

  def workhorse_request_with_file(method, url, file_key:, params:, send_rewritten_field:, env: {}, extra_headers: {})
    workhorse_request_with_multiple_files(
      method,
      url,
      file_keys: file_key,
      params: params,
      env: env,
      extra_headers: extra_headers,
      send_rewritten_field: send_rewritten_field
    )
  end

  def workhorse_request_with_multiple_files(method, url, file_keys:, params:, send_rewritten_field:, env: {}, extra_headers: {})
    workhorse_params = params.dup

    file_keys = Array(file_keys)
    rewritten_fields = {}

    file_keys.each do |key|
      file = workhorse_params.delete(key)
      rewritten_fields[key] = file.path if file
      workhorse_params = workhorse_disk_accelerated_file_params(key, file).merge(workhorse_params)
      workhorse_params = workhorse_params.merge(jwt_file_upload_param(key: key, params: workhorse_params))
    end

    headers = if send_rewritten_field
                workhorse_rewritten_fields_header(rewritten_fields)
              else
                {}
              end

    headers.merge!(extra_headers)

    process(method, url, params: workhorse_params, headers: headers, env: env)
  end

  private

  def jwt_file_upload_param(key:, params:)
    upload_params = UPLOAD_PARAM_NAMES.map do |file_upload_param|
      [file_upload_param, params["#{key}.#{file_upload_param}"]]
    end
    upload_params = upload_params.to_h.compact

    return {} if upload_params.empty?

    { "#{key}.gitlab-workhorse-upload" => jwt_token(data: { 'upload' => upload_params }) }
  end

  def jwt_token(data: {}, issuer: 'gitlab-workhorse', secret: Gitlab::Workhorse.secret, algorithm: 'HS256')
    JWT.encode({ 'iss' => issuer }.merge(data), secret, algorithm)
  end

  def workhorse_rewritten_fields_header(fields)
    { Gitlab::Middleware::Multipart::RACK_ENV_KEY => jwt_token(data: { 'rewritten_fields' => fields }) }
  end

  def workhorse_disk_accelerated_file_params(key, file)
    return {} unless file

    {
      "#{key}.name" => file.original_filename,
      "#{key}.size" => file.size
    }.tap do |params|
      if file.path
        params["#{key}.path"] = file.path
        params["#{key}.sha256"] = Digest::SHA256.file(file.path).hexdigest
      end

      params["#{key}.remote_id"] = file.remote_id if file.respond_to?(:remote_id) && file.remote_id.present?
      params["#{key}.sha256"] = file.sha256 if file.respond_to?(:sha256) && file.sha256.present?
    end
  end

  def fog_to_uploaded_file(file, filename: nil, sha256: nil, remote_id: nil)
    filename ||= File.basename(file.key)

    UploadedFile.new(
      nil,
      filename: filename,
      remote_id: remote_id || filename,
      size: file.content_length,
      sha256: sha256
    )
  end
end
