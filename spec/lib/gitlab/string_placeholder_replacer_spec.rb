# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Gitlab::StringPlaceholderReplacer, feature_category: :shared do
  describe 'replace_string_placeholders' do
    it 'returns nil if the string is blank' do
      expect(described_class.replace_string_placeholders(nil, /whatever/)).to be_blank
    end

    it 'returns the string if the placeholder regex is not specified' do
      expect(described_class.replace_string_placeholders('whatever')).to eq 'whatever'
    end

    it 'returns the string if no block is given' do
      expect(described_class.replace_string_placeholders('whatever', /whatever/)).to eq 'whatever'
    end

    context 'when all params are valid' do
      let(:string) { '%{path}/%{id}/%{branch}' }
      let(:regex) { /(path|id)/ }

      it 'replaces each placeholders with the block result' do
        result = described_class.replace_string_placeholders(string, regex) do |arg|
          'WHATEVER'
        end

        expect(result).to eq 'WHATEVER/WHATEVER/%{branch}'
      end

      it 'does not replace the placeholder if the block result is nil' do
        result = described_class.replace_string_placeholders(string, regex) do |arg|
          arg == 'path' ? nil : 'WHATEVER'
        end

        expect(result).to eq '%{path}/WHATEVER/%{branch}'
      end

      it 'limits the number of replacements' do
        result = described_class.replace_string_placeholders(string, regex, limit: 1) do |arg|
          'WHATEVER'
        end

        expect(result).to eq 'WHATEVER/%{id}/%{branch}'
      end
    end

    context 'with in_uri: true' do
      let(:string) { '%%7Bpath%7D/%25%7bid%7d/%{branch}/%%7Btag%7D' }
      let(:regex) { /(path|id)/ }

      it 'replaces each placeholders with the block result, leaving non-matches alone' do
        result = described_class.replace_string_placeholders(string, regex, in_uri: true) do |arg|
          'WHATEVER'
        end

        expect(result).to eq 'WHATEVER/WHATEVER/%{branch}/%%7Btag%7D'
      end
    end
  end
end
