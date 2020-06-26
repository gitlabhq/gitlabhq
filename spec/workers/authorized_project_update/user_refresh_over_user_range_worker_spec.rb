# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AuthorizedProjectUpdate::UserRefreshOverUserRangeWorker do
  let(:start_user_id) { 42 }
  let(:end_user_id) { 4242 }

  describe '#perform' do
    it 'calls AuthorizedProjectUpdate::RecalculateForUserRangeService' do
      expect_next_instance_of(AuthorizedProjectUpdate::RecalculateForUserRangeService) do |service|
        expect(service).to receive(:execute)
      end

      subject.perform(start_user_id, end_user_id)
    end

    context 'feature flag :periodic_project_authorization_recalculation is disabled' do
      before do
        stub_feature_flags(periodic_project_authorization_recalculation: false)
      end

      it 'does not call AuthorizedProjectUpdate::RecalculateForUserRangeService' do
        expect(AuthorizedProjectUpdate::RecalculateForUserRangeService).not_to receive(:new)

        subject.perform(start_user_id, end_user_id)
      end
    end
  end
end
