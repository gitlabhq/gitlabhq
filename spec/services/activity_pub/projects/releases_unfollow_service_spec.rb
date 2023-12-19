# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ActivityPub::Projects::ReleasesUnfollowService, feature_category: :release_orchestration do
  let_it_be(:project) { create(:project, :public) }
  let_it_be_with_reload(:existing_subscription) { create(:activity_pub_releases_subscription, project: project) }

  describe '#execute' do
    let(:service) { described_class.new(project, payload) }
    let(:payload) { nil }

    context 'with a valid payload' do
      let(:payload) do
        {
          '@context': 'https://www.w3.org/ns/activitystreams',
          id: 'https://example.com/new-actor#unfollow-1',
          type: 'Undo',
          actor: actor,
          object: {
            id: 'https://example.com/new-actor#follow-1',
            type: 'Follow',
            actor: actor,
            object: 'https://localhost/our/project/-/releases'
          }
        }.with_indifferent_access
      end

      let(:actor) { existing_subscription.subscriber_url }

      context 'when there is a subscription for this actor' do
        it 'deletes the subscription' do
          service.execute
          expect(ActivityPub::ReleasesSubscription.where(id: existing_subscription.id).first).to be_nil
        end

        it 'returns true' do
          expect(service.execute).to be_truthy
        end
      end

      context 'when there is no subscription for this actor' do
        before do
          allow(ActivityPub::ReleasesSubscription).to receive(:find_by_project_and_subscriber).and_return(nil)
        end

        it 'does not delete anything' do
          expect { service.execute }.not_to change { ActivityPub::ReleasesSubscription.count }
        end

        it 'returns true' do
          expect(service.execute).to be_truthy
        end
      end
    end

    shared_examples 'invalid unfollow request' do
      it 'does not delete anything' do
        expect { service.execute }.not_to change { ActivityPub::ReleasesSubscription.count }
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
          id: 'https://example.com/new-actor#unfollow-1',
          type: 'Undo',
          object: {
            id: 'https://example.com/new-actor#follow-1',
            type: 'Follow',
            object: 'https://localhost/our/project/-/releases'
          }
        }.with_indifferent_access
      end

      it_behaves_like 'invalid unfollow request'
    end

    context 'when actor is an object with no id attribute' do
      let(:payload) do
        {
          '@context': 'https://www.w3.org/ns/activitystreams',
          id: 'https://example.com/new-actor#unfollow-1',
          actor: { type: 'Person' },
          type: 'Undo',
          object: {
            id: 'https://example.com/new-actor#follow-1',
            type: 'Follow',
            actor: { type: 'Person' },
            object: 'https://localhost/our/project/-/releases'
          }
        }.with_indifferent_access
      end

      it_behaves_like 'invalid unfollow request'
    end

    context 'when actor is neither a string nor an object' do
      let(:payload) do
        {
          '@context': 'https://www.w3.org/ns/activitystreams',
          id: 'https://example.com/new-actor#unfollow-1',
          actor: 27.13,
          type: 'Undo',
          object: {
            id: 'https://example.com/new-actor#follow-1',
            type: 'Follow',
            actor: 27.13,
            object: 'https://localhost/our/project/-/releases'
          }
        }.with_indifferent_access
      end

      it_behaves_like 'invalid unfollow request'
    end

    context "when actor tries to delete someone else's subscription" do
      let(:payload) do
        {
          '@context': 'https://www.w3.org/ns/activitystreams',
          id: 'https://example.com/actor#unfollow-1',
          type: 'Undo',
          actor: 'https://example.com/nasty-actor',
          object: {
            id: 'https://example.com/actor#follow-1',
            type: 'Follow',
            actor: existing_subscription.subscriber_url,
            object: 'https://localhost/our/project/-/releases'
          }
        }.with_indifferent_access
      end

      it 'does not delete anything' do
        expect { service.execute }.not_to change { ActivityPub::ReleasesSubscription.count }
      end

      it 'returns true' do
        expect(service.execute).to be_truthy
      end
    end
  end
end
