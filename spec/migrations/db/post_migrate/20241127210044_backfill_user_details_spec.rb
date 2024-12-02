# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe BackfillUserDetails, migration: :gitlab_main, feature_category: :acquisition, migration_version: 20241127210044 do
  let(:connection) { ActiveRecord::Base.connection }
  let(:users) { table(:users) }
  let(:user_details) { table(:user_details) }

  let!(:first_user) do
    users.create!(name: 'bob', email: 'bob@example.com', projects_limit: 1, user_type: 15).tap do |record|
      user_details.create!(user_id: record.id)
    end
  end

  let!(:user_without_details) { users.create!(name: 'foo', email: 'foo@example.com', projects_limit: 1, user_type: 15) }
  let!(:multiple_user_without_details) do
    users.create!(name: 'foo2', email: 'foo2@example.com', projects_limit: 1, user_type: 17)
  end

  let!(:user_without_details_out_of_scope) do
    users.create!(name: 'foo3', email: 'foo3@example.com', projects_limit: 1, user_type: 0)
  end

  describe '#up' do
    it 'creates only the needed user_details entries' do
      expect(user_details.count).to eq(1)
      expect(user_details.exists?(user_id: first_user.id)).to be(true)
      expect(user_details.exists?(user_id: user_without_details.id)).to be(false)
      expect(user_details.exists?(user_id: multiple_user_without_details.id)).to be(false)
      expect(user_details.exists?(user_id: user_without_details_out_of_scope.id)).to be(false)

      expect { migrate! }.to change { user_details.count }.by(2)

      expect(user_details.exists?(user_id: user_without_details.id)).to be(true)
      expect(user_details.exists?(user_id: multiple_user_without_details.id)).to be(true)
      expect(user_details.exists?(user_id: user_without_details_out_of_scope.id)).to be(false)
    end

    context 'when there are no user_details that are missing for user records' do
      before do
        user_details.create!(user_id: user_without_details.id)
        user_details.create!(user_id: multiple_user_without_details.id)
        user_details.create!(user_id: user_without_details_out_of_scope.id)
      end

      it 'creates only the needed user_details entries' do
        expect(user_details.count).to eq(4)

        expect { migrate! }.not_to change { user_details.count }
      end
    end

    context 'when upsert raises an error' do
      before do
        allow(described_class::UserDetail).to receive(:upsert_all).and_raise(Exception, '_error_')
      end

      it 'logs the error' do
        expect_next_instance_of(Gitlab::BackgroundMigration::Logger) do |logger|
          details = {
            class: Exception,
            message: "BackfillUserDetails Migration: error inserting. Reason: _error_",
            user_ids: [user_without_details.id]
          }
          expect(logger).to receive(:error).with(details)
        end

        expect { migrate! }.to raise_error(Exception)
      end
    end
  end
end
