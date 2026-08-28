# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MergeRequests::AfterCreateEventPublisher,
  :clean_gitlab_redis_shared_state,
  feature_category: :code_review_workflow do
  let_it_be(:merge_request) { create(:merge_request) }

  let(:redis_key) { "merge_requests:pending_after_create_publish:#{merge_request.id}" }

  subject(:publisher) { described_class.new(merge_request) }

  context 'when the merge_request_create_flow_trigger flag is disabled' do
    before do
      stub_feature_flags(merge_request_create_flow_trigger: false)
    end

    it 'does not defer, publish, or touch Redis' do
      publisher.defer_to_mergeability_check

      expect(Gitlab::Redis::SharedState.with { |redis| redis.get(redis_key) }).to be_nil
      expect { publisher.publish_deferred }.not_to publish_event(::MergeRequests::AfterCreateCloudEvent)
    end
  end

  describe '#publish_deferred' do
    context 'when the event was deferred' do
      before do
        publisher.defer_to_mergeability_check
      end

      it 'publishes MergeRequests::AfterCreateCloudEvent as the merge request author' do
        expect(::MergeRequests::AfterCreateCloudEvent).to receive(:build)
          .with(merge_request: merge_request, current_user: merge_request.author)
          .and_call_original

        expect { publisher.publish_deferred }
          .to publish_event(::MergeRequests::AfterCreateCloudEvent).with(
            merge_request_id: merge_request.id,
            merge_request_iid: merge_request.iid,
            project_id: merge_request.project_id
          )
      end

      it 'publishes at most once' do
        publisher.publish_deferred

        expect { publisher.publish_deferred }
          .not_to publish_event(::MergeRequests::AfterCreateCloudEvent)
      end

      it 'expires the flag after the configured TTL' do
        Gitlab::Redis::SharedState.with do |redis|
          ttl = redis.ttl(redis_key)

          expect(ttl).to be > 0
          expect(ttl).to be <= described_class::TTL.to_i
        end
      end

      it 'is scoped per merge request' do
        other_mr = create(:merge_request, :unique_branches, source_project: merge_request.source_project)

        expect { described_class.new(other_mr).publish_deferred }
          .not_to publish_event(::MergeRequests::AfterCreateCloudEvent)
      end
    end

    context 'when the event was not deferred' do
      it 'does not publish' do
        expect { publisher.publish_deferred }
          .not_to publish_event(::MergeRequests::AfterCreateCloudEvent)
      end
    end

    context 'when the merge request was prepared longer ago than the TTL' do
      let(:prepared_long_ago) do
        create(:merge_request, :unique_branches,
          source_project: merge_request.source_project,
          prepared_at: described_class::TTL.ago - 1.minute)
      end

      it 'does not reach Redis, so pushes after create cost nothing' do
        expect(Gitlab::Redis::SharedState).not_to receive(:with)

        expect { described_class.new(prepared_long_ago).publish_deferred }
          .not_to publish_event(::MergeRequests::AfterCreateCloudEvent)
      end
    end

    context 'when the merge request was prepared within the TTL' do
      let(:prepared_recently) do
        create(:merge_request, :unique_branches,
          source_project: merge_request.source_project,
          prepared_at: 1.minute.ago)
      end

      it 'still publishes' do
        other = described_class.new(prepared_recently)
        other.defer_to_mergeability_check

        expect { other.publish_deferred }
          .to publish_event(::MergeRequests::AfterCreateCloudEvent)
      end
    end
  end
end
