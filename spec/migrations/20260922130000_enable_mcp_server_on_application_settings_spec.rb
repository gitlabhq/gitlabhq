# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe EnableMcpServerOnApplicationSettings, migration: :gitlab_main, feature_category: :mcp_server do
  let(:application_settings) { table(:application_settings) }
  let(:instance_audit_events) { table(:instance_audit_events) }

  # Both shapes are written for every admin change, copied from real events.
  let(:key_event) do
    <<~YAML
      ---
      :change: mcp_server_enabled
      :from: #{from}
      :to: #{to}
      :target_details: Mcp server enabled
      :event_name: application_setting_updated
    YAML
  end

  let(:settings_event) do
    <<~YAML
      ---
      :change: mcp_server_settings
      :from: !ruby/hash:ActiveSupport::HashWithIndifferentAccess
        mcp_server_enabled: #{from}
      :to: !ruby/hash:ActiveSupport::HashWithIndifferentAccess
        mcp_server_enabled: #{to}
      :target_details: Mcp server settings
      :event_name: application_setting_updated
    YAML
  end

  let(:from) { true }
  let(:to) { false }

  let!(:app_setting) { application_settings.create!(mcp_server_settings: mcp_server_settings) }
  let(:mcp_server_settings) { { 'mcp_server_enabled' => false } }

  def mcp_server_enabled
    app_setting.reload.mcp_server_settings['mcp_server_enabled']
  end

  def create_audit_event(details, created_at: Time.current)
    instance_audit_events.create!(created_at: created_at, author_id: 1,
      event_name: 'application_setting_updated', details: details)
  end

  describe '#up' do
    it 'turns MCP on when it is off and no admin changed it' do
      migrate!

      expect(mcp_server_enabled).to be true
    end

    context 'on GitLab.com, where the instance value does not gate access' do
      before do
        allow(Gitlab).to receive(:com?).and_return(true)
      end

      it 'leaves the value off' do
        migrate!

        expect(mcp_server_enabled).to be false
      end
    end

    context 'when MCP is already on' do
      let(:mcp_server_settings) { { 'mcp_server_enabled' => true } }

      it 'does not scan the audit log' do
        expect(ActiveRecord::QueryRecorder.new { migrate! }.log.join).not_to include('instance_audit_events')
      end
    end

    context 'when the key is not set, which already reads as on' do
      let(:mcp_server_settings) { {} }

      it 'leaves the value unset' do
        migrate!

        expect(app_setting.reload.mcp_server_settings).to eq({})
      end
    end

    context 'when an admin changed MCP' do
      it 'leaves it off, matching the event for the key' do
        create_audit_event(key_event)

        migrate!

        expect(mcp_server_enabled).to be false
      end

      it 'leaves it off, matching the event for the whole value' do
        create_audit_event(settings_event)

        migrate!

        expect(mcp_server_enabled).to be false
      end

      context 'when the change was to turn it on' do
        let(:from) { false }
        let(:to) { true }

        it 'leaves it off, because a later migration may have turned it off' do
          create_audit_event(key_event)
          create_audit_event(settings_event)

          migrate!

          expect(mcp_server_enabled).to be false
        end
      end

      context 'when the change was before the setting existed' do
        it 'turns MCP on' do
          create_audit_event(key_event, created_at: Time.utc(2026, 3, 25))

          migrate!

          expect(mcp_server_enabled).to be true
        end
      end
    end

    context 'when the audit scan exceeds the timeout' do
      let(:migration) { described_class.new }

      before do
        allow(migration).to receive(:select_value).and_call_original
        allow(migration).to receive(:select_value).with(/instance_audit_events/)
          .and_raise(ActiveRecord::QueryCanceled)
      end

      it 'leaves it off, because an admin may have changed it' do
        migration.up

        expect(mcp_server_enabled).to be false
      end
    end

    context 'when an admin turned a different setting off' do
      it 'turns MCP on' do
        create_audit_event(<<~YAML)
          ---
          :change: duo_features_enabled
          :from: true
          :to: false
        YAML

        migrate!

        expect(mcp_server_enabled).to be true
      end
    end
  end
end
