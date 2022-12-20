# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Metrics::GlobalSearchSlis do
  using RSpec::Parameterized::TableSyntax

  describe '#initialize_slis!' do
    it 'initializes Apdex SLIs for global_search' do
      expect(Gitlab::Metrics::Sli::Apdex).to receive(:initialize_sli).with(
        :global_search,
        a_kind_of(Array)
      )

      described_class.initialize_slis!
    end

    it 'initializes ErrorRate SLIs for global_search' do
      expect(Gitlab::Metrics::Sli::ErrorRate).to receive(:initialize_sli).with(
        :global_search,
        a_kind_of(Array)
      )

      described_class.initialize_slis!
    end
  end

  describe '#record_apdex' do
    where(:search_type, :code_search, :duration_target) do
      'basic'    | false | 8.812
      'basic'    | true  | 27.538
      'advanced' | false | 2.452
      'advanced' | true  | 15.52
    end

    with_them do
      before do
        allow(::Gitlab::ApplicationContext).to receive(:current_context_attribute).with(:caller_id).and_return('end')
      end

      let(:search_scope) { code_search ? 'blobs' : 'issues' }

      it 'increments the global_search SLI as a success if the elapsed time is within the target' do
        duration = duration_target - 0.1

        expect(Gitlab::Metrics::Sli::Apdex[:global_search]).to receive(:increment).with(
          labels: {
            search_type: search_type,
            search_level: 'global',
            search_scope: search_scope,
            endpoint_id: 'end'
          },
          success: true
        )

        described_class.record_apdex(
          elapsed: duration,
          search_type: search_type,
          search_level: 'global',
          search_scope: search_scope
        )
      end

      it 'increments the global_search SLI as a failure if the elapsed time is not within the target' do
        duration = duration_target + 0.1

        expect(Gitlab::Metrics::Sli::Apdex[:global_search]).to receive(:increment).with(
          labels: {
            search_type: search_type,
            search_level: 'global',
            search_scope: search_scope,
            endpoint_id: 'end'
          },
          success: false
        )

        described_class.record_apdex(
          elapsed: duration,
          search_type: search_type,
          search_level: 'global',
          search_scope: search_scope
        )
      end
    end
  end

  describe '#record_error_rate' do
    it 'calls increment on the error rate SLI' do
      expect(Gitlab::Metrics::Sli::ErrorRate[:global_search]).to receive(:increment)

      described_class.record_error_rate(
        error: true,
        search_type: 'basic',
        search_level: 'global',
        search_scope: 'issues'
      )
    end
  end
end
