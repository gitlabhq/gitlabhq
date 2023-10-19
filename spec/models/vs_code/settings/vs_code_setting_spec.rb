# frozen_string_literal: true

require 'spec_helper'

RSpec.describe VsCode::Settings::VsCodeSetting, feature_category: :web_ide do
  let!(:user) { create(:user) }
  let!(:setting) { create(:vscode_setting, user: user, setting_type: 'settings') }

  describe 'validates the presence of required attributes' do
    it { is_expected.to validate_presence_of(:setting_type) }
    it { is_expected.to validate_presence_of(:content) }
  end

  describe 'relationship validation' do
    it { is_expected.to belong_to(:user) }
  end

  describe '.by_setting_type' do
    subject { described_class.by_setting_type('settings') }

    it { is_expected.to contain_exactly(setting) }
  end

  describe '.by_user' do
    subject { described_class.by_user(user) }

    it { is_expected.to contain_exactly(setting) }
  end
end
