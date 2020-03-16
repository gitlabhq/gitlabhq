# frozen_string_literal: true

RSpec.shared_context 'multipart middleware context' do
  let(:app) { double(:app) }
  let(:middleware) { described_class.new(app) }
  let(:original_filename) { 'filename' }

  # Rails 5 doesn't combine the GET/POST parameters in
  # ActionDispatch::HTTP::Parameters if action_dispatch.request.parameters is set:
  # https://github.com/rails/rails/blob/aea6423f013ca48f7704c70deadf2cd6ac7d70a1/actionpack/lib/action_dispatch/http/parameters.rb#L41
  def get_params(env)
    req = ActionDispatch::Request.new(env)
    req.GET.merge(req.POST)
  end

  def post_env(rewritten_fields, params, secret, issuer)
    token = JWT.encode({ 'iss' => issuer, 'rewritten_fields' => rewritten_fields }, secret, 'HS256')
    Rack::MockRequest.env_for(
      '/',
      method: 'post',
      params: params,
      described_class::RACK_ENV_KEY => token
    )
  end

  def with_tmp_dir(uploads_sub_dir, storage_path = '')
    Dir.mktmpdir do |dir|
      upload_dir = File.join(dir, storage_path, uploads_sub_dir)
      FileUtils.mkdir_p(upload_dir)

      allow(Rails).to receive(:root).and_return(dir)
      allow(Dir).to receive(:tmpdir).and_return(File.join(Dir.tmpdir, 'tmpsubdir'))
      allow(GitlabUploader).to receive(:root).and_return(File.join(dir, storage_path))

      Tempfile.open('top-level', upload_dir) do |tempfile|
        env = post_env({ 'file' => tempfile.path }, { 'file.name' => original_filename, 'file.path' => tempfile.path }, Gitlab::Workhorse.secret, 'gitlab-workhorse')

        yield dir, env
      end
    end
  end
end
