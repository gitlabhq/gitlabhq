# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SpamLog do
  let_it_be(:admin) { create(:admin) }

  describe 'associations' do
    it { is_expected.to belong_to(:user) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:user) }
  end

  describe '#remove_user' do
    it 'blocks the user' do
      spam_log = build(:spam_log)

      expect { spam_log.remove_user(deleted_by: admin) }.to change { spam_log.user.blocked? }.to(true)
    end

    context 'when admin mode is enabled', :enable_admin_mode do
      it 'initiates user removal', :sidekiq_inline do
        spam_log = build(:spam_log)
        user = spam_log.user

        perform_enqueued_jobs do
          spam_log.remove_user(deleted_by: admin)
        end

        expect(
          Users::GhostUserMigration.where(user: user, initiator_user: admin)
        ).to be_exists
      end
    end

    context 'when admin mode is disabled' do
      it 'does not allow to remove the user', :sidekiq_might_not_need_inline do
        spam_log = build(:spam_log)
        user = spam_log.user

        perform_enqueued_jobs do
          spam_log.remove_user(deleted_by: admin)
        end

        expect(User.exists?(user.id)).to be(true)
      end
    end
  end

  describe '.verify_recaptcha!' do
    let_it_be(:spam_log) { create(:spam_log, user: admin, recaptcha_verified: false) }

    context 'the record cannot be found' do
      it 'updates nothing' do
        expect(instance_of(described_class)).not_to receive(:update!)

        described_class.verify_recaptcha!(id: spam_log.id, user_id: admin.id)

        expect(spam_log.recaptcha_verified).to be_falsey
      end

      it 'does not error despite not finding a record' do
        expect { described_class.verify_recaptcha!(id: -1, user_id: admin.id) }.not_to raise_error
      end
    end

    context 'the record exists' do
      it 'updates recaptcha_verified' do
        expect { described_class.verify_recaptcha!(id: spam_log.id, user_id: admin.id) }
          .to change { spam_log.reload.recaptcha_verified }.from(false).to(true)
      end
    end
  end
end
