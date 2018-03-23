require 'spec_helper'

describe Gitlab::StringPlaceholderReplacer do
  describe '.render_url' do
    it 'returns the nil if the string is blank' do
      expect(described_class.replace_string_placeholders(nil, /whatever/)).to be_blank
    end

    it 'returns the string if the placeholder regex' do
      expect(described_class.replace_string_placeholders('whatever')).to eq 'whatever'
    end

    it 'returns the string if no block given' do
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
    end
  end
end
