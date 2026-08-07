# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::MobilePushSubscriptions, feature_category: :notifications do
  let_it_be(:user) { create(:user) }
  let_it_be(:other_user) { create(:user) }

  let(:device_token) { SecureRandom.hex(32) }
  let(:path) { '/user/push_subscriptions' }

  describe 'POST /user/push_subscriptions' do
    let(:params) { { device_token: device_token } }

    it_behaves_like 'authorizing granular token permissions', :create_mobile_push_subscription,
      expected_success_status: :created do
      let(:boundary_object) { :user }
      let(:request) { post api(path, personal_access_token: pat), params: params }
    end

    context 'when unauthenticated' do
      it 'returns 401' do
        post api(path), params: params

        expect(response).to have_gitlab_http_status(:unauthorized)
      end
    end

    context 'when the feature flag is disabled' do
      before do
        stub_feature_flags(mobile_push_registration_api: false)
      end

      it 'returns 404' do
        post api(path, user), params: params

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    it 'registers the device and returns 201 with id and created_at' do
      expect do
        post api(path, user), params: params.merge(
          apns_environment: 'sandbox',
          bundle_id: 'com.gitlab-mobile.app',
          device_name: 'iPhone 17 Pro',
          app_version: '1.2.3',
          locale: 'de',
          payload_mode: 'id_only'
        )
      end.to change { user.mobile_device_push_subscriptions.count }.by(1)

      expect(response).to have_gitlab_http_status(:created)
      expect(json_response.keys).to contain_exactly('id', 'created_at')

      subscription = user.mobile_device_push_subscriptions.order(:id).last
      expect(subscription.device_token).to eq(device_token)
      expect(subscription).to be_apns_sandbox
      expect(subscription).to be_ios
      expect(subscription.bundle_identifier).to eq('com.gitlab-mobile.app')
      expect(subscription.device_name).to eq('iPhone 17 Pro')
      expect(subscription.app_version).to eq('1.2.3')
      expect(subscription.locale).to eq('de')
      expect(subscription).to be_id_only_payload
      expect(subscription.last_seen_at).to be_present
    end

    it 'upserts the existing subscription for the same token and environment' do
      existing = create(
        :mobile_device_push_subscription,
        user: user,
        device_token: device_token,
        last_seen_at: 1.day.ago
      )

      expect do
        post api(path, user), params: params.merge(app_version: '9.9.9')
      end.not_to change { Notifications::MobileDevicePushSubscription.count }

      expect(response).to have_gitlab_http_status(:created)
      expect(json_response['id']).to eq(existing.id)

      existing.reload
      expect(existing.app_version).to eq('9.9.9')
      expect(existing.last_seen_at).to be > 1.hour.ago
    end

    it 'preserves stored attributes omitted from a re-registration' do
      existing = create(
        :mobile_device_push_subscription,
        user: user,
        device_token: device_token,
        payload_mode: :id_only
      )

      post api(path, user), params: params

      expect(response).to have_gitlab_http_status(:created)
      expect(existing.reload).to be_id_only_payload
    end

    it 'reassigns a token registered by another user' do
      existing = create(:mobile_device_push_subscription, user: other_user, device_token: device_token)

      post api(path, user), params: params

      expect(response).to have_gitlab_http_status(:created)
      expect(json_response['id']).to eq(existing.id)
      expect(existing.reload.user).to eq(user)
      expect(other_user.mobile_device_push_subscriptions).to be_empty
    end

    context 'when the user is blocked' do
      it 'is rejected by authentication' do
        blocked_user = create(:user, :blocked)

        post api(path, blocked_user), params: params

        expect(response).to have_gitlab_http_status(:forbidden)
        expect(json_response['message']).to include('Your account has been blocked')
        expect(blocked_user.mobile_device_push_subscriptions).to be_empty
      end
    end

    it 'returns 400 when the user reached the subscription cap' do
      stub_const('Notifications::MobileDevicePushSubscription::MAX_SUBSCRIPTIONS_PER_USER', 1)
      create(:mobile_device_push_subscription, user: user)

      expect do
        post api(path, user), params: params
      end.not_to change { Notifications::MobileDevicePushSubscription.count }

      expect(response).to have_gitlab_http_status(:bad_request)
      expect(json_response['message']['base'])
        .to include('cannot have more than 1 push subscriptions per user')
    end

    it 'returns 400 when a reassignment is blocked by the new user cap' do
      stub_const('Notifications::MobileDevicePushSubscription::MAX_SUBSCRIPTIONS_PER_USER', 1)
      existing = create(:mobile_device_push_subscription, user: other_user, device_token: device_token)
      create(:mobile_device_push_subscription, user: user)

      post api(path, user), params: params

      expect(response).to have_gitlab_http_status(:bad_request)
      expect(json_response['message']['base'])
        .to include('cannot have more than 1 push subscriptions per user')
      expect(existing.reload.user).to eq(other_user)
    end

    it 'returns 400 for a token that is not hexadecimal' do
      post api(path, user), params: { device_token: 'not-a-hex-token!' }

      expect(response).to have_gitlab_http_status(:bad_request)
    end

    it 'returns 400 for an unknown apns_environment' do
      post api(path, user), params: params.merge(apns_environment: 'staging')

      expect(response).to have_gitlab_http_status(:bad_request)
    end
  end

  describe 'DELETE /user/push_subscriptions' do
    let(:params) { { device_token: device_token } }

    context 'when unauthenticated' do
      it 'returns 401' do
        delete api(path), params: params

        expect(response).to have_gitlab_http_status(:unauthorized)
      end
    end

    context 'when the feature flag is disabled' do
      before do
        stub_feature_flags(mobile_push_registration_api: false)
      end

      it 'returns 404' do
        create(:mobile_device_push_subscription, user: user, device_token: device_token)

        delete api(path, user), params: params

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    it_behaves_like 'authorizing granular token permissions', :delete_mobile_push_subscription,
      expected_success_status: :no_content do
      let(:boundary_object) { :user }
      let(:request) { delete api(path, personal_access_token: pat), params: params }

      before do
        create(:mobile_device_push_subscription, user: user, device_token: device_token)
      end
    end

    it 'destroys the subscriptions with that token and returns 204' do
      create(:mobile_device_push_subscription, user: user, device_token: device_token)
      create(:mobile_device_push_subscription, :sandbox, user: user, device_token: device_token)

      expect do
        delete api(path, user), params: params
      end.to change { user.mobile_device_push_subscriptions.count }.by(-2)

      expect(response).to have_gitlab_http_status(:no_content)
    end

    it "does not destroy another user's subscription" do
      other_subscription = create(
        :mobile_device_push_subscription,
        :sandbox,
        user: other_user,
        device_token: device_token
      )
      create(:mobile_device_push_subscription, user: user, device_token: device_token)

      delete api(path, user), params: params

      expect(response).to have_gitlab_http_status(:no_content)
      expect(Notifications::MobileDevicePushSubscription.exists?(other_subscription.id)).to be(true)
    end

    it 'returns 404 when the user has no subscription with that token' do
      delete api(path, user), params: params

      expect(response).to have_gitlab_http_status(:not_found)
    end

    it 'returns 400 when the device token is missing' do
      delete api(path, user)

      expect(response).to have_gitlab_http_status(:bad_request)
    end
  end
end
