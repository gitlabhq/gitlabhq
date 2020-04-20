# frozen_string_literal: true

require 'spec_helper'

describe Ci::UpdateRunnerService do
  let(:runner) { create(:ci_runner) }

  describe '#update' do
    before do
      allow(runner).to receive(:tick_runner_queue)
    end

    context 'with description params' do
      let(:params) { { description: 'new runner' } }

      it 'updates the runner and ticking the queue' do
        expect(update).to be_truthy

        runner.reload

        expect(runner).to have_received(:tick_runner_queue)
        expect(runner.description).to eq('new runner')
      end
    end

    context 'with cost factor params' do
      let(:params) { { public_projects_minutes_cost_factor: 1.1, private_projects_minutes_cost_factor: 2.2 }}

      it 'updates the runner cost factors' do
        expect(update).to be_truthy

        runner.reload

        expect(runner.public_projects_minutes_cost_factor).to eq(1.1)
        expect(runner.private_projects_minutes_cost_factor).to eq(2.2)
      end
    end

    context 'when params are not valid' do
      let(:params) { { run_untagged: false } }

      it 'does not update and give false because it is not valid' do
        expect(update).to be_falsey

        runner.reload

        expect(runner).not_to have_received(:tick_runner_queue)
        expect(runner.run_untagged).to be_truthy
      end
    end

    def update
      described_class.new(runner).update(params)
    end
  end
end
