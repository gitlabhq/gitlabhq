# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Analytics::GroupFetcher, :silence_stdout, feature_category: :service_ping do
  let(:stage_data) do
    <<~YAML
      stages:
        analyze:
          section: analytics
          groups:
            analytics_instrumentation:
        secure:
          section: security
          groups:
            static_analysis:
            dynamic_analysis:
    YAML
  end

  let(:response) { instance_double(HTTParty::Response, success?: true, body: stage_data) }

  around do |example|
    described_class.instance_variable_set(:@groups, nil)
    example.run
    described_class.instance_variable_set(:@groups, nil)
  end

  before do
    allow(Gitlab::HTTP).to receive(:get).and_return(response)
  end

  context 'when online' do
    describe '.group_unknown?' do
      it 'returns false for known groups' do
        expect(described_class.group_unknown?('analytics_instrumentation')).to be_falsy
      end

      it 'returns true for unknown groups' do
        expect(described_class.group_unknown?('unknown')).to be_truthy
      end
    end

    describe '.stage_text' do
      it 'returns the stage name for known groups' do
        expect(described_class.stage_text('analytics_instrumentation')).to eq('analyze')
      end

      it 'returns empty string for unknown group' do
        expect(described_class.stage_text('unknown')).to eq('')
      end
    end

    describe '.section_text' do
      it 'returns the section name for known groups' do
        expect(described_class.section_text('analytics_instrumentation')).to eq('analytics')
      end

      it 'returns empty string for unknown group' do
        expect(described_class.section_text('unknown')).to eq('')
      end
    end
  end

  context 'when offline' do
    before do
      allow(Gitlab::HTTP).to receive(:get).and_raise(Gitlab::HTTP_V2::BlockedUrlError)
    end

    describe '.group_unknown?' do
      it 'returns false for known groups' do
        expect(described_class.group_unknown?('analytics_instrumentation')).to be_falsy
      end

      it 'returns false for unknown group' do
        expect(described_class.group_unknown?('unknown')).to be_falsy
      end
    end

    describe '.stage_text' do
      it 'returns empty string for known groups' do
        expect(described_class.stage_text('analytics_instrumentation')).to eq('')
      end

      it 'returns empty string for unknown groups' do
        expect(described_class.stage_text('unknown')).to eq('')
      end
    end

    describe '.section_text' do
      it 'returns empty string for known groups' do
        expect(described_class.section_text('analytics_instrumentation')).to eq('')
      end

      it 'returns empty string for unknown groups' do
        expect(described_class.section_text('unknown')).to eq('')
      end
    end
  end
end
