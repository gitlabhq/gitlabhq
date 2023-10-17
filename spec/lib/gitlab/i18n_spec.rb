# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::I18n, feature_category: :internationalization do
  let(:user) { create(:user, preferred_language: :es) }

  describe '.selectable_locales' do
    include StubLanguagesTranslationPercentage

    it 'does not return languages with default translation levels 60%' do
      stub_languages_translation_percentage(pt_BR: 0, en: 100, es: 65)

      expect(described_class.selectable_locales).to eq({
        'en' => 'English',
        'es' => 'Spanish - español'
      })
    end

    it 'does not return languages with less than 100% translation levels' do
      stub_languages_translation_percentage(pt_BR: 0, en: 100, es: 65)

      expect(described_class.selectable_locales(100)).to eq({ 'en' => 'English' })
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

  describe '.pluralisation_rule' do
    context 'when overridden' do
      before do
        # Internally, FastGettext sets
        # Thread.current[:fast_gettext_pluralisation_rule].
        # Our patch patches `FastGettext.pluralisation_rule` instead.
        FastGettext.pluralisation_rule = :something
      end

      it 'returns custom definition regardless' do
        expect(FastGettext.pluralisation_rule).to eq(Gitlab::I18n::Pluralization)
      end
    end
  end

  describe '.trimmed_language_name' do
    it 'trims the language name', :aggregate_failures do
      expect(described_class.trimmed_language_name('en')).to eq('English')
      expect(described_class.trimmed_language_name('bg')).to eq('Bulgarian')
      expect(described_class.trimmed_language_name('id_ID')).to eq('Indonesian')
      expect(described_class.trimmed_language_name('nb_NO')).to eq('Norwegian (Bokmål)')
      expect(described_class.trimmed_language_name('zh_HK')).to eq('Chinese, Traditional (Hong Kong)')
    end

    it 'return nil for unknown language code' do
      expect(described_class.trimmed_language_name('_invalid_code_')).to be_nil
    end
  end
end
