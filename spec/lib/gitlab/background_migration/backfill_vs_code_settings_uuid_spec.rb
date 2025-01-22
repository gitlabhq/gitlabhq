# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillVsCodeSettingsUuid, schema: 20231220225325, feature_category: :web_ide do
  let!(:vs_code_settings) { table(:vs_code_settings) }
  let!(:users) { table(:users) }

  let!(:user) do
    users.create!(
      email: "test1@example.com",
      username: "test1",
      notification_email: "test@example.com",
      name: "test",
      state: "active",
      projects_limit: 10)
  end

  subject(:migration) do
    described_class.new(
      start_id: vs_code_setting_one.id,
      end_id: vs_code_setting_two.id,
      batch_table: :vs_code_settings,
      batch_column: :id,
      sub_batch_size: 100,
      pause_ms: 0,
      connection: ActiveRecord::Base.connection
    )
  end

  describe "#perform" do
    context 'when it finds vs_code_setting rows with empty uuid' do
      let(:vs_code_setting_one) do
        vs_code_settings.create!(user_id: user.id, setting_type: 'profiles', content: '{}')
      end

      let(:vs_code_setting_two) do
        vs_code_settings.create!(user_id: user.id, setting_type: 'tasks', content: '{}')
      end

      it 'populates uuid column with a generated uuid' do
        expect(vs_code_setting_one.uuid).to be_nil
        expect(vs_code_setting_two.uuid).to be_nil

        migration.perform

        expect(vs_code_setting_one.reload.uuid).not_to be_nil
        expect(vs_code_setting_two.reload.uuid).not_to be_nil
      end
    end

    context 'when it finds vs_code_setting rows with non-empty uuid' do
      let(:vs_code_setting_one) do
        vs_code_settings.create!(user_id: user.id, setting_type: 'profiles', content: '{}', uuid: SecureRandom.uuid)
      end

      let(:vs_code_setting_two) do
        vs_code_settings.create!(user_id: user.id, setting_type: 'tasks', content: '{}')
      end

      it 'populates uuid column with a generated uuid' do
        expect(vs_code_setting_one.uuid).not_to be_nil
        expect(vs_code_setting_two.uuid).to be_nil

        previous_uuid = vs_code_setting_one.uuid

        migration.perform

        expect(vs_code_setting_one.reload.uuid).to eq(previous_uuid)
        expect(vs_code_setting_two.reload.uuid).not_to be_nil
      end
    end
  end
end
