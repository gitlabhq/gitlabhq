# frozen_string_literal: true

require 'fast_spec_helper'
require 'support/shared_examples/lib/gitlab/malicious_regexp_shared_examples'

RSpec.describe Gitlab::UntrustedRegexp, feature_category: :shared do
  def create_regex(regex_str, multiline: false)
    described_class.new(regex_str, multiline: multiline).freeze
  end

  describe '#initialize' do
    subject { described_class.new(pattern) }

    context 'invalid regexp' do
      let(:pattern) { '[' }

      it { expect { subject }.to raise_error(RegexpError) }
    end
  end

  describe '#replace_all' do
    it 'replaces all instances of the match in a string' do
      result = create_regex('foo').replace_all('foo bar foo', 'oof')

      expect(result).to eq('oof bar oof')
    end
  end

  describe '#replace_gsub' do
    let(:regex_str) { '(?P<scheme>(ftp))' }
    let(:regex) { create_regex(regex_str, multiline: true) }

    def result(text, regex, limit: 0)
      regex.replace_gsub(text, limit: limit) do |match|
        if match[:scheme]
          "http|#{match[:scheme]}|rss"
        else
          match.to_s
        end
      end
    end

    it 'replaces all instances of the match in a string' do
      text = 'Use only https instead of ftp or sftp'

      expect(result(text, regex)).to eq('Use only https instead of http|ftp|rss or shttp|ftp|rss')
    end

    it 'limits the number of replacements' do
      text = 'Use only https instead of ftp or sftp'

      expect(result(text, regex, limit: 1)).to eq('Use only https instead of http|ftp|rss or sftp')
    end

    it 'replaces nothing when no match' do
      text = 'Use only https instead of gopher'

      expect(result(text, regex)).to eq(text)
    end

    it 'handles empty text' do
      text = ''

      expect(result(text, regex)).to eq('')
    end
  end

  describe '#replace' do
    it 'replaces the first instance of the match in a string' do
      result = create_regex('foo').replace('foo bar foo', 'oof')

      expect(result).to eq('oof bar foo')
    end
  end

  describe '#===' do
    it 'returns true for a match' do
      result = create_regex('foo') === 'a foo here'

      expect(result).to be_truthy
    end

    it 'returns false for no match' do
      result = create_regex('foo') === 'a bar here'

      expect(result).to be_falsy
    end

    it 'can handle regular expressions in multiline mode' do
      regexp = create_regex('^\d', multiline: true)

      result = regexp === "Header\n\n1. Content"

      expect(result).to be_truthy
    end
  end

  describe '#match?' do
    subject { create_regex(regexp).match?(text) }

    context 'malicious regexp' do
      let(:text) { malicious_text }
      let(:regexp) { malicious_regexp_re2 }

      include_examples 'malicious regexp'
    end

    context 'matching regexp' do
      let(:regexp) { 'foo' }
      let(:text) { 'foo' }

      it 'returns an array of nil matches' do
        is_expected.to eq(true)
      end
    end

    context 'non-matching regexp' do
      let(:regexp) { 'boo' }
      let(:text) { 'foo' }

      it 'returns an array of nil matches' do
        is_expected.to eq(false)
      end
    end
  end

  describe '#scan' do
    subject { create_regex(regexp).scan(text) }

    context 'malicious regexp' do
      let(:text) { malicious_text }
      let(:regexp) { malicious_regexp_re2 }

      include_examples 'malicious regexp'
    end

    context 'empty regexp' do
      let(:regexp) { '' }
      let(:text) { 'foo' }

      it 'returns an array of nil matches' do
        is_expected.to eq([nil, nil, nil, nil])
      end
    end

    context 'empty capture group regexp' do
      let(:regexp) { '()' }
      let(:text) { 'foo' }

      it 'returns an array of nil matches in an array' do
        is_expected.to eq([[nil], [nil], [nil], [nil]])
      end
    end

    context 'no capture group' do
      let(:regexp) { '.+' }
      let(:text) { 'foo' }

      it 'returns the whole match' do
        is_expected.to eq(['foo'])
      end
    end

    context 'one capture group' do
      let(:regexp) { '(f).+' }
      let(:text) { 'foo' }

      it 'returns the captured part' do
        is_expected.to eq([%w[f]])
      end
    end

    context 'two capture groups' do
      let(:regexp) { '(f).(o)' }
      let(:text) { 'foo' }

      it 'returns the captured parts' do
        is_expected.to eq([%w[f o]])
      end
    end
  end

  describe '#extract_named_group' do
    let(:re) { create_regex('(?P<name>\w+) (?P<age>\d+)|(?P<name_only>\w+)') }
    let(:text) { 'Bob 40' }

    it 'returns values for both named groups' do
      matched = re.scan(text).first

      expect(re.extract_named_group(:name, matched)).to eq 'Bob'
      expect(re.extract_named_group(:age, matched)).to eq '40'
    end

    it 'returns nil if there was no match for group' do
      matched = re.scan('Bob').first

      expect(re.extract_named_group(:name, matched)).to be_nil
      expect(re.extract_named_group(:age, matched)).to be_nil
      expect(re.extract_named_group(:name_only, matched)).to eq 'Bob'
    end

    it 'returns nil if match is nil' do
      matched = '(?P<age>\d+)'.scan(text).first

      expect(re.extract_named_group(:age, matched)).to be_nil
    end

    it 'raises if name is not a capture group' do
      matched = re.scan(text).first

      expect { re.extract_named_group(:foo, matched) }.to raise_error('Invalid named capture group: foo')
    end
  end

  describe '#match' do
    context 'when there are matches' do
      it 'returns a match object' do
        result = create_regex('(?P<number>\d+)').match('hello 10')

        expect(result[:number]).to eq('10')
      end
    end

    context 'when there are no matches' do
      it 'returns nil' do
        result = create_regex('(?P<number>\d+)').match('hello')

        expect(result).to be_nil
      end
    end
  end
end
