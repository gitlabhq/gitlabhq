# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Gitlab::Ci::Reports::Security::Scan, feature_category: :vulnerability_management do
  describe '#initialize' do
    subject { described_class.new(params.with_indifferent_access) }

    let(:params) do
      {
        status: 'success',
        type: 'dependency-scanning',
        start_time: 'placeholer',
        end_time: 'placholder'
      }
    end

    context 'when all params are given' do
      it 'initializes an instance' do
        expect(subject).to have_attributes(
          status: 'success',
          type: 'dependency-scanning',
          start_time: 'placeholer',
          end_time: 'placholder',
          partial_scan_mode: nil,
          git_strategy: nil
        )
      end
    end

    context 'when partial scan' do
      let(:params) do
        {
          status: 'success',
          type: 'dependency-scanning',
          start_time: 'placeholer',
          end_time: 'placholder',
          partial_scan: {
            mode: 'differential'
          }
        }
      end

      it 'sets partial_scan_mode attribute' do
        expect(subject).to have_attributes(
          partial_scan_mode: 'differential'
        )
      end
    end

    context 'when the observability events report a git strategy' do
      let(:params) do
        {
          type: 'secret_detection',
          observability: {
            events: [
              { event: 'collect_secrets_analyzer_ruleset_adoption_metrics_from_pipeline', custom_ruleset: false },
              { event: 'collect_secrets_analyzer_scan_metrics_from_pipeline', git_strategy: 'FetchRange' }
            ]
          }
        }
      end

      it 'sets git_strategy from the event that has one' do
        expect(subject.git_strategy).to eq('FetchRange')
      end
    end

    context 'when the observability events are malformed' do
      let(:params) { { type: 'secret_detection', observability: { events: 'unexpected' } } }

      it 'does not set git_strategy' do
        expect(subject.git_strategy).to be_nil
      end
    end

    describe '#to_hash' do
      subject { described_class.new(params.with_indifferent_access).to_hash }

      it 'returns expected hash' do
        is_expected.to eq(
          {
            status: 'success',
            type: 'dependency-scanning',
            start_time: 'placeholer',
            end_time: 'placholder'
          }
        )
      end
    end
  end
end
