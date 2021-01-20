# frozen_string_literal: true

module MultipartHelpers
  include WorkhorseHelpers

  def post_env(rewritten_fields:, params:, secret:, issuer:)
    token = JWT.encode({ 'iss' => issuer, 'rewritten_fields' => rewritten_fields }, secret, 'HS256')
    Rack::MockRequest.env_for(
      '/',
      method: 'post',
      params: params,
      described_class::RACK_ENV_KEY => token
    )
  end

  def upload_parameters_for(filepath: nil, key: nil, mode: nil, filename: 'filename', remote_id: 'remote_id')
    result = {
      "name" => filename,
      "type" => "application/octet-stream",
      "sha256" => "1234567890"
    }

    case mode
    when :local
      result["path"] = filepath
    when :remote
      result["remote_id"] = remote_id
      result["size"] = 3.megabytes
    else
      raise ArgumentError, "can't handle #{mode} mode"
    end

    {
      "#{key}.gitlab-workhorse-upload" => jwt_token(data: { 'upload' => result })
    }
  end

  # This function assumes a `mode` variable to be set
  def rewritten_fields_hash(hash)
    if mode == :remote
      # For remote uploads, workhorse still submits rewritten_fields,
      # but all the values are empty strings.
      hash.keys.each { |k| hash[k] = '' }
    end

    hash
  end

  def expect_uploaded_files(uploaded_file_expectations)
    expect(app).to receive(:call) do |env|
      Array.wrap(uploaded_file_expectations).each do |expectation|
        file = get_params(env).dig(*expectation[:params_path])
        expect_uploaded_file(file, expectation)
      end
    end
  end

  # This function assumes a `mode` variable to be set
  def expect_uploaded_file(file, expectation)
    expect(file).to be_a(::UploadedFile)
    expect(file.original_filename).to eq(expectation[:original_filename])
    expect(file.sha256).to eq('1234567890')

    case mode
    when :local
      expect(file.path).to eq(File.realpath(expectation[:filepath]))
      expect(file.remote_id).to be_nil
      expect(file.size).to eq(expectation[:size])
    when :remote
      expect(file.remote_id).to eq(expectation[:remote_id])
      expect(file.path).to be_nil
      expect(file.size).to eq(3.megabytes)
    else
      raise ArgumentError, "can't handle #{mode} mode"
    end
  end

  # Rails doesn't combine the GET/POST parameters in
  # ActionDispatch::HTTP::Parameters if action_dispatch.request.parameters is set:
  # https://github.com/rails/rails/blob/aea6423f013ca48f7704c70deadf2cd6ac7d70a1/actionpack/lib/action_dispatch/http/parameters.rb#L41
  def get_params(env)
    req = ActionDispatch::Request.new(env)
    req.GET.merge(req.POST)
  end
end
