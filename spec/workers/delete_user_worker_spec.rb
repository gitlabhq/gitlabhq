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

  context 'when user is banned' do
    subject(:perform) { described_class.new.perform(current_user.id, user.id) }

    before do
      user.ban
    end

    it_behaves_like 'does nothing'

    context 'when delay_delete_own_user feature flag is disabled' do
      before do
        stub_feature_flags(delay_delete_own_user: false)
      end

      it "proceeds with deletion" do
        expect_next_instance_of(Users::DestroyService) do |service|
          expect(service).to receive(:execute).with(user, {})
        end

        perform
      end
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
