# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::PersonalAccessTokens::SelfInformation, feature_category: :system_access do
  let(:path) { '/personal_access_tokens/self' }
  let(:token) { create(:personal_access_token, user: current_user) }

  let_it_be(:current_user) { create(:user) }

  describe 'DELETE /personal_access_tokens/self' do
    subject(:delete_token) { delete api(path, personal_access_token: token) }

    shared_examples 'revoking token succeeds' do
      it 'revokes token', :aggregate_failures do
        delete_token

        expect(response).to have_gitlab_http_status(:no_content)
        expect(token.reload).to be_revoked
      end
    end

    shared_examples 'revoking token denied' do |status|
      it 'cannot revoke token' do
        delete_token

        expect(response).to have_gitlab_http_status(status)
      end
    end

    context 'when current_user is an administrator', :enable_admin_mode do
      let(:current_user) { create(:admin) }

      it_behaves_like 'revoking token succeeds'

      context 'with impersonated token' do
        let(:token) { create(:personal_access_token, :impersonation, user: current_user) }

        it_behaves_like 'revoking token succeeds'
      end
    end

    context 'when current_user is not an administrator' do
      let(:current_user) { create(:user) }

      it_behaves_like 'revoking token succeeds'

      context 'with impersonated token' do
        let(:token) { create(:personal_access_token, :impersonation, user: current_user) }

        it_behaves_like 'revoking token denied', :bad_request
      end

      context 'with already revoked token' do
        let(:token) { create(:personal_access_token, :revoked, user: current_user) }

        it_behaves_like 'revoking token denied', :unauthorized
      end
    end

    Gitlab::Auth.all_available_scopes.each do |scope|
      context "with a '#{scope}' scoped token" do
        let(:token) { create(:personal_access_token, scopes: [scope], user: current_user) }

        it_behaves_like 'revoking token succeeds'
      end
    end
  end

  describe 'GET /personal_access_tokens/self' do
    Gitlab::Auth.all_available_scopes.each do |scope|
      context "with a '#{scope}' scoped token" do
        let(:token) { create(:personal_access_token, scopes: [scope], user: current_user) }

        it 'shows token info', :aggregate_failures do
          get api(path, personal_access_token: token)

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response['scopes']).to match_array([scope.to_s])
        end
      end
    end

    context 'when an ip is recently used' do
      let(:request_ip_address) { '192.168.1.2' }

      before do
        allow(Gitlab::IpAddressState).to receive(:current).and_return(request_ip_address)
      end

      it 'returns ips used' do
        get api(path, personal_access_token: token)

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response['last_used_ips']).to match_array([request_ip_address])
      end
    end

    context 'when several IP have been recently used' do
      let(:nb_ips) { 8 }
      let(:request_ips) { (1..nb_ips).map { |i| "192.168.#{i}.2" } }
      let(:time_travel_step) { 1.minute + 10.seconds }

      before do
        allow_next_instance_of(Gitlab::ExclusiveLease) do |instance|
          allow(instance).to receive(:try_obtain).and_return(true)
        end
      end

      it 'returns up to 5 most recent ones' do
        nb_ips.times do |i|
          travel_to (i * time_travel_step).from_now do
            allow(Gitlab::IpAddressState).to receive(:current).and_return(request_ips[i])
            get api(path, personal_access_token: token)

            expect(response).to have_gitlab_http_status(:ok)
            expect(json_response['last_used_ips']).to match_array(request_ips.first(i + 1).last(5))
          end
        end
      end
    end

    context 'when token is invalid' do
      it 'returns 401' do
        get api(path, personal_access_token: instance_double(PersonalAccessToken, token: 'invalidtoken'))

        expect(response).to have_gitlab_http_status(:unauthorized)
      end
    end

    context 'when the token is not PAT' do
      let(:token) { create(:oauth_access_token, scopes: ['api']) }

      it 'returns 400' do
        get api(path, oauth_access_token: token)

        expect(response).to have_gitlab_http_status(:bad_request)
        expect(json_response['message']).to eql(
          "400 Bad request - This endpoint requires token type to be a personal access token"
        )
      end
    end

    context 'when token is expired' do
      it 'returns 401' do
        token = create(:personal_access_token, expires_at: 1.day.ago, user: current_user)

        get api(path, personal_access_token: token)

        expect(response).to have_gitlab_http_status(:unauthorized)
      end
    end
  end

  describe 'GET /personal_access_tokens/self/associations' do
    let(:path) { '/personal_access_tokens/self/associations' }

    context 'when token is invalid' do
      it 'returns 401' do
        get api(path, personal_access_token: instance_double(PersonalAccessToken, token: 'invalidtoken'))

        expect(response).to have_gitlab_http_status(:unauthorized)
      end
    end

    context 'when token is valid' do
      context 'when token has no associations' do
        it 'returns empty arrays', :aggregate_failures do
          get api(path, personal_access_token: token)

          expect(json_response).to eq({ "groups" => [], "projects" => [] })
          expect(response).to have_gitlab_http_status(:success)
        end
      end

      context 'when token has associations' do
        before do
          group = create(:group, :private, name: "test_group", developers: current_user)
          sub_group = create(:group, :private, name: "test_subgroup", developers: current_user, parent: group)
          create(:project, :private, name: "test_project", maintainers: current_user, group: sub_group)
        end

        it 'returns associations', :aggregate_failures do
          get api(path, personal_access_token: token)

          expected_group_names = json_response["groups"].pluck("name")
          expect(expected_group_names).to match_array(%w[test_group test_subgroup])
          expect(response).to have_gitlab_http_status(:success)
        end

        it 'filters associations by min_access_level', :aggregate_failures do
          get api("#{path}?min_access_level=40", personal_access_token: token)

          expect(json_response["groups"]).to be_empty
          expect(json_response["projects"][0]["name"]).to eq("test_project")
          expect(response).to have_gitlab_http_status(:success)
        end
      end
    end
  end
end
