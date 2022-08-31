# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Metrics::GlobalSearchSlis do
  using RSpec::Parameterized::TableSyntax

  before do
    stub_feature_flags(global_search_custom_slis: feature_flag_enabled)
  end

  describe '#initialize_slis!' do
    context 'when global_search_custom_slis feature flag is enabled' do
      let(:feature_flag_enabled) { true }

      it 'initializes Apdex SLI for global_search' do
        expect(Gitlab::Metrics::Sli::Apdex).to receive(:initialize_sli).with(
          :global_search,
          a_kind_of(Array)
        )

        described_class.initialize_slis!
      end
    end

    context 'when global_search_custom_slis feature flag is disabled' do
      let(:feature_flag_enabled) { false }

      it 'does not initialzie the Apdex SLI for global_search' do
        expect(Gitlab::Metrics::Sli::Apdex).not_to receive(:initialize_sli)

        described_class.initialize_slis!
      end
    end
  end

  describe '#record_apdex' do
    context 'when global_search_custom_slis feature flag is enabled' do
      let(:feature_flag_enabled) { true }

      where(:search_type, :code_search, :duration_target) do
        'basic'    | false | 7.031
        'basic'    | true  | 21.903
        'advanced' | false | 4.865
        'advanced' | true  | 13.546
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

    context 'when global_search_custom_slis feature flag is disabled' do
      let(:feature_flag_enabled) { false }

      it 'does not call increment on the apdex SLI' do
        expect(Gitlab::Metrics::Sli::Apdex[:global_search]).not_to receive(:increment)

        described_class.record_apdex(
          elapsed: 1,
          search_type: 'basic',
          search_level: 'global',
          search_scope: 'issues'
        )
      end
    end
  end
end
