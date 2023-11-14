# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ActivityPub::AcceptFollowService, feature_category: :integrations do
  let_it_be(:project) { create(:project, :public) }
  let_it_be_with_reload(:existing_subscription) do
    create(:activity_pub_releases_subscription, :inbox, project: project)
  end

  let(:service) { described_class.new(existing_subscription, 'http://localhost/my-project/releases') }

  describe '#execute' do
    context 'when third party server complies' do
      before do
        allow(Gitlab::HTTP).to receive(:post).and_return(true)
        service.execute
      end

      it 'sends an Accept activity' do
        expect(Gitlab::HTTP).to have_received(:post)
      end

      it 'updates subscription state to accepted' do
        expect(existing_subscription.reload.status).to eq 'accepted'
      end
    end

    context 'when there is an error with third party server' do
      before do
        allow(Gitlab::HTTP).to receive(:post).and_raise(Errno::ECONNREFUSED)
      end

      it 'raises a ThirdPartyError' do
        expect { service.execute }.to raise_error(ActivityPub::ThirdPartyError)
      end

      it 'does not update subscription state to accepted' do
        begin
          service.execute
        rescue StandardError
        end

        expect(existing_subscription.reload.status).to eq 'requested'
      end
    end

    context 'when subscription is already accepted' do
      before do
        allow(Gitlab::HTTP).to receive(:post).and_return(true)
        allow(existing_subscription).to receive(:accepted!).and_return(true)
        existing_subscription.status = :accepted
        service.execute
      end

      it 'does not send an Accept activity' do
        expect(Gitlab::HTTP).not_to have_received(:post)
      end

      it 'does not update subscription state' do
        expect(existing_subscription).not_to have_received(:accepted!)
      end
    end

    context 'when inbox has not been resolved' do
      before do
        allow(Gitlab::HTTP).to receive(:post).and_return(true)
        allow(existing_subscription).to receive(:accepted!).and_return(true)
      end

      it 'raises an error' do
        existing_subscription.subscriber_inbox_url = nil
        expect { service.execute }.to raise_error(ActivityPub::AcceptFollowService::MissingInboxURLError)
      end
    end
  end
end
