require 'spec_helper'

require 'tempfile'

describe Gitlab::Middleware::Multipart do
  let(:app) { double(:app) }
  let(:middleware) { described_class.new(app) }
  let(:original_filename) { 'filename' }

  shared_examples_for 'multipart upload files' do
    it 'opens top-level files' do
      Tempfile.open('top-level') do |tempfile|
        env = post_env({ 'file' => tempfile.path }, { 'file.name' => original_filename, 'file.path' => tempfile.path, 'file.remote_id' => remote_id }, Gitlab::Workhorse.secret, 'gitlab-workhorse')

        expect_uploaded_file(tempfile, %w(file))

        middleware.call(env)
      end
    end

    it 'opens files one level deep' do
      Tempfile.open('one-level') do |tempfile|
        in_params = { 'user' => { 'avatar' => { '.name' => original_filename, '.path' => tempfile.path, '.remote_id' => remote_id } } }
        env = post_env({ 'user[avatar]' => tempfile.path }, in_params, Gitlab::Workhorse.secret, 'gitlab-workhorse')

        expect_uploaded_file(tempfile, %w(user avatar))

        middleware.call(env)
      end
    end

    it 'opens files two levels deep' do
      Tempfile.open('two-levels') do |tempfile|
        in_params = { 'project' => { 'milestone' => { 'themesong' => { '.name' => original_filename, '.path' => tempfile.path, '.remote_id' => remote_id } } } }
        env = post_env({ 'project[milestone][themesong]' => tempfile.path }, in_params, Gitlab::Workhorse.secret, 'gitlab-workhorse')

        expect_uploaded_file(tempfile, %w(project milestone themesong))

        middleware.call(env)
      end
    end

    def expect_uploaded_file(tempfile, path, remote: false)
      expect(app).to receive(:call) do |env|
        file = Rack::Request.new(env).params.dig(*path)
        expect(file).to be_a(::UploadedFile)
        expect(file.path).to eq(tempfile.path)
        expect(file.original_filename).to eq(original_filename)
        expect(file.remote_id).to eq(remote_id)
      end
    end
  end

  it 'rejects headers signed with the wrong secret' do
    env = post_env({ 'file' => '/var/empty/nonesuch' }, {}, 'x' * 32, 'gitlab-workhorse')

    expect { middleware.call(env) }.to raise_error(JWT::VerificationError)
  end

  it 'rejects headers signed with the wrong issuer' do
    env = post_env({ 'file' => '/var/empty/nonesuch' }, {}, Gitlab::Workhorse.secret, 'acme-inc')

    expect { middleware.call(env) }.to raise_error(JWT::InvalidIssuerError)
  end

  context 'with remote file' do
    let(:remote_id) { 'someid' }

    it_behaves_like 'multipart upload files'
  end

  context 'with local file' do
    let(:remote_id) { nil }

    it_behaves_like 'multipart upload files'
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
end
