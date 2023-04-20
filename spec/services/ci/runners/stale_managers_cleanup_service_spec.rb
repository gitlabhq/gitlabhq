# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::Runners::StaleManagersCleanupService, feature_category: :runner_fleet do
  let(:service) { described_class.new }
  let!(:runner_manager3) { create(:ci_runner_machine, created_at: 6.months.ago, contacted_at: Time.current) }

  subject(:response) { service.execute }

  context 'with no stale runner managers' do
    it 'does not clean any runner managers and returns :success status' do
      expect do
        expect(response).to be_success
        expect(response.payload).to match({ deleted_managers: false })
      end.not_to change { Ci::RunnerManager.count }.from(1)
    end
  end

  context 'with some stale runner managers' do
    before do
      create(:ci_runner_machine, :stale)
      create(:ci_runner_machine, :stale, contacted_at: nil)
    end

    it 'only leaves non-stale runners' do
      expect(response).to be_success
      expect(response.payload).to match({ deleted_managers: true })
      expect(Ci::RunnerManager.all).to contain_exactly(runner_manager3)
    end

    context 'with more stale runners than MAX_DELETIONS' do
      before do
        stub_const("#{described_class}::MAX_DELETIONS", 1)
      end

      it 'only leaves non-stale runners' do
        expect do
          expect(response).to be_success
          expect(response.payload).to match({ deleted_managers: true })
        end.to change { Ci::RunnerManager.count }.by(-Ci::Runners::StaleManagersCleanupService::MAX_DELETIONS)
      end
    end
  end
end
