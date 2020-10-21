# frozen_string_literal: true

require 'spec_helper'
require "rack/test"

RSpec.describe Gitlab::Middleware::HandleNullBytes do
  let(:null_byte) { "\u0000" }
  let(:error_400) { [400, {}, ["Bad Request"]] }
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

  context 'with null bytes in params' do
    it 'rejects null bytes in a top level param' do
      env = env_for(name: "null#{null_byte}byte")

      expect(subject.call(env)).to eq error_400
    end

    it "responds with 400 BadRequest for hashes with strings" do
      env = env_for(name: { inner_key: "I am #{null_byte} bad" })

      expect(subject.call(env)).to eq error_400
    end

    it "responds with 400 BadRequest for arrays with strings" do
      env = env_for(name: ["I am #{null_byte} bad"])

      expect(subject.call(env)).to eq error_400
    end

    it "responds with 400 BadRequest for arrays containing hashes with string values" do
      env = env_for(name: [
        {
          inner_key: "I am #{null_byte} bad"
        }
      ])

      expect(subject.call(env)).to eq error_400
    end

    it "gives up and does not 400 with too deeply nested params" do
      env = env_for(name: [
        {
          inner_key: { deeper_key: [{ hash_inside_array_key: "I am #{null_byte} bad" }] }
        }
      ])

      expect(subject.call(env)).not_to eq error_400
    end
  end

  context 'without null bytes in params' do
    it "does not respond with a 400 for strings" do
      env = env_for(name: "safe name")

      expect(subject.call(env)).not_to eq error_400
    end

    it "does not respond with a 400 with no params" do
      env = env_for

      expect(subject.call(env)).not_to eq error_400
    end
  end

  context 'when disabled via env flag' do
    before do
      stub_env('REJECT_NULL_BYTES', '1')
    end

    it 'does not respond with a 400 no matter what' do
      env = env_for(name: "null#{null_byte}byte")

      expect(subject.call(env)).not_to eq error_400
    end
  end
end
