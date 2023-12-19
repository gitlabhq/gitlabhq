# frozen_string_literal: true

require 'spec_helper'

RSpec.describe DeleteUserWorker, feature_category: :user_management do
  let!(:user)         { create(:user) }
  let!(:current_user) { create(:user) }

  it "calls the DeleteUserWorker with the params it was given" do
    expect_next_instance_of(Users::DestroyService) do |service|
      expect(service).to receive(:execute).with(user, {})
    end

    described_class.new.perform(current_user.id, user.id)
  end

  it "uses symbolized keys" do
    expect_next_instance_of(Users::DestroyService) do |service|
      expect(service).to receive(:execute).with(user, { test: "test" })
    end

    described_class.new.perform(current_user.id, user.id, { "test" => "test" })
  end

  shared_examples 'does nothing' do
    it "does not instantiate a DeleteUserWorker" do
      expect(Users::DestroyService).not_to receive(:new)

      perform
    end
  end

  context 'when user deleted their own account' do
    subject(:perform) { described_class.new.perform(current_user.id, user.id) }

    before do
      # user is blocked as part of User#delete_async
      user.block
      # custom attribute is created as part of User#delete_async
      UserCustomAttribute.set_deleted_own_account_at(user)
    end

    shared_examples 'proceeds with deletion' do
      it "proceeds with deletion" do
        expect_next_instance_of(Users::DestroyService) do |service|
          expect(service).to receive(:execute).with(user, {})
        end

        perform
      end
    end

    it_behaves_like 'proceeds with deletion'

    context 'when delay_delete_own_user feature flag is disabled' do
      before do
        stub_feature_flags(delay_delete_own_user: false)
      end

      it_behaves_like 'proceeds with deletion'
    end

    shared_examples 'logs' do |reason|
      it 'logs' do
        expect(Gitlab::AppLogger).to receive(:info).with({
          message: 'Skipped own account deletion.',
          reason: reason,
          user_id: user.id,
          username: user.username
        })

        perform
      end
    end

    shared_examples 'updates the user\'s custom attributes' do
      it 'destroys the user\'s DELETED_OWN_ACCOUNT_AT custom attribute' do
        key = UserCustomAttribute::DELETED_OWN_ACCOUNT_AT
        expect { perform }.to change { user.custom_attributes.by_key(key).count }.from(1).to(0)
      end

      context 'when custom attribute is not present' do
        before do
          UserCustomAttribute.delete_all
        end

        it 'does nothing' do
          expect { perform }.not_to raise_error
        end
      end

      it 'creates a SKIPPED_ACCOUNT_DELETION_AT custom attribute for the user' do
        key = UserCustomAttribute::SKIPPED_ACCOUNT_DELETION_AT
        expect { perform }.to change { user.custom_attributes.by_key(key).count }.from(0).to(1)
      end
    end

    context 'when user is banned' do
      before do
        user.activate
        user.ban
      end

      it_behaves_like 'does nothing'
      it_behaves_like 'logs', 'User has been banned.'
      it_behaves_like 'updates the user\'s custom attributes'
    end

    context 'when user is not blocked (e.g. result of user reinstatement request)' do
      before do
        user.activate
      end

      it_behaves_like 'does nothing'
      it_behaves_like 'logs', 'User has been unblocked.'
      it_behaves_like 'updates the user\'s custom attributes'
    end
  end

  context 'when user to delete does not exist' do
    subject(:perform) { described_class.new.perform(current_user.id, non_existing_record_id) }

    it_behaves_like 'does nothing'
  end

  context 'when current user does not exist' do
    subject(:perform) { described_class.new.perform(non_existing_record_id, user.id) }

    it_behaves_like 'does nothing'
  end

  context 'when user to delete and current user do not exist' do
    subject(:perform) { described_class.new.perform(non_existing_record_id, non_existing_record_id) }

    it_behaves_like 'does nothing'
  end
end
