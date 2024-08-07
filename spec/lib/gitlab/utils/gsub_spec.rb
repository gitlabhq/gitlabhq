# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Gitlab::Utils::Gsub, feature_category: :shared do
  describe '#gsub_with_limit' do
    let(:regex) { /(?<scheme>ftp)/ }

    def result(text, regex, limit:)
      described_class.gsub_with_limit(text, regex, limit: limit) do |match|
        if match[:scheme]
          "http|#{match[:scheme]}|rss"
        else
          match.to_s
        end
      end
    end

    it 'replaces all instances of the match in a string' do
      text = 'Use only https instead of ftp or sftp'

      expect(result(text, regex, limit: 0)).to eq('Use only https instead of http|ftp|rss or shttp|ftp|rss')
    end

    it 'replaces nothing when no match' do
      text = 'Use only https instead of gopher'

      expect(result(text, regex, limit: 100)).to eq(text)
    end

    it 'handles empty text' do
      text = ''

      expect(result(text, regex, limit: 100)).to eq('')
    end

    it 'limits the number of replacements' do
      text = 'Use only https instead of ftp or sftp'

      expect(result(text, regex, limit: 1)).to eq('Use only https instead of http|ftp|rss or sftp')
    end
  end
end
