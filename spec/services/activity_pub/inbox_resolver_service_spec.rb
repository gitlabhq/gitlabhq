# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ActivityPub::InboxResolverService, feature_category: :integrations do
  let_it_be(:project) { create(:project, :public) }
  let_it_be_with_reload(:existing_subscription) { create(:activity_pub_releases_subscription, project: project) }
  let(:service) { described_class.new(existing_subscription) }

  shared_examples 'third party error' do
    it 'raises a ThirdPartyError' do
      expect { service.execute }.to raise_error(ActivityPub::ThirdPartyError)
    end

    it 'does not update the subscription record' do
      begin
        service.execute
      rescue StandardError
      end

      expect(ActivityPub::ReleasesSubscription.last.subscriber_inbox_url).not_to eq 'https://example.com/user/inbox'
    end
  end

  describe '#execute' do
    context 'with successful HTTP request' do
      before do
        allow(Gitlab::HTTP).to receive(:get) { response }
      end

      let(:response) { instance_double(HTTParty::Response, body: body) }

      context 'with a JSON response' do
        let(:body) do
          {
            '@context': 'https://www.w3.org/ns/activitystreams',
            id: 'https://example.com/user',
            type: 'Person',
            **inbox,
            **entrypoints,
            outbox: 'https://example.com/user/outbox'
          }.to_json
        end

        let(:entrypoints) { {} }

        context 'with valid response' do
          let(:inbox) { { inbox: 'https://example.com/user/inbox' } }

          context 'without a shared inbox' do
            it 'updates only the inbox in the subscription record' do
              service.execute

              expect(ActivityPub::ReleasesSubscription.last.subscriber_inbox_url).to eq 'https://example.com/user/inbox'
              expect(ActivityPub::ReleasesSubscription.last.shared_inbox_url).to be_nil
            end
          end

          context 'with a shared inbox' do
            let(:entrypoints) { { entrypoints: { sharedInbox: 'https://example.com/shared-inbox' } } }

            it 'updates both the inbox and shared inbox in the subscription record' do
              service.execute

              expect(ActivityPub::ReleasesSubscription.last.subscriber_inbox_url).to eq 'https://example.com/user/inbox'
              expect(ActivityPub::ReleasesSubscription.last.shared_inbox_url).to eq 'https://example.com/shared-inbox'
            end
          end
        end

        context 'without inbox attribute' do
          let(:inbox) { {} }

          it_behaves_like 'third party error'
        end

        context 'with a non string inbox attribute' do
          let(:inbox) { { inbox: 27.13 } }

          it_behaves_like 'third party error'
        end
      end

      context 'with non JSON response' do
        let(:body) { '<div>woops</div>' }

        it_behaves_like 'third party error'
      end
    end

    context 'with http error' do
      before do
        allow(Gitlab::HTTP).to receive(:get).and_raise(Errno::ECONNREFUSED)
      end

      it_behaves_like 'third party error'
    end
  end
end
