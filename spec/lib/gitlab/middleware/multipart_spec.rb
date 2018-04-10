require 'spec_helper'

require 'tempfile'

describe Gitlab::Middleware::Multipart do
  let(:app) { double(:app) }
  let(:middleware) { described_class.new(app) }
  let(:original_filename) { 'filename' }

  it 'opens top-level files' do
    Tempfile.open('top-level') do |tempfile|
      env = post_env({ 'file' => tempfile.path }, { 'file.name' => original_filename }, Gitlab::Workhorse.secret, 'gitlab-workhorse')

      expect(app).to receive(:call) do |env|
        file = Rack::Request.new(env).params['file']
        expect(file).to be_a(::UploadedFile)
        expect(file.path).to eq(tempfile.path)
        expect(file.original_filename).to eq(original_filename)
      end

      middleware.call(env)
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

  it 'opens files one level deep' do
    Tempfile.open('one-level') do |tempfile|
      in_params = { 'user' => { 'avatar' => { '.name' => original_filename } } }
      env = post_env({ 'user[avatar]' => tempfile.path }, in_params, Gitlab::Workhorse.secret, 'gitlab-workhorse')

      expect(app).to receive(:call) do |env|
        file = Rack::Request.new(env).params['user']['avatar']
        expect(file).to be_a(::UploadedFile)
        expect(file.path).to eq(tempfile.path)
        expect(file.original_filename).to eq(original_filename)
      end

      middleware.call(env)
    end
  end

  it 'opens files two levels deep' do
    Tempfile.open('two-levels') do |tempfile|
      in_params = { 'project' => { 'milestone' => { 'themesong' => { '.name' => original_filename } } } }
      env = post_env({ 'project[milestone][themesong]' => tempfile.path }, in_params, Gitlab::Workhorse.secret, 'gitlab-workhorse')

      expect(app).to receive(:call) do |env|
        file = Rack::Request.new(env).params['project']['milestone']['themesong']
        expect(file).to be_a(::UploadedFile)
        expect(file.path).to eq(tempfile.path)
        expect(file.original_filename).to eq(original_filename)
      end

      middleware.call(env)
    end
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
