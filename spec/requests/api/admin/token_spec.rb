# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Admin::Token, :aggregate_failures, feature_category: :system_access do
  shared_examples 'rejecting invalid requests with admin' do
    context 'with non-existing token' do
      let(:plaintext) { "#{personal_access_token.token}-non-existing" }

      it_behaves_like 'returning response status', :not_found
    end

    context 'with unsupported token type' do
      let(:plaintext) { 'unsupported' }

      it_behaves_like 'returning response status', :unprocessable_entity
    end
  end

  shared_examples 'rejecting requests with invalid or missing authorization' do
    context 'when the user is not an admin' do
      let(:api_user) { user }

      it_behaves_like 'returning response status', :forbidden
    end

    context 'without a user' do
      let(:api_user) { nil }

      it_behaves_like 'returning response status', :unauthorized
    end
  end

  shared_examples 'post_successful_interval_event_tracking' do
    it_behaves_like 'internal event tracking' do
      let(:event) { 'use_admin_token_api' }
      let(:user) { api_user }
      let(:namespace) { api_user.namespace }
      let(:project) { nil }
      subject(:track_event) { post_token }
    end
  end

  shared_examples 'delete_successful_interval_event_tracking' do
    it_behaves_like 'internal event tracking' do
      let(:event) { 'use_admin_token_api' }
      let(:user) { api_user }
      let(:namespace) { api_user.namespace }
      let(:project) { nil }
      subject(:track_event) { delete_token }
    end
  end

  let_it_be(:admin) { create(:admin, :with_namespace) }
  let_it_be(:project) { create(:project) }
  let_it_be(:group) { create(:group) }
  let_it_be(:url) { '/admin/token' }
  let(:api_user) { admin }
  let_it_be(:user) { create(:user, :with_namespace) }

  let_it_be(:project_bot) { create(:user, :project_bot) }
  let_it_be(:group_bot) { create(:user, :project_bot) }
  let_it_be(:project_member) { create(:project_member, source: project, user: project_bot) }
  let_it_be(:group_member) { create(:group_member, source: group, user: group_bot) }

  let(:personal_access_token) { create(:personal_access_token, user: user) }
  let(:project_access_token) { create(:personal_access_token, user: project_bot) }
  let(:group_access_token) { create(:personal_access_token, user: group_bot) }
  let(:group_deploy_token) { create(:deploy_token, :group, groups: [group]) }
  let(:project_deploy_token) { create(:deploy_token, :project, projects: [create(:project)]) }
  let(:oauth_application) { create(:oauth_application) }
  let(:cluster_agent_token) { create(:cluster_agent_token, token_encrypted: nil) }
  let(:runner_authentication_token) { create(:ci_runner, registration_type: :authenticated_user) }
  let(:impersonation_token) { create(:personal_access_token, :impersonation, user: user) }
  let_it_be(:ci_trigger) { create(:ci_trigger, project: project) }
  let(:ci_build) { create(:ci_build, status: :running) }
  let(:feature_flags_client) { create(:operations_feature_flags_client) }

  let(:plaintext) { nil }
  let(:params) { { token: plaintext } }

  describe 'POST /admin/token' do
    subject(:post_token) { post(api(url, api_user, admin_mode: true), params: params) }

    context 'when the user is an admin' do
      context 'with a valid token' do
        where(:token, :plaintext) do
          [
            [ref(:personal_access_token), lazy { personal_access_token.token }],
            [ref(:group_deploy_token), lazy { group_deploy_token.token }],
            [ref(:project_deploy_token), lazy { project_deploy_token.token }],
            [ref(:user), lazy { user.reload.feed_token }],
            [ref(:user), lazy { user.incoming_email_token }],
            [ref(:oauth_application), lazy { oauth_application.plaintext_secret }],
            [ref(:cluster_agent_token), lazy { cluster_agent_token.token }],
            [ref(:runner_authentication_token), lazy { runner_authentication_token.token }],
            [ref(:impersonation_token), lazy { impersonation_token.token }],
            [ref(:ci_trigger), lazy { ci_trigger.token }],
            [ref(:feature_flags_client), lazy { feature_flags_client.token }]
          ]
        end

        with_them do
          it 'returns info about the token' do
            post_token

            expect(response).to have_gitlab_http_status(:ok)
            expect(json_response['id']).to eq(token.id)
          end

          it_behaves_like 'post_successful_interval_event_tracking'
        end
      end

      context 'with valid CI job token' do
        let(:token) { ci_build }
        let(:plaintext) { ci_build.token }

        it 'contains a job' do
          post_token

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response['job']['id']).to eq(ci_build.id)
        end

        it_behaves_like 'post_successful_interval_event_tracking'
      end

      context 'with _gitlab_session' do
        let(:session_id) { 'session_id' }
        let(:plaintext) { "_gitlab_session=#{session_id}" }

        context 'with a valid session in ActiveSession' do
          before do
            rack_session = Rack::Session::SessionId.new(session_id)
            allow(ActiveSession).to receive(:sessions_from_ids)
              .with([rack_session.private_id]).and_return([{ 'warden.user.user.key' => [[user.id],
                user.authenticatable_salt] }])
          end

          it 'returns info about the token' do
            post_token

            expect(response).to have_gitlab_http_status(:ok)
            expect(json_response['id']).to eq(user.id)
          end

          it_behaves_like 'post_successful_interval_event_tracking'
        end

        context 'with an unknown session' do
          let(:session_id) { 'unknown' }

          it_behaves_like 'returning response status', :not_found
        end

        context 'with an empty session' do
          let(:session_id) { '' }

          it_behaves_like 'returning response status', :not_found
        end
      end

      it_behaves_like 'rejecting invalid requests with admin'
    end

    it_behaves_like 'rejecting requests with invalid or missing authorization'
  end

  describe 'DELETE /admin/token' do
    subject(:delete_token) { delete(api(url, api_user, admin_mode: true), params: params) }

    context 'when the user is an admin' do
      context 'when the token is valid' do
        context 'when the token can be revoked' do
          where(:token, :plaintext) do
            [
              [ref(:personal_access_token), lazy { personal_access_token.token }],
              [ref(:project_access_token), lazy { project_access_token.token }],
              [ref(:impersonation_token), lazy { impersonation_token.token }],
              [ref(:group_access_token), lazy { group_access_token.token }],
              [ref(:group_deploy_token), lazy { group_deploy_token.token }],
              [ref(:project_deploy_token), lazy { project_deploy_token.token }],
              [ref(:cluster_agent_token), lazy { cluster_agent_token.token }]
            ]
          end

          with_them do
            it 'revokes the token' do
              delete_token

              expect(response).to have_gitlab_http_status(:no_content)
              expect(token.reload.revoked?).to be_truthy
            end

            it_behaves_like 'delete_successful_interval_event_tracking'
          end
        end

        context 'when the token can be reset' do
          before do
            user.reload
          end

          where(:token, :plaintext_attribute, :changed_attribute) do
            [
              [ref(:user), :feed_token, :feed_token],
              [ref(:runner_authentication_token), :token, :token],
              [ref(:feature_flags_client), :token, :token],
              [ref(:oauth_application), :plaintext_secret, :secret]
            ]
          end

          with_them do
            let(:plaintext) { token.send(plaintext_attribute) }
            it 'resets the token' do
              expect { delete_token }.to change { token.reload.send(changed_attribute) }

              expect(response).to have_gitlab_http_status(:no_content)
            end

            it_behaves_like 'delete_successful_interval_event_tracking'
          end
        end
      end

      context 'when the token is an incoming email token' do
        let(:plaintext) { user.incoming_email_token }

        it 'resets the token' do
          expect { delete_token }.to change { user.reload.incoming_email_token }

          expect(response).to have_gitlab_http_status(:no_content)
        end

        it_behaves_like 'delete_successful_interval_event_tracking'
      end

      context 'when the token is a ci pipeline trigger token' do
        let(:plaintext) { ci_trigger.token }

        it 'expires the trigger token' do
          expect { delete_token }.to change { ci_trigger.reload.expired? }
          expect(response).to have_gitlab_http_status(:no_content)
        end

        context 'when expiring the token fails' do
          before do
            errors = ActiveModel::Errors.new(ci_trigger).tap { |e| e.add(:base, 'Some error') }
            allow(ci_trigger).to receive_messages(update: false, errors: errors)
            allow(::Ci::Trigger).to receive(:find_by_token).with(plaintext).and_return(ci_trigger)
          end

          it_behaves_like 'returning response status', :bad_request

          it 'returns the error message' do
            delete_token
            expect(response.body).to include('Some error')
          end
        end
      end

      context 'with _gitlab_session' do
        let(:session_id) { 'session_id' }
        let(:plaintext) { "_gitlab_session=#{session_id}" }

        context 'with a valid session in ActiveSession' do
          before do
            rack_session = Rack::Session::SessionId.new(session_id)
            allow(ActiveSession).to receive(:sessions_from_ids)
              .with([rack_session.private_id]).and_return([{ 'warden.user.user.key' => [[user.id],
                user.authenticatable_salt] }])
          end

          it 'deletes the session' do
            delete_token

            expect(response).to have_gitlab_http_status(:no_content)
          end

          it_behaves_like 'delete_successful_interval_event_tracking'
        end

        context 'with an unknown session' do
          let(:session_id) { 'unknown' }

          it_behaves_like 'returning response status', :not_found
        end

        context 'with an empty session' do
          let(:plaintext) { "_gitlab_session=" }

          it_behaves_like 'returning response status', :not_found
        end
      end

      it_behaves_like 'rejecting invalid requests with admin'
    end

    it_behaves_like 'rejecting requests with invalid or missing authorization'
  end
end
