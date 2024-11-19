# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::RestoreOptInToGitlabCom, feature_category: :activation do
  describe '#perform' do
    let(:connection) { ApplicationRecord.connection }
    let(:temporary_table_name) { :_test_temp_user_details_issue18240 }
    let(:temporary_table) { table(temporary_table_name) }
    let(:users) { table(:users) }
    let(:user_details) { table(:user_details) }
    let(:start_id) { user_details.minimum(:user_id) }
    let(:end_id) { user_details.maximum(:user_id) }

    let!(:user_detail_1) do
      user = table(:users).create!(username: 'u1', email: 'u1@email.com', projects_limit: 5)
      user_details.create!(user_id: user.id, onboarding_status: {})
    end

    let!(:user_detail_2) do
      user = table(:users).create!(username: 'u2', email: 'u2@email.com', projects_limit: 5)
      user_details.create!(user_id: user.id, onboarding_status: { step_url: '/users/sign_up/welcome' })
    end

    let!(:user_detail_3) do
      user = table(:users).create!(username: 'u3', email: 'u3@email.com', projects_limit: 5)

      user_details.create!(user_id: user.id, onboarding_status: {
        step_url: '/users/sign_up/welcome',
        email_opt_in: true
      })
    end

    let!(:user_detail_4) do
      user = table(:users).create!(username: 'u4', email: 'u4@email.com', projects_limit: 5)
      user_details.create!(user_id: user.id, onboarding_status: {})
    end

    let!(:user_detail_5) do
      user = table(:users).create!(username: 'u5', email: 'u5@email.com', projects_limit: 5)
      user_details.create!(user_id: user.id, onboarding_status: { email_opt_in: false })
    end

    before do
      # https://gitlab.com/gitlab-com/gl-infra/production/-/issues/18367
      connection.execute(<<~SQL)
        -- Make sure that the temp table is dropped (in case the after block didn't run)
        DROP TABLE IF EXISTS #{temporary_table_name};

        CREATE TABLE #{temporary_table_name} (
          GITLAB_DOTCOM_ID integer,
          RESTORE_VALUE boolean,
          RESTORE_VALUE_SOURCE varchar(2550)
        );
      SQL

      temporary_table.create!(gitlab_dotcom_id: user_detail_1.user_id, restore_value: true)
      temporary_table.create!(gitlab_dotcom_id: user_detail_2.user_id, restore_value: false)
      temporary_table.create!(gitlab_dotcom_id: user_detail_3.user_id, restore_value: false)
      temporary_table.create!(gitlab_dotcom_id: user_detail_4.user_id, restore_value: nil)
      temporary_table.create!(gitlab_dotcom_id: nil, restore_value: nil)
    end

    after do
      # Make sure that the temp table we created is dropped (it is not removed by the database_cleaner)
      connection.execute(<<~SQL)
        DROP TABLE IF EXISTS #{temporary_table_name};
      SQL
    end

    subject(:migration) do
      described_class.new(
        start_id: start_id,
        end_id: end_id,
        batch_table: :user_details,
        batch_column: :user_id,
        job_arguments: [temporary_table_name],
        sub_batch_size: 2,
        pause_ms: 0,
        connection: ::ApplicationRecord.connection
      )
    end

    it 'updates user_details from the temporary table' do
      expect { migration.perform }.not_to raise_error

      # were updated
      expect(user_detail_1.reload.onboarding_status).to eq('email_opt_in' => true)

      expect(user_detail_2.reload.onboarding_status)
        .to eq('step_url' => '/users/sign_up/welcome', 'email_opt_in' => false)

      # were NOT updated
      expect(user_detail_3.reload.onboarding_status)
        .to eq('step_url' => '/users/sign_up/welcome', 'email_opt_in' => true)

      expect(user_detail_4.reload.onboarding_status).to eq({})
      expect(user_detail_5.reload.onboarding_status).to eq('email_opt_in' => false)
    end
  end
end
