# frozen_string_literal: true

require 'spec_helper'

RSpec.describe VsCode::Settings::VsCodeManifestPresenter, feature_category: :web_ide do
  let(:settings) { [] }

  subject(:presenter) { described_class.new(settings) }

  describe '#latest' do
    context 'when there are not persisted settings' do
      it 'includes default machine uuid' do
        default_machine = ::VsCode::Settings::DEFAULT_MACHINE

        expect(presenter.latest.length).to eq(1)
        expect(presenter.latest['machines']).to eq(default_machine[:uuid])
      end
    end

    context 'when there are persisted settings' do
      let(:settings) { [build_stubbed(:vscode_setting, setting_type: 'extensions')] }

      it 'includes the persisted setting uuid' do
        expect(presenter.latest.length).to eq(2)
        expect(presenter.latest['extensions']).to eq(settings.first.uuid)
      end
    end
  end

  describe '#session' do
    it 'returns default session' do
      expect(presenter.session).to eq(::VsCode::Settings::DEFAULT_SESSION)
    end
  end
end
