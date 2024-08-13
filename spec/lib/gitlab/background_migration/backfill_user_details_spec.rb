# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillUserDetails, schema: 20240716191121, feature_category: :acquisition do
  let(:users) { table(:users) }
  let(:user_details) { table(:user_details) }

  let!(:first_user) do
    users.create!(name: 'bob', email: 'bob@example.com', projects_limit: 1).tap do |record|
      user_details.create!(user_id: record.id)
    end
  end

  let!(:user_without_details) { users.create!(name: 'foo', email: 'foo@example.com', projects_limit: 1) }
  let!(:multiple_user_without_details) { users.create!(name: 'foo2', email: 'foo2@example.com', projects_limit: 1) }

  subject(:migration) do
    described_class.new(
      start_id: first_user.id,
      end_id: multiple_user_without_details.id,
      batch_table: :users,
      batch_column: :id,
      sub_batch_size: 100,
      pause_ms: 0,
      connection: ApplicationRecord.connection
    )
  end

  describe '#perform' do
    it 'creates only the needed user_details entries' do
      expect(user_details.count).to eq(1)
      expect(user_details.exists?(user_id: first_user.id)).to be(true)
      expect(user_details.exists?(user_id: user_without_details.id)).to be(false)
      expect(user_details.exists?(user_id: multiple_user_without_details.id)).to be(false)

      expect { migration.perform }.to change { user_details.count }.by(2)

      expect(user_details.exists?(user_id: user_without_details.id)).to be(true)
      expect(user_details.exists?(user_id: multiple_user_without_details.id)).to be(true)
    end

    context 'when there are no user_details that are missing for user records' do
      before do
        user_details.create!(user_id: user_without_details.id)
        user_details.create!(user_id: multiple_user_without_details.id)
      end

      it 'creates only the needed user_details entries' do
        expect(user_details.count).to eq(3)

        expect { migration.perform }.to change { user_details.count }.by(0)
      end
    end

    context 'when upsert raises an error', quarantine: {
      type: :flaky,
      issue: 'https://gitlab.com/gitlab-org/gitlab/-/issues/477109'
    } do
      before do
        allow(described_class::UserDetail).to receive(:upsert_all).and_raise(Exception, '_error_')
      end

      it 'logs the error' do
        expect_next_instance_of(Gitlab::BackgroundMigration::Logger) do |logger|
          details = {
            class: Exception,
            message: "BackfillUserDetails Migration: error inserting. Reason: _error_",
            user_ids: [user_without_details.id, multiple_user_without_details.id]
          }
          expect(logger).to receive(:error).with(details)
        end

        expect { migration.perform }.to raise_error(Exception)
      end
    end
  end
end
