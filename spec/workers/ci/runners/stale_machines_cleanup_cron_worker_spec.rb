# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::Runners::StaleMachinesCleanupCronWorker, feature_category: :runner_fleet do
  let(:worker) { described_class.new }

  describe '#perform', :freeze_time do
    subject(:perform) { worker.perform }

    let!(:runner_machine1) do
      create(:ci_runner_machine, created_at: 7.days.ago, contacted_at: 7.days.ago)
    end

    let!(:runner_machine2) { create(:ci_runner_machine) }
    let!(:runner_machine3) { create(:ci_runner_machine, created_at: 6.days.ago) }

    it_behaves_like 'an idempotent worker' do
      it 'delegates to Ci::Runners::StaleMachinesCleanupService' do
        expect_next_instance_of(Ci::Runners::StaleMachinesCleanupService) do |service|
          expect(service)
            .to receive(:execute).and_call_original
        end

        perform

        expect(worker.logging_extras).to eq({
          "extra.ci_runners_stale_machines_cleanup_cron_worker.status" => :success,
          "extra.ci_runners_stale_machines_cleanup_cron_worker.deleted_machines" => true
        })
      end

      it 'cleans up stale runner machines', :aggregate_failures do
        expect(Ci::RunnerMachine.stale.count).to eq 1

        expect { perform }.to change { Ci::RunnerMachine.count }.from(3).to(2)

        expect(Ci::RunnerMachine.all).to match_array [runner_machine2, runner_machine3]
      end
    end
  end
end
