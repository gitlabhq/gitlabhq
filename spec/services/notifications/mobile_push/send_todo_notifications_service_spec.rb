# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Notifications::MobilePush::SendTodoNotificationsService, feature_category: :notifications do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project) }

  let(:todo) { create(:todo, user: user, project: project) }
  let(:client) { instance_double(::Gitlab::MobilePush::ApnsClient, close: nil) }
  let(:counter) { instance_double(Prometheus::Client::Counter, increment: nil) }
  let(:histogram) { instance_double(Prometheus::Client::Histogram, observe: nil) }

  before do
    allow(::Gitlab::MobilePush::ApnsClient).to receive(:new).and_return(client)
    allow(::Gitlab::ApplicationRateLimiter).to receive(:throttled?)
      .with(described_class::RATE_LIMIT_KEY, scope: anything)
      .and_return(false)
    allow(Gitlab::Metrics).to receive(:counter).and_call_original
    allow(Gitlab::Metrics).to receive(:counter)
      .with(:mobile_push_notifications_total, anything)
      .and_return(counter)
    allow(Gitlab::Metrics).to receive(:histogram).and_call_original
    allow(Gitlab::Metrics).to receive(:histogram)
      .with(:mobile_push_notification_delivery_seconds, anything, anything, anything)
      .and_return(histogram)
  end

  describe '#execute' do
    context 'when the todos no longer exist' do
      it 'skips and counts each missing todo' do
        expect(client).not_to receive(:push)

        described_class.new([non_existing_record_id]).execute

        expect(counter).to have_received(:increment).with(result: 'skipped_todo_resolved')
      end
    end

    context 'when a todo is no longer pending' do
      let(:todo) { create(:todo, :done, user: user, project: project) }

      it 'skips and counts the outcome' do
        expect(client).not_to receive(:push)

        described_class.new([todo.id]).execute

        expect(counter).to have_received(:increment).with(result: 'skipped_todo_resolved')
      end
    end

    context 'when the recipient is not an active user' do
      %i[blocked banned deactivated].each do |trait|
        it "does not push to a #{trait} user" do
          inactive_user = create(:user, trait)
          inactive_todo = create(:todo, user: inactive_user, project: project)
          create(:mobile_device_push_subscription, user: inactive_user)

          expect(client).not_to receive(:push)

          described_class.new([inactive_todo.id]).execute

          expect(counter).to have_received(:increment).with(result: 'skipped_user_inactive')
        end
      end
    end

    context 'when the feature flag is disabled for the user' do
      before do
        stub_feature_flags(mobile_push_notifications: false)
      end

      it 'skips and counts the outcome' do
        create(:mobile_device_push_subscription, user: user)

        expect(client).not_to receive(:push)

        described_class.new([todo.id]).execute

        expect(counter).to have_received(:increment).with(result: 'skipped_setting_disabled')
      end
    end

    context 'when the user has no push subscriptions' do
      it 'skips and counts the outcome' do
        expect(client).not_to receive(:push)

        described_class.new([todo.id]).execute

        expect(counter).to have_received(:increment).with(result: 'skipped_no_subscription')
      end
    end

    context 'when the user has push subscriptions' do
      let!(:subscription) { create(:mobile_device_push_subscription, user: user) }

      it 'pushes a full payload and records delivery metrics' do
        expect(client).to receive(:push) do |sub, payload|
          expect(sub).to eq(subscription)
          expect(payload).to be_a(::Gitlab::MobilePush::Payload)
          expect(payload).not_to be_id_only

          :delivered
        end

        described_class.new([todo.id]).execute

        expect(counter).to have_received(:increment).with(result: 'delivered')
        expect(histogram).to have_received(:observe).with({}, kind_of(Numeric))
      end

      it 'delivers every todo in the batch' do
        other_todo = create(:todo, :marked, user: user, project: project)

        expect(client).to receive(:push).twice.and_return(:delivered)

        described_class.new([todo.id, other_todo.id]).execute

        expect(counter).to have_received(:increment).with(result: 'delivered').twice
      end

      it 'returns batch tallies in the payload' do
        allow(client).to receive(:push).and_return(:delivered)

        response = described_class.new([todo.id]).execute

        expect(response).to be_success
        expect(response.payload).to eq(
          todo_count: 1,
          subscription_count: 1,
          results: { 'delivered' => 1 },
          apns_results: { 'delivered' => 1 }
        )
      end

      it 'sends an id_only payload to subscriptions in id_only mode' do
        id_only_subscription = create(:mobile_device_push_subscription, user: user, payload_mode: :id_only)

        expect(client).to receive(:push).with(subscription, anything).and_return(:delivered)
        expect(client).to receive(:push) do |sub, payload|
          expect(sub).to eq(id_only_subscription)
          expect(payload).to be_id_only

          :delivered
        end

        described_class.new([todo.id]).execute
      end

      it 'destroys the subscription and counts an eviction on a dead token' do
        expect(client).to receive(:push).with(subscription, anything).and_return(:bad_token)

        described_class.new([todo.id]).execute

        expect(Notifications::MobileDevicePushSubscription.exists?(subscription.id)).to be(false)
        expect(counter).to have_received(:increment).with(result: 'evicted')
      end

      it 'keeps the subscription and counts a failure on a transient error' do
        allow(client).to receive(:push).and_return(:failed)

        described_class.new([todo.id]).execute

        expect(Notifications::MobileDevicePushSubscription.exists?(subscription.id)).to be(true)
        expect(counter).to have_received(:increment).with(result: 'failed')
        expect(histogram).not_to have_received(:observe)
      end

      it 'counts an unconfigured APNs client separately' do
        allow(client).to receive(:push).and_return(:skipped)

        described_class.new([todo.id]).execute

        expect(counter).to have_received(:increment).with(result: 'skipped_not_configured')
      end

      it 'closes the client after the batch' do
        allow(client).to receive(:push).and_return(:delivered)

        described_class.new([todo.id]).execute

        expect(client).to have_received(:close)
      end

      context 'when the user exceeds the push rate limit', :clean_gitlab_redis_shared_state do
        before do
          allow(::Gitlab::ApplicationRateLimiter).to receive(:throttled?)
            .with(described_class::RATE_LIMIT_KEY, scope: [user])
            .and_return(true)
        end

        it 'sends one generic summary alert on the first breach' do
          expect(client).to receive(:push) do |sub, payload|
            expect(sub).to eq(subscription)
            expect(payload).to be_a(::Gitlab::MobilePush::SummaryPayload)
            expect(payload.collapse_id).to eq("summary-#{user.id}")

            :delivered
          end

          described_class.new([todo.id]).execute

          expect(counter).to have_received(:increment).with(result: 'rate_limited')
          expect(counter).to have_received(:increment).with(result: 'delivered')
        end

        it 'suppresses alerts once the summary was sent, while still counting them' do
          allow(client).to receive(:push).and_return(:delivered)
          described_class.new([todo.id]).execute

          other_todo = create(:todo, :marked, user: user, project: project)

          response = described_class.new([other_todo.id]).execute

          expect(response.payload).to eq(
            todo_count: 1,
            subscription_count: 1,
            results: { 'rate_limited' => 1 },
            apns_results: {}
          )
          expect(client).to have_received(:push).once
          expect(counter).to have_received(:increment).with(result: 'rate_limited').twice
        end
      end
    end
  end
end
