# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Gitlab::Middleware::ReleaseEnv do
  let(:inner_app) { double(:app, call: 'yay') }
  let(:app) { described_class.new(inner_app) }
  let(:env) { { 'action_controller.instance' => 'something' } }

  describe '#call' do
    it 'calls the app and clears the env' do
      result = app.call(env)

      expect(result).to eq('yay')
      expect(env).to be_empty
    end
  end
end
