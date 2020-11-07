# frozen_string_literal: true

require 'spec_helper'
require "rack/test"

RSpec.describe Gitlab::Middleware::HandleMalformedStrings do
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
        env = env_for(name: [
          {
            inner_key: "I am #{problematic_input} bad"
          }
        ])

        expect(subject.call(env)).to eq error_400
      end

      it "gives up and does not reject too deeply nested params" do
        env = env_for(name: [
          {
            inner_key: { deeper_key: [{ hash_inside_array_key: "I am #{problematic_input} bad" }] }
          }
        ])

        expect(subject.call(env)).not_to eq error_400
      end
    end

    context 'with null byte' do
      it_behaves_like 'checks params' do
        let(:problematic_input) { null_byte }
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
end
