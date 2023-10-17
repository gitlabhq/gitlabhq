# frozen_string_literal: true

require 'spec_helper'

RSpec.describe VsCode::Settings::CreateOrUpdateService, feature_category: :web_ide do
  describe '#execute' do
    let_it_be(:user) { create(:user) }

    let(:opts) do
      {
        setting_type: "settings",
        content: '{ "editor.fontSize": 12 }'
      }
    end

    subject { described_class.new(current_user: user, params: opts).execute }

    context 'when setting_type is machines' do
      it 'returns default machine as a successful response' do
        opts = { setting_type: "machines", machines: '[]' }
        result = described_class.new(current_user: user, params: opts).execute

        expect(result.payload).to eq(VsCode::Settings::DEFAULT_MACHINE)
      end
    end

    it 'creates a new record when a record with the setting does not exist' do
      expect { subject }.to change { User.find(user.id).vscode_settings.count }.from(0).to(1)
      record = User.find(user.id).vscode_settings.by_setting_type('settings').first
      expect(record.content).to eq('{ "editor.fontSize": 12 }')
    end

    it 'updates the existing record if setting exists' do
      setting = create(:vscode_setting, user: user)

      expect { subject }.to change {
        VsCode::Settings::VsCodeSetting.find(setting.id).content
      }.from(setting.content).to(opts[:content])
    end

    it 'fails if an invalid value is passed' do
      invalid_opts = { setting_type: nil, content: nil }
      result = described_class.new(current_user: user, params: invalid_opts).execute

      expect(result.status).to eq(:error)
    end
  end
end
