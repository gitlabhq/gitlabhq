# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Metrics::GlobalSearchSlis, feature_category: :global_search do
  using RSpec::Parameterized::TableSyntax

  describe '#initialize_slis!' do
    let(:api_endpoint_labels) do
      [a_hash_including(endpoint_id: 'GET /api/:version/search')]
    end

    let(:web_endpoint_labels) do
      [a_hash_including(endpoint_id: "SearchController#show")]
    end

    let(:all_endpoint_labels) do
      api_endpoint_labels + web_endpoint_labels
    end

    it 'initializes Apdex SLIs for global_search' do
      expect(Gitlab::Metrics::Sli::Apdex).to receive(:initialize_sli).with(
        :global_search,
        array_including(all_endpoint_labels)
      )

      described_class.initialize_slis!
    end

    it 'initializes ErrorRate SLIs for global_search' do
      expect(Gitlab::Metrics::Sli::ErrorRate).to receive(:initialize_sli).with(
        :global_search,
        array_including(all_endpoint_labels)
      )

      described_class.initialize_slis!
    end

    context "when initializeing for limited types" do
      where(:api, :web) do
        [true, false].repeated_permutation(2).to_a
      end

      with_them do
        it 'only initializes for the relevant endpoints', :aggregate_failures do
          allow(Gitlab::Metrics::Environment).to receive(:api?).and_return(api)
          allow(Gitlab::Metrics::Environment).to receive(:web?).and_return(web)
          allow(Gitlab::Metrics::Sli::Apdex).to receive(:initialize_sli)
          allow(Gitlab::Metrics::Sli::ErrorRate).to receive(:initialize_sli)

          described_class.initialize_slis!

          if api
            expect(Gitlab::Metrics::Sli::Apdex).to(
              have_received(:initialize_sli).with(:global_search, array_including(*api_endpoint_labels))
            )
            expect(Gitlab::Metrics::Sli::ErrorRate).to(
              have_received(:initialize_sli).with(:global_search, array_including(*api_endpoint_labels))
            )
          else
            expect(Gitlab::Metrics::Sli::Apdex).not_to(
              have_received(:initialize_sli).with(:global_search, array_including(*api_endpoint_labels))
            )
            expect(Gitlab::Metrics::Sli::ErrorRate).not_to(
              have_received(:initialize_sli).with(:global_search, array_including(*api_endpoint_labels))
            )
          end

          if web
            expect(Gitlab::Metrics::Sli::Apdex).to(
              have_received(:initialize_sli).with(:global_search, array_including(*web_endpoint_labels))
            )
            expect(Gitlab::Metrics::Sli::ErrorRate).to(
              have_received(:initialize_sli).with(:global_search, array_including(*web_endpoint_labels))
            )
          else
            expect(Gitlab::Metrics::Sli::Apdex).not_to(
              have_received(:initialize_sli).with(:global_search, array_including(*web_endpoint_labels))
            )
            expect(Gitlab::Metrics::Sli::ErrorRate).not_to(
              have_received(:initialize_sli).with(:global_search, array_including(*web_endpoint_labels))
            )
          end
        end
      end
    end
  end

  describe '#record_apdex' do
    before do
      allow(::Gitlab::ApplicationContext).to receive(:current_context_attribute).with(:caller_id).and_return('end')
    end

    where(:search_type, :code_search, :duration_target) do
      'basic'    | false | 8.812
      'basic'    | true  | 27.538
      'advanced' | false | 2.452
      'advanced' | true  | 15.52
      'zoekt'    | true  | 15.52
    end

    with_them do
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

    context 'when the search scope is merge_requests and the search type is basic' do
      it 'increments the global_search SLI as a success if the elapsed time is within the target' do
        expect(Gitlab::Metrics::Sli::Apdex[:global_search]).to receive(:increment).with(
          labels: {
            search_type: 'basic',
            search_level: 'global',
            search_scope: 'merge_requests',
            endpoint_id: 'end'
          },
          success: true
        )

        described_class.record_apdex(
          elapsed: 14,
          search_type: 'basic',
          search_level: 'global',
          search_scope: 'merge_requests'
        )
      end

      it 'increments the global_search SLI as a failure if the elapsed time is not within the target' do
        expect(Gitlab::Metrics::Sli::Apdex[:global_search]).to receive(:increment).with(
          labels: {
            search_type: 'basic',
            search_level: 'global',
            search_scope: 'merge_requests',
            endpoint_id: 'end'
          },
          success: false
        )

        described_class.record_apdex(
          elapsed: 16,
          search_type: 'basic',
          search_level: 'global',
          search_scope: 'merge_requests'
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
