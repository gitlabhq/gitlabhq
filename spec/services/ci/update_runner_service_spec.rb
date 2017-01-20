require 'spec_helper'

describe Ci::UpdateRunnerService, services: true do
  let(:runner) { create(:ci_runner) }

  describe '#update' do
    before do
      allow(runner).to receive(:tick_runner_queue)

      described_class.new(runner).update(description: 'new runner')
    end

    it 'updates the runner and ticking the queue' do
      expect(runner.description).to eq('new runner')
      expect(runner).to have_received(:tick_runner_queue)
    end
  end
end
