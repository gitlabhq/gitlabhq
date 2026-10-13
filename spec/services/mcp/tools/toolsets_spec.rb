# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mcp::Tools::Toolsets, feature_category: :mcp_server do
  describe '.parse' do
    subject(:parse) { described_class.parse(header_value) }

    context 'when the header is absent' do
      let(:header_value) { nil }

      it { is_expected.to be_nil }
    end

    context 'when the header is empty' do
      let(:header_value) { '' }

      it { is_expected.to be_nil }
    end

    context 'when the header holds only separators' do
      let(:header_value) { ' , , ' }

      it 'returns nil so callers fall back to the defaults' do
        expect(parse).to be_nil
      end
    end

    context 'with a single valid toolset' do
      let(:header_value) { 'ci' }

      it { is_expected.to eq(%w[ci]) }
    end

    context 'with several valid toolsets' do
      let(:header_value) { 'ci,wikis' }

      it { is_expected.to eq(%w[ci wikis]) }
    end

    context 'with surrounding whitespace' do
      let(:header_value) { '  ci , wikis  ' }

      it 'strips each name' do
        expect(parse).to eq(%w[ci wikis])
      end
    end

    context 'with mixed-case names' do
      let(:header_value) { 'CI,Wikis' }

      it 'matches names case-insensitively' do
        expect(parse).to eq(%w[ci wikis])
      end
    end

    context 'with an uppercase "all"' do
      let(:header_value) { 'ALL' }

      it 'returns every toolset' do
        expect(parse).to match_array(described_class::ALL.map(&:to_s))
      end
    end

    context 'with a repeated name' do
      let(:header_value) { 'ci,ci' }

      it 'keeps the duplicate for the caller to collapse' do
        expect(parse).to eq(%w[ci ci])
      end
    end

    context 'with the "all" pseudo-value' do
      let(:header_value) { 'all' }

      it 'returns every toolset' do
        expect(parse).to match_array(described_class::ALL.map(&:to_s))
      end
    end

    context 'when "all" is combined with a valid toolset' do
      let(:header_value) { 'all,ci' }

      it 'returns every toolset' do
        expect(parse).to match_array(described_class::ALL.map(&:to_s))
      end
    end

    context 'with an unknown toolset' do
      let(:header_value) { 'bogus' }

      it 'raises and names the offending value' do
        expect { parse }.to raise_error(ArgumentError, /Unknown toolsets: bogus/)
      end
    end

    context 'when an unknown toolset accompanies a valid one' do
      let(:header_value) { 'ci,bogus' }

      it 'raises for the unknown name only' do
        expect { parse }.to raise_error(ArgumentError, /Unknown toolsets: bogus/)
      end
    end

    context 'when an unknown toolset accompanies "all"' do
      let(:header_value) { 'all,bogus' }

      it 'raises rather than letting "all" mask the typo' do
        expect { parse }.to raise_error(ArgumentError, /Unknown toolsets: bogus/)
      end
    end
  end

  describe '.defaults' do
    it 'returns the default and always-on toolsets' do
      expect(described_class.defaults)
        .to match_array((described_class::DEFAULT + described_class::ALWAYS_ON).map(&:to_s))
    end

    it 'excludes opt-in toolsets' do
      expect(described_class.defaults).not_to include(*described_class::OPT_IN.map(&:to_s))
    end
  end
end
