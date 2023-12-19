# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ActivityPub::Projects::ReleasesFollowService, feature_category: :release_orchestration do
  let_it_be(:project) { create(:project, :public) }
  let_it_be_with_reload(:existing_subscription) { create(:activity_pub_releases_subscription, project: project) }

  describe '#execute' do
    let(:service) { described_class.new(project, payload) }
    let(:payload) { nil }

    before do
      allow(ActivityPub::Projects::ReleasesSubscriptionWorker).to receive(:perform_async)
    end

    context 'with a valid payload' do
      let(:payload) do
        {
          '@context': 'https://www.w3.org/ns/activitystreams',
          id: 'https://example.com/new-actor#follow-1',
          type: 'Follow',
          actor: actor,
          object: 'https://localhost/our/project/-/releases'
        }.with_indifferent_access
      end

      let(:actor) { 'https://example.com/new-actor' }

      context 'when there is no subscription for that actor' do
        before do
          allow(ActivityPub::ReleasesSubscription).to receive(:find_by_project_and_subscriber).and_return(nil)
        end

        it 'sets the subscriber url' do
          service.execute
          expect(ActivityPub::ReleasesSubscription.last.subscriber_url).to eq 'https://example.com/new-actor'
        end

        it 'sets the payload' do
          service.execute
          expect(ActivityPub::ReleasesSubscription.last.payload).to eq payload
        end

        it 'sets the project' do
          service.execute
          expect(ActivityPub::ReleasesSubscription.last.project_id).to eq project.id
        end

        it 'saves the subscription' do
          expect { service.execute }.to change { ActivityPub::ReleasesSubscription.count }.by(1)
        end

        it 'queues the subscription job' do
          service.execute
          expect(ActivityPub::Projects::ReleasesSubscriptionWorker).to have_received(:perform_async)
        end

        it 'returns true' do
          expect(service.execute).to be_truthy
        end
      end

      context 'when there is already a subscription for that actor' do
        before do
          allow(ActivityPub::ReleasesSubscription).to receive(:find_by_project_and_subscriber) { existing_subscription }
        end

        it 'does not save the subscription' do
          expect { service.execute }.not_to change { ActivityPub::ReleasesSubscription.count }
        end

        it 'does not queue the subscription job' do
          service.execute
          expect(ActivityPub::Projects::ReleasesSubscriptionWorker).not_to have_received(:perform_async)
        end

        it 'returns true' do
          expect(service.execute).to be_truthy
        end
      end
    end

    shared_examples 'invalid follow request' do
      it 'does not save the subscription' do
        expect { service.execute }.not_to change { ActivityPub::ReleasesSubscription.count }
      end

      it 'does not queue the subscription job' do
        service.execute
        expect(ActivityPub::Projects::ReleasesSubscriptionWorker).not_to have_received(:perform_async)
      end

      it 'sets an error' do
        service.execute
        expect(service.errors).not_to be_empty
      end

      it 'returns false' do
        expect(service.execute).to be_falsey
      end
    end

    context 'when actor is missing' do
      let(:payload) do
        {
          '@context': 'https://www.w3.org/ns/activitystreams',
          id: 'https://example.com/new-actor',
          type: 'Follow',
          object: 'https://localhost/our/project/-/releases'
        }.with_indifferent_access
      end

      it_behaves_like 'invalid follow request'
    end

    context 'when actor is an object with no id attribute' do
      let(:payload) do
        {
          '@context': 'https://www.w3.org/ns/activitystreams',
          id: 'https://example.com/new-actor',
          type: 'Follow',
          actor: { type: 'Person' },
          object: 'https://localhost/our/project/-/releases'
        }.with_indifferent_access
      end

      it_behaves_like 'invalid follow request'
    end

    context 'when actor is neither a string nor an object' do
      let(:payload) do
        {
          '@context': 'https://www.w3.org/ns/activitystreams',
          id: 'https://example.com/new-actor',
          type: 'Follow',
          actor: 27.13,
          object: 'https://localhost/our/project/-/releases'
        }.with_indifferent_access
      end

      it_behaves_like 'invalid follow request'
    end
  end
end
