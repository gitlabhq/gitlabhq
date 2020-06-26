# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AuthorizedProjectUpdate::PeriodicRecalculateWorker do
  describe '#perform' do
    it 'calls AuthorizedProjectUpdate::PeriodicRecalculateService' do
      expect_next_instance_of(AuthorizedProjectUpdate::PeriodicRecalculateService) do |service|
        expect(service).to receive(:execute)
      end

      subject.perform
    end

    context 'feature flag :periodic_project_authorization_recalculation is disabled' do
      before do
        stub_feature_flags(periodic_project_authorization_recalculation: false)
      end

      it 'does not call AuthorizedProjectUpdate::PeriodicRecalculateService' do
        expect(AuthorizedProjectUpdate::PeriodicRecalculateService).not_to receive(:new)

        subject.perform
      end
    end
  end
end
