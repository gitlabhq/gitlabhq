# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Metrics::GlobalSearchSlis, feature_category: :global_search do
  using RSpec::Parameterized::TableSyntax

  describe '#initialize_slis!' do
    let(:api_endpoint_labels) do
      [a_hash_including(endpoint_id: 'GET /api/:version/search')]
    end

    let(:web_endpoint_labels) do
      [
        a_hash_including(endpoint_id: "SearchController#show"),
        a_hash_including(endpoint_id: "SearchController#count"),
        a_hash_including(endpoint_id: "SearchController#autocomplete")
      ]
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

    where(:search_type, :search_scope, :search_level, :valid) do
      'basic' | 'work_items' | 'global'  | true
      'basic' | 'blobs'      | 'project' | true
      'basic' | 'blobs'      | 'global'  | false
      'basic' | 'blobs'      | 'group'   | false
      'basic' | 'wiki_blobs' | 'global'  | false
      'basic' | 'commits'    | 'global'  | false
    end

    with_them do
      it 'initializes valid label combinations and excludes impossible ones' do
        if valid
          expect(Gitlab::Metrics::Sli::Apdex).to receive(:initialize_sli).with(
            :global_search, array_including(a_hash_including(
              search_type: search_type, search_scope: search_scope, search_level: search_level
            ))
          )
        else
          expect(Gitlab::Metrics::Sli::Apdex).not_to receive(:initialize_sli).with(
            :global_search, array_including(a_hash_including(
              search_type: search_type, search_scope: search_scope, search_level: search_level
            ))
          )
        end

        described_class.initialize_slis!
      end
    end

    context 'when initializing autocomplete labels' do
      before do
        allow(Gitlab::Metrics::Environment).to receive_messages(web?: true, api?: false)
      end

      it 'registers autocomplete as a single label combination' do
        expect(Gitlab::Metrics::Sli::Apdex).to receive(:initialize_sli).with(
          :global_search, array_including(a_hash_including(
            endpoint_id: 'SearchController#autocomplete',
            search_type: nil,
            search_level: nil,
            search_scope: nil
          ))
        )

        described_class.initialize_slis!
      end

      it 'registers autocomplete error rate as a single label combination' do
        expect(Gitlab::Metrics::Sli::ErrorRate).to receive(:initialize_sli).with(
          :global_search, array_including(a_hash_including(
            endpoint_id: 'SearchController#autocomplete',
            search_type: nil,
            search_level: nil,
            search_scope: nil
          ))
        )

        described_class.initialize_slis!
      end
    end

    context 'when initializing search types', unless: Gitlab.ee? do
      it 'does not include zoekt search type' do
        expect(Gitlab::Metrics::Sli::Apdex).not_to receive(:initialize_sli).with(
          :global_search, array_including(a_hash_including(search_type: 'zoekt'))
        )

        described_class.initialize_slis!
      end

      it 'does not include advanced search type' do
        expect(Gitlab::Metrics::Sli::Apdex).not_to receive(:initialize_sli).with(
          :global_search, array_including(a_hash_including(search_type: 'advanced'))
        )

        described_class.initialize_slis!
      end
    end

    context "when initializing for limited types" do
      where(:api, :web) do
        [true, false].repeated_permutation(2).to_a
      end

      with_them do
        it 'only initializes for the relevant endpoints', :aggregate_failures do
          allow(Gitlab::Metrics::Environment).to receive_messages(api?: api, web?: web)
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
      allow(Gitlab::AppJsonLogger).to receive(:info)
    end

    where(:search_type, :code_search, :duration_target) do
      'basic'    | false | 8.812
      'basic'    | true  | 27.538
      'advanced' | false | 2.452
      'advanced' | true  | 15.52
      'zoekt'    | true  | 15.52
      'unknown'  | false | 5
      nil        | false | 5
    end

    with_them do
      let(:search_scope) { code_search ? 'blobs' : 'work_items' }

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

        expect(Gitlab::AppJsonLogger).to receive(:info).with(
          message: "Global Search Apdex SLI",
          duration_s: duration,
          target_s: duration_target,
          success: true,
          search_type: search_type,
          search_level: 'global',
          search_scope: search_scope
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

        expect(Gitlab::AppJsonLogger).to receive(:info).with(
          message: "Global Search Apdex SLI",
          duration_s: duration,
          target_s: duration_target,
          success: false,
          search_type: search_type,
          search_level: 'global',
          search_scope: search_scope
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

        expect(Gitlab::AppJsonLogger).to receive(:info).with(
          message: "Global Search Apdex SLI",
          duration_s: 14,
          target_s: 15,
          success: true,
          search_type: 'basic',
          search_level: 'global',
          search_scope: 'merge_requests'
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
    before do
      allow(::Gitlab::ApplicationContext).to receive(:current_context_attribute).with(:caller_id).and_return('end')
      allow(Gitlab::AppJsonLogger).to receive(:info)
    end

    it 'calls increment on the error rate SLI and logs the error' do
      expect(Gitlab::Metrics::Sli::ErrorRate[:global_search]).to receive(:increment)

      expect(Gitlab::AppJsonLogger).to receive(:info).with(
        message: "Global Search Error Rate SLI",
        error: true,
        search_type: 'basic',
        search_level: 'global',
        search_scope: 'work_items'
      )

      described_class.record_error_rate(
        error: true,
        search_type: 'basic',
        search_level: 'global',
        search_scope: 'work_items'
      )
    end
  end

  describe '.search_scopes' do
    it 'returns all scope names from Search::Scopes' do
      result = described_class.send(:search_scopes)
      expect(result).to eq(::Search::Scopes.all_scope_names)
    end

    it 'includes expected scopes' do
      result = described_class.send(:search_scopes)
      expect(result).to include('blobs', 'merge_requests', 'projects', 'work_items')
    end
  end
end
