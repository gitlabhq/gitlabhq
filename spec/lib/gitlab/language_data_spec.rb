# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::LanguageData do
  describe '#extensions' do
    before do
      described_class.clear_extensions!
    end

    it 'loads the extensions once' do
      expect(YAML).to receive(:load_file).once.and_call_original

      2.times do
        expect(described_class.extensions).to be_a(Set)
        expect(described_class.extensions.count).to be > 0
        # Sanity check for known extensions
        expect(described_class.extensions).to include(*%w[.rb .yml .json])
      end
    end
  end
end
