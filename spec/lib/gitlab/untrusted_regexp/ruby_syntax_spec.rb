# frozen_string_literal: true

require 'fast_spec_helper'
require 'support/shared_examples/lib/gitlab/malicious_regexp_shared_examples'
require 'support/helpers/stub_feature_flags'

RSpec.describe Gitlab::UntrustedRegexp::RubySyntax do
  describe '.matches_syntax?' do
    it 'returns true if regexp is valid' do
      expect(described_class.matches_syntax?('/some .* thing/'))
        .to be true
    end

    it 'returns true if regexp is invalid, but resembles regexp' do
      expect(described_class.matches_syntax?('/some ( thing/'))
        .to be true
    end
  end

  describe '.valid?' do
    it 'returns true if regexp is valid' do
      expect(described_class.valid?('/some .* thing/'))
        .to be true
    end

    it 'returns false if regexp is invalid' do
      expect(described_class.valid?('/some ( thing/'))
        .to be false
    end
  end

  describe '.fabricate' do
    context 'when regexp is valid' do
      it 'fabricates regexp without flags' do
        expect(described_class.fabricate('/some .* thing/')).not_to be_nil
      end
    end

    context 'when regexp is empty' do
      it 'fabricates regexp correctly' do
        expect(described_class.fabricate('//')).not_to be_nil
      end
    end

    context 'when regexp is a raw pattern' do
      it 'returns error' do
        expect(described_class.fabricate('some .* thing')).to be_nil
      end
    end
  end

  describe '.fabricate!' do
    context 'safe regexp is used' do
      context 'when regexp is using /regexp/ scheme with flags' do
        it 'fabricates regexp with a single flag' do
          regexp = described_class.fabricate!('/something/i')

          expect(regexp).to eq Gitlab::UntrustedRegexp.new('(?i)something')
          expect(regexp.scan('SOMETHING')).to be_one
        end

        it 'fabricates regexp with multiple flags' do
          regexp = described_class.fabricate!('/something/im')

          expect(regexp).to eq Gitlab::UntrustedRegexp.new('(?im)something')
        end

        it 'fabricates regexp without flags' do
          regexp = described_class.fabricate!('/something/')

          expect(regexp).to eq Gitlab::UntrustedRegexp.new('something')
        end
      end
    end

    context 'when unsafe regexp is used' do
      include StubFeatureFlags

      before do
        stub_feature_flags(allow_unsafe_ruby_regexp: true)

        allow(Gitlab::UntrustedRegexp).to receive(:new).and_raise(RegexpError)
      end

      context 'when no fallback is enabled' do
        it 'raises an exception' do
          expect { described_class.fabricate!('/something/') }
            .to raise_error(RegexpError)
        end
      end

      context 'when fallback is used' do
        it 'fabricates regexp with a single flag' do
          regexp = described_class.fabricate!('/something/i', fallback: true)

          expect(regexp).to eq Regexp.new('something', Regexp::IGNORECASE)
        end

        it 'fabricates regexp with multiple flags' do
          regexp = described_class.fabricate!('/something/im', fallback: true)

          expect(regexp).to eq Regexp.new('something', Regexp::IGNORECASE | Regexp::MULTILINE)
        end

        it 'fabricates regexp without flags' do
          regexp = described_class.fabricate!('/something/', fallback: true)

          expect(regexp).to eq Regexp.new('something')
        end
      end
    end

    context 'when regexp is a raw pattern' do
      it 'raises an error' do
        expect { described_class.fabricate!('some .* thing') }
          .to raise_error(RegexpError)
      end
    end
  end
end
