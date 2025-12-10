# frozen_string_literal: true

RSpec.shared_context 'for workhorse body uploads' do
  include WorkhorseHelpers
  include_context 'workhorse headers'

  let(:body_encoding) { :json }
  let(:method) { :post }

  def workhorse_body_upload(url, params)
    case body_encoding
    when :json
      perform_workhorse_json_body_upload(url, params.to_json)
    when :multipart_form
      perform_workhorse_multpart_form_encoding_body_upload(url, params)
    when :form
      perform_workhorse_form_encoding_body_upload(url, params)
    end
  end

  def perform_workhorse_json_body_upload(url, json_body, params: {})
    upload_path = 'public/uploads/tmp/body_uploader'
    file_name = 'file-payload.json'
    temp_file_path = "#{upload_path}/#{file_name}"

    FileUtils.mkdir_p(upload_path)

    File.write(temp_file_path, json_body)

    uploaded_file = UploadedFile.new(temp_file_path, filename: File.basename(temp_file_path))

    workhorse_finalize(
      url,
      method: method,
      file_key: :file,
      params: params.merge({ file: uploaded_file }),
      headers: workhorse_headers,
      send_rewritten_field: true
    )
  end

  def perform_workhorse_multpart_form_encoding_body_upload(url, params)
    boundary = 'XXX'
    content_type = "multipart/form-data; boundary=#{boundary}"

    body = form_encoding_body(params, boundary)
    perform_workhorse_json_body_upload(url, body, params: { 'Content-Type': content_type })
  end

  def perform_workhorse_form_encoding_body_upload(url, params)
    body = URI.encode_www_form(flatten_params(params))

    perform_workhorse_json_body_upload(url, body, params: { 'Content-Type': 'application/x-www-form-urlencoded' })
  end

  def form_encoding_body(params, boundary)
    body = []

    flatten_params(params).each do |key, value|
      body << "--#{boundary}\r\n"

      if value.is_a?(Tempfile)
        body << "Content-Disposition: form-data; name=\"#{key}\";"
        body << "filename=\"#{value.path}\"\r\n"
        body << "Content-Type: application/octet-stream\r\n\r\n#{value.read}\n\r\n"
      else
        body << "Content-Disposition: form-data; name=\"#{key}\"\r\n\r\n"
        body << value.to_s
        body << "\r\n"
      end
    end

    body << "--#{boundary}--\r\n"

    body.join
  end

  def flatten_params(params, prefix = nil)
    result = []

    params.each do |key, value|
      full_key = prefix ? "#{prefix}[#{key}]" : key.to_s

      if value.is_a?(Hash)
        result.concat(flatten_params(value, full_key))
      elsif value.is_a?(Array)
        value.each do |item|
          if item.is_a?(Hash)
            result.concat(flatten_params(item, "#{full_key}[]"))
          else
            result << ["#{full_key}[]", item]
          end
        end
      else
        result << [full_key, value]
      end
    end

    result
  end
end
