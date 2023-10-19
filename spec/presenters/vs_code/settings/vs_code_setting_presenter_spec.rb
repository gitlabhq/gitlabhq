# frozen_string_literal: true

require 'spec_helper'

RSpec.describe VsCode::Settings::VsCodeSettingPresenter, feature_category: :web_ide do
  subject(:presenter) { described_class.new(setting) }

  context "when presenting default machine" do
    let(:setting) { VsCode::Settings::DEFAULT_MACHINE }

    describe '#content' do
      it { expect(presenter.content).to be_nil }
    end

    describe '#machines' do
      it { expect(presenter.machines).to eq(VsCode::Settings::DEFAULT_MACHINE[:machines]) }
    end

    describe '#machine_id' do
      it { expect(presenter.machine_id).to be_nil }
    end
  end

  context "when presenting persisted setting" do
    let(:setting) { build_stubbed(:vscode_setting, setting_type: 'extensions') }

    describe '#content' do
      it { expect(presenter.content).to eq(setting.content) }
    end

    describe '#machines' do
      it { expect(presenter.machines).to be_nil }
    end

    describe '#machine_id' do
      it { expect(presenter.machine_id).to eq(VsCode::Settings::DEFAULT_MACHINE[:uuid]) }
    end

    describe 'version' do
      it { expect(presenter.version).to eq(setting.version) }
    end
  end
end
