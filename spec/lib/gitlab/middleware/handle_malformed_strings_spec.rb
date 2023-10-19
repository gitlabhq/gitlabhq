# frozen_string_literal: true
require 'spec_helper'
require "rack/test"

RSpec.describe Gitlab::Middleware::HandleMalformedStrings do
  include GitHttpHelpers

  let(:null_byte) { "\u0000" }
  let(:escaped_null_byte) { "%00" }
  let(:invalid_string) { "mal\xC0formed" }
  let(:escaped_invalid_string) { "mal%c0formed" }
  let(:error_400) { [400, { 'Content-Type' => 'text/plain' }, ['Bad Request']] }
  let(:app) { double(:app) }

  subject { described_class.new(app) }

  before do
    allow(app).to receive(:call) do |args|
      args
    end
  end

  def env_for(params = {})
    Rack::MockRequest.env_for('/', { params: params })
  end

  context 'in the URL' do
    it 'rejects null bytes' do
      # We have to create the env separately or Rack::MockRequest complains about invalid URI
      env = env_for
      env['PATH_INFO'] = "/someplace/witha#{null_byte}nullbyte"

      expect(subject.call(env)).to eq error_400
    end

    it 'rejects escaped null bytes' do
      # We have to create the env separately or Rack::MockRequest complains about invalid URI
      env = env_for
      env['PATH_INFO'] = "/someplace/withan#{escaped_null_byte}escaped nullbyte"

      expect(subject.call(env)).to eq error_400
    end

    it 'rejects malformed strings' do
      # We have to create the env separately or Rack::MockRequest complains about invalid URI
      env = env_for
      env['PATH_INFO'] = "/someplace/with_an/#{invalid_string}"

      expect(subject.call(env)).to eq error_400
    end

    it 'rejects escaped malformed strings' do
      # We have to create the env separately or Rack::MockRequest complains about invalid URI
      env = env_for
      env['PATH_INFO'] = "/someplace/with_an/#{escaped_invalid_string}"

      expect(subject.call(env)).to eq error_400
    end
  end

  context 'with POST request' do
    let(:request_env) do
      Rack::MockRequest.env_for(
        '/',
        method: 'POST',
        input: input,
        'CONTENT_TYPE' => 'application/json'
      )
    end

    let(:params) { { method: 'POST' } }

    context 'with valid JSON' do
      let(:input) { %({"hello": "world"}) }

      it 'returns no error' do
        env = request_env

        expect(subject.call(env)).not_to eq error_400
      end
    end

    context 'with bad JSON' do
      let(:input) { "{ bad json }" }

      it 'rejects bad JSON with 400 error' do
        env = request_env

        expect(subject.call(env)).to eq error_400
      end
    end
  end

  context 'in authorization headers' do
    let(:problematic_input) { null_byte }

    shared_examples 'rejecting invalid input' do
      it 'rejects problematic input in the password' do
        env = env_for.merge(auth_env("username", "password#{problematic_input}encoded", nil))

        expect(subject.call(env)).to eq error_400
      end

      it 'rejects problematic input in the username' do
        env = env_for.merge(auth_env("username#{problematic_input}", "passwordencoded", nil))

        expect(subject.call(env)).to eq error_400
      end

      it 'rejects problematic input in non-basic-auth tokens' do
        env = env_for.merge('HTTP_AUTHORIZATION' => "GL-Geo hello#{problematic_input}world")

        expect(subject.call(env)).to eq error_400
      end
    end

    it_behaves_like 'rejecting invalid input' do
      let(:problematic_input) { null_byte }
    end

    it_behaves_like 'rejecting invalid input' do
      let(:problematic_input) { invalid_string }
    end

    it_behaves_like 'rejecting invalid input' do
      let(:problematic_input) { "\xC3" }
    end

    it 'does not reject correct non-basic-auth tokens' do
      # This token is known to include a null-byte when we were to try to decode it
      # as Base64, while it wasn't encoded at such.
      special_token = 'GL-Geo ta8KakZWpu0AcledQ6n0:eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJkYXRhIjoie1wic2NvcGVcIjpcImdlb19hcGlcIn0iLCJqdGkiOiIwYWFmNzVlYi1lNWRkLTRkZjEtODQzYi1lM2E5ODhhNDMwMzIiLCJpYXQiOjE2MDQ3MDI4NzUsIm5iZiI6MTYwNDcwMjg3MCwiZXhwIjoxNjA0NzAyOTM1fQ.NcgDipDyxSP5uSzxc01ylzH4GkTxJRflNNjT7U6fpg4'
      expect(Base64.decode64(special_token)).to include(null_byte)

      env = env_for.merge('HTTP_AUTHORIZATION' => special_token)

      expect(subject.call(env)).not_to eq error_400
    end

    it 'does not reject correct encoded password with special characters' do
      env = env_for.merge(auth_env("username", "RçKszEwéC5kFnû∆f243fycGu§Gh9ftDj!U", nil))

      expect(subject.call(env)).not_to eq error_400
    end
  end

  context 'in params' do
    shared_examples_for 'checks params' do
      it 'rejects bad params in a top level param' do
        env = env_for(name: "null#{problematic_input}byte")

        expect(subject.call(env)).to eq error_400
      end

      it "rejects bad params for hashes with strings" do
        env = env_for(name: { inner_key: "I am #{problematic_input} bad" })

        expect(subject.call(env)).to eq error_400
      end

      it "rejects bad params for arrays with strings" do
        env = env_for(name: ["I am #{problematic_input} bad"])

        expect(subject.call(env)).to eq error_400
      end

      it "rejects bad params for arrays containing hashes with string values" do
        env = env_for(
          name: [
            {
              inner_key: "I am #{problematic_input} bad"
            }
          ])

        expect(subject.call(env)).to eq error_400
      end
    end

    context 'with null byte' do
      let(:problematic_input) { null_byte }

      it_behaves_like 'checks params'

      it "gives up and does not reject too deeply nested params" do
        env = env_for(
          name: [
            {
              inner_key: { deeper_key: [{ hash_inside_array_key: "I am #{problematic_input} bad" }] }
            }
          ])

        expect(subject.call(env)).not_to eq error_400
      end
    end

    context 'with malformed strings' do
      it_behaves_like 'checks params' do
        let(:problematic_input) { invalid_string }
      end
    end
  end

  context 'without problematic input' do
    it "does not error for strings" do
      env = env_for(name: "safe name")

      expect(subject.call(env)).not_to eq error_400
    end

    it "does not error with no params" do
      env = env_for

      expect(subject.call(env)).not_to eq error_400
    end
  end

  it 'does not modify the env' do
    env = env_for

    expect { subject.call(env) }.not_to change { env }
  end
end
