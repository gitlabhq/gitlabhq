# frozen_string_literal: true

require 'spec_helper'

RSpec.describe VsCode::Settings::CreateOrUpdateService, feature_category: :web_ide do
  describe '#execute' do
    let_it_be(:user) { create(:user) }

    context 'when setting_type is machines' do
      it 'returns default machine as a successful response' do
        opts = { setting_type: "machines", machines: '[]' }
        result = described_class.new(current_user: user, params: opts).execute

        expect(result.payload).to eq(VsCode::Settings::DEFAULT_MACHINE)
      end
    end

    context 'when setting_type is extensions' do
      let(:settings_context_hash) { '1234' }
      let(:extensions_params) do
        {
          setting_type: VsCode::Settings::EXTENSIONS,
          content: '[{ "version": "1.0.0" }]',
          settings_context_hash: settings_context_hash
        }
      end

      subject do
        described_class.new(current_user: user,
          params: extensions_params).execute
      end

      it 'creates a new record when a record with settings_context_hash does not exist' do
        expect { subject }.to change { User.find(user.id).vscode_settings.count }.from(0).to(1)
        record = User.find(user.id).vscode_settings.by_setting_types([VsCode::Settings::EXTENSIONS],
          settings_context_hash).first
        expect(record.content).to eq('[{ "version": "1.0.0" }]')
        expect(record.settings_context_hash).to eq(settings_context_hash)

        new_settings_context_hash = '5678'
        new_params = extensions_params.merge(settings_context_hash: new_settings_context_hash)
        described_class.new(current_user: user,
          params: new_params).execute
        expect(User.find(user.id).vscode_settings.count).to eq(2)
      end

      it 'updates record if a record with the same setings_context_hash exists' do
        setting = create(:vscode_setting, user: user, setting_type: VsCode::Settings::EXTENSIONS,
          settings_context_hash: settings_context_hash)

        expect { subject }.to change {
          setting.reload.content
        }.from(setting.content).to(extensions_params[:content]).and change { setting.reload.uuid }
      end
    end

    context "when setting_type is not extensions" do
      let(:opts) do
        {
          setting_type: "settings",
          content: '{ "editor.fontSize": 12 }'
        }
      end

      subject { described_class.new(current_user: user, params: opts).execute }

      it 'creates a new record when a record with the setting does not exist' do
        expect { subject }.to change { User.find(user.id).vscode_settings.count }.from(0).to(1)
        record = User.find(user.id).vscode_settings.by_setting_types(['settings']).first
        expect(record.content).to eq('{ "editor.fontSize": 12 }')
        expect(record.settings_context_hash).to be_nil
      end

      it 'updates the existing record if setting exists' do
        setting = create(:vscode_setting, user: user)

        expect { subject }.to change { setting.reload.content }.from(setting.content).to(opts[:content]).and change {
          setting.reload.uuid
        }
      end

      it 'fails if an invalid value is passed' do
        invalid_opts = { setting_type: nil, content: nil }
        result = described_class.new(current_user: user, params: invalid_opts).execute

        expect(result.status).to eq(:error)
      end
    end
  end
end
