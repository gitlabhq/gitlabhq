# frozen_string_literal: true

# require 'fast_spec_helper' -- this no longer runs under fast_spec_helper
require 'spec_helper'
require 'rspec-parameterized'
require 'rails/version'
require 'gettext_i18n_rails'

RSpec.describe Gitlab::I18n::Pluralization, feature_category: :internationalization do
  describe '.call' do
    subject(:rule) { described_class.call(1) }

    context 'with available locales' do
      around do |example|
        Gitlab::I18n.with_locale(locale, &example)
      end

      where(:locale) do
        Gitlab::I18n.available_locales
      end

      with_them do
        it 'supports pluralization' do
          expect(rule).not_to be_nil
        end
      end

      context 'with missing rules' do
        let(:locale) { "pl_PL" }

        before do
          stub_const("#{described_class}::MAP", described_class::MAP.except(locale))
        end

        it 'raises an ArgumentError' do
          expect { rule }.to raise_error(ArgumentError,
            /Missing pluralization rule for locale "#{locale}"/
          )
        end
      end
    end
  end

  describe '.install_on' do
    let(:mod) { Module.new }

    before do
      described_class.install_on(mod)
    end

    it 'adds pluralisation_rule method' do
      expect(mod.pluralisation_rule).to eq(described_class)
    end
  end
end
