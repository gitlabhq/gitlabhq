require 'spec_helper'

describe Gitlab::Middleware::ReleaseEnv do
  let(:inner_app) { double(:app) }
  let(:app) { described_class.new(inner_app) }
  let(:env) { { 'action_controller.instance' => 'something' } }

  before do
    expect(inner_app).to receive(:call).with(env).and_return('yay')
  end

  describe '#call' do
    it 'calls the app and delete the controller' do
      result = app.call(env)

      expect(result).to eq('yay')
      expect(env).to be_empty
    end
  end
end
