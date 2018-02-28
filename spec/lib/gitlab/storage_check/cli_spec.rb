require 'spec_helper'

describe Gitlab::StorageCheck::CLI do
  let(:options) { Gitlab::StorageCheck::Options.new('unix://tmp/socket.sock', nil, 1, false) }
  subject(:runner) { described_class.new(options) }

  describe '#update_settings' do
    it 'updates the interval when changed in a valid response and logs the change' do
      fake_response = double
      expect(fake_response).to receive(:valid?).and_return(true)
      expect(fake_response).to receive(:check_interval).and_return(42)
      expect(runner.logger).to receive(:info)

      runner.update_settings(fake_response)

      expect(options.interval).to eq(42)
    end
  end
end
