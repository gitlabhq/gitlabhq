# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::I18n do
  let(:user) { create(:user, preferred_language: 'es') }

  describe '.selectable_locales' do
    it 'does not return languages that should not be available in the UI' do
      Gitlab::I18n::NOT_AVAILABLE_IN_UI.each do |language|
        expect(described_class.selectable_locales).not_to include(language)
      end
    end
  end

  describe '.locale=' do
    after do
      described_class.use_default_locale
    end

    it 'sets the locale based on current user preferred language' do
      described_class.locale = user.preferred_language

      expect(FastGettext.locale).to eq('es')
      expect(::I18n.locale).to eq(:es)
    end
  end

  describe '.use_default_locale' do
    it 'resets the locale to the default language' do
      described_class.locale = user.preferred_language

      described_class.use_default_locale

      expect(FastGettext.locale).to eq('en')
      expect(::I18n.locale).to eq(:en)
    end
  end
end
