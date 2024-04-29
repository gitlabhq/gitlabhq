# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::Runners::UpdateRunnerService, '#execute', feature_category: :runner do
  subject(:execute) { described_class.new(runner).execute(params) }

  let(:runner) { create(:ci_runner) }

  before do
    allow(runner).to receive(:tick_runner_queue)
  end

  context 'with description params' do
    let(:params) { { description: 'new runner' } }

    it 'updates the runner and ticking the queue' do
      expect(execute).to be_success

      runner.reload

      expect(runner).to have_received(:tick_runner_queue)
      expect(runner.description).to eq('new runner')
    end
  end

  context 'with paused param' do
    let(:params) { { paused: true } }

    it 'updates the runner and ticking the queue' do
      expect(runner.active).to be_truthy
      expect(execute).to be_success

      runner.reload

      expect(runner).to have_received(:tick_runner_queue)
      expect(runner.active).to be_falsey
    end
  end

  context 'with cost factor params' do
    let(:params) { { public_projects_minutes_cost_factor: 1.1, private_projects_minutes_cost_factor: 2.2 } }

    it 'updates the runner cost factors' do
      expect(execute).to be_success

      runner.reload

      expect(runner.public_projects_minutes_cost_factor).to eq(1.1)
      expect(runner.private_projects_minutes_cost_factor).to eq(2.2)
    end
  end

  context 'when params are not valid' do
    let(:params) { { run_untagged: false } }

    it 'does not update and returns error because it is not valid' do
      expect(execute).to be_error

      runner.reload

      expect(runner).not_to have_received(:tick_runner_queue)
      expect(runner.run_untagged).to be_truthy
    end
  end
end
