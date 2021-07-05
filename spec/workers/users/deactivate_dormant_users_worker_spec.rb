# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Users::DeactivateDormantUsersWorker do
  describe '#perform' do
    let_it_be(:dormant) { create(:user, last_activity_on: User::MINIMUM_INACTIVE_DAYS.days.ago.to_date) }
    let_it_be(:inactive) { create(:user, last_activity_on: nil) }

    subject(:worker) { described_class.new }

    it 'does not run for GitLab.com' do
      expect(Gitlab).to receive(:com?).and_return(true)
      expect(Gitlab::CurrentSettings).not_to receive(:current_application_settings)

      worker.perform

      expect(User.dormant.count).to eq(1)
      expect(User.with_no_activity.count).to eq(1)
    end

    context 'when automatic deactivation of dormant users is enabled' do
      before do
        stub_application_setting(deactivate_dormant_users: true)
      end

      it 'deactivates dormant users' do
        freeze_time do
          stub_const("#{described_class.name}::BATCH_SIZE", 1)
          stub_const("#{described_class.name}::PAUSE_SECONDS", 0)

          expect(worker).to receive(:sleep).twice

          worker.perform

          expect(User.dormant.count).to eq(0)
          expect(User.with_no_activity.count).to eq(0)
        end
      end
    end

    context 'when automatic deactivation of dormant users is disabled' do
      before do
        stub_application_setting(deactivate_dormant_users: false)
      end

      it 'does nothing' do
        worker.perform

        expect(User.dormant.count).to eq(1)
        expect(User.with_no_activity.count).to eq(1)
      end
    end
  end
end
