# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AuthorizedProjectUpdate::PeriodicRecalculateWorker, feature_category: :permissions do
  subject(:execute_worker) { described_class.new.perform }

  describe '#perform' do
    context 'when the feature flag `do_not_run_safety_net_auth_refresh_jobs` is disabled' do
      before do
        stub_feature_flags(do_not_run_safety_net_auth_refresh_jobs: false)
      end

      it 'runs the safety net refresh' do
        expect_next_instance_of(AuthorizedProjectUpdate::PeriodicRecalculateService) do |service|
          expect(service).to receive(:execute)
        end

        execute_worker
      end
    end

    context 'when the feature flag `do_not_run_safety_net_auth_refresh_jobs` is enabled' do
      before do
        stub_feature_flags(do_not_run_safety_net_auth_refresh_jobs: true)
      end

      it 'skips the safety net refresh' do
        expect(AuthorizedProjectUpdate::PeriodicRecalculateService).not_to receive(:new)

        execute_worker
      end
    end
  end
end
