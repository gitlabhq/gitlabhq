# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Auth::RequestAuthenticator, feature_category: :system_access do
  include DependencyProxyHelpers

  let(:env) do
    {
      'rack.input' => '',
      'REQUEST_METHOD' => 'GET'
    }
  end

  let(:request) { ActionDispatch::Request.new(env) }

  subject(:request_authenticator) { described_class.new(request) }

  describe '#user' do
    let_it_be(:sessionless_user) { build(:user) }
    let_it_be(:session_user) { build(:user) }

    it 'returns sessionless user first' do
      allow_next_instance_of(described_class) do |instance|
        allow(instance).to receive(:find_sessionless_user).and_return(sessionless_user)
        allow(instance).to receive(:find_user_from_warden).and_return(session_user)
      end

      expect(subject.user([:api])).to eq sessionless_user
    end

    it 'returns session user if no sessionless user found' do
      allow_any_instance_of(described_class).to receive(:find_user_from_warden).and_return(session_user)

      expect(subject.user([:api])).to eq session_user
    end

    it 'returns nil if no user found' do
      expect(subject.user([:api])).to be_blank
    end

    it 'bubbles up exceptions' do
      allow_any_instance_of(described_class).to receive(:find_user_from_warden).and_raise(Gitlab::Auth::UnauthorizedError)
    end
  end

  describe '#can_sign_in_bot?' do
    context 'the user is nil' do
      it { is_expected.not_to be_can_sign_in_bot(nil) }
    end

    context 'the user is a bot, but for a web request' do
      let(:user) { build(:user, :project_bot) }

      it { is_expected.not_to be_can_sign_in_bot(user) }
    end

    context 'the user is a service account, but for a web request' do
      let_it_be(:user) { build(:user, :service_account) }

      it { is_expected.not_to be_can_sign_in_bot(user) }
    end

    context 'the user is a regular user, for an API request' do
      let(:user) { build(:user) }

      before do
        env['SCRIPT_NAME'] = '/api/some_resource'
      end

      it { is_expected.not_to be_can_sign_in_bot(user) }
    end

    context 'the user is a project bot, for an API request' do
      let(:user) { build(:user, :project_bot) }

      before do
        env['SCRIPT_NAME'] = '/api/some_resource'
      end

      it { is_expected.to be_can_sign_in_bot(user) }
    end

    context 'the user is a service account, for an API request' do
      let_it_be(:user) { build(:user, :service_account) }

      before do
        env['SCRIPT_NAME'] = '/api/some_resource'
      end

      it { is_expected.to be_can_sign_in_bot(user) }
    end
  end

  describe '#find_authenticated_requester' do
    let_it_be(:api_user) { create(:user) }
    let_it_be(:deploy_token_user) { create(:user) }

    it 'returns the deploy token if it exists' do
      allow_next_instance_of(described_class) do |authenticator|
        expect(authenticator).to receive(:deploy_token_from_request).and_return(deploy_token_user)
        allow(authenticator).to receive(:user).and_return(nil)
      end

      expect(subject.find_authenticated_requester([:api])).to eq deploy_token_user
    end

    it 'returns the user id if it exists' do
      allow_next_instance_of(described_class) do |authenticator|
        allow(authenticator).to receive(:deploy_token_from_request).and_return(deploy_token_user)
        expect(authenticator).to receive(:user).and_return(api_user)
      end

      expect(subject.find_authenticated_requester([:api])).to eq api_user
    end

    it 'rerturns nil if no match is found' do
      allow_next_instance_of(described_class) do |authenticator|
        expect(authenticator).to receive(:deploy_token_from_request).and_return(nil)
        expect(authenticator).to receive(:user).and_return(nil)
      end

      expect(subject.find_authenticated_requester([:api])).to eq nil
    end
  end

  describe '#find_sessionless_user' do
    let_it_be(:dependency_proxy_user) { build(:user) }
    let_it_be(:access_token_user) { build(:user) }
    let_it_be(:feed_token_user) { build(:user) }
    let_it_be(:static_object_token_user) { build(:user) }
    let_it_be(:job_token_user) { build(:user) }
    let_it_be(:lfs_token_user) { build(:user) }
    let_it_be(:basic_auth_access_token_user) { build(:user) }
    let_it_be(:basic_auth_password_user) { build(:user) }

    it 'raises if the request format is unknown' do
      expect { request_authenticator.find_sessionless_user(:invalid_request_format) }
        .to raise_error(ArgumentError, "Unknown request format")
    end

    it 'returns dependency_proxy user first' do
      allow_any_instance_of(described_class).to receive(:find_user_from_dependency_proxy_token)
                                                  .and_return(dependency_proxy_user)

      allow_any_instance_of(described_class).to receive(:find_user_from_web_access_token).and_return(access_token_user)

      expect(subject.find_sessionless_user(:api)).to eq dependency_proxy_user
    end

    it 'returns access_token user if no dependency_proxy user found' do
      allow_any_instance_of(described_class).to receive(:find_user_from_web_access_token)
                                                  .with(anything, scopes: [:api, :read_api])
                                                  .and_return(access_token_user)

      allow_any_instance_of(described_class).to receive(:find_user_from_feed_token).and_return(feed_token_user)

      expect(subject.find_sessionless_user(:api)).to eq access_token_user
    end

    it 'returns feed_token user if no access_token user found' do
      allow_any_instance_of(described_class).to receive(:find_user_from_feed_token).and_return(feed_token_user)

      expect(subject.find_sessionless_user(:api)).to eq feed_token_user
    end

    it 'returns static_object_token user if no feed_token user found' do
      allow_any_instance_of(described_class)
        .to receive(:find_user_from_static_object_token)
        .and_return(static_object_token_user)

      expect(subject.find_sessionless_user(:api)).to eq static_object_token_user
    end

    it 'returns job_token user if no static_object_token user found' do
      allow_any_instance_of(described_class)
        .to receive(:find_user_from_job_token)
        .and_return(job_token_user)

      expect(subject.find_sessionless_user(:api)).to eq job_token_user
    end

    it 'returns nil even if basic_auth_access_token is available' do
      allow_any_instance_of(described_class)
        .to receive(:find_user_from_personal_access_token)
        .and_return(basic_auth_access_token_user)

      expect(subject.find_sessionless_user(:api)).to be_nil
    end

    it 'returns nil even if find_user_from_lfs_token is available' do
      allow_any_instance_of(described_class)
        .to receive(:find_user_from_lfs_token)
        .and_return(lfs_token_user)

      expect(subject.find_sessionless_user(:api)).to be_nil
    end

    it 'returns nil if no user found' do
      expect(subject.find_sessionless_user(:api)).to be_nil
    end

    context 'in an API request' do
      before do
        env['SCRIPT_NAME'] = '/api/v4/projects'
      end

      it 'returns basic_auth_access_token user if no job_token_user found' do
        allow_any_instance_of(described_class)
          .to receive(:find_user_from_personal_access_token)
          .and_return(basic_auth_access_token_user)

        expect(subject.find_sessionless_user(:api)).to eq basic_auth_access_token_user
      end
    end

    context 'in a Git request' do
      before do
        env['SCRIPT_NAME'] = '/group/project.git/info/refs'
      end

      it 'returns lfs_token user if no job_token user found' do
        allow_any_instance_of(described_class)
          .to receive(:find_user_from_lfs_token)
          .and_return(lfs_token_user)

        expect(subject.find_sessionless_user(nil)).to eq lfs_token_user
      end

      it 'returns basic_auth_access_token user if no lfs_token user found' do
        allow_any_instance_of(described_class)
          .to receive(:find_user_from_personal_access_token)
          .and_return(basic_auth_access_token_user)

        expect(subject.find_sessionless_user(nil)).to eq basic_auth_access_token_user
      end

      it 'returns basic_auth_access_password user if no basic_auth_access_token user found' do
        allow_any_instance_of(described_class)
          .to receive(:find_user_from_basic_auth_password)
          .and_return(basic_auth_password_user)

        expect(subject.find_sessionless_user(nil)).to eq basic_auth_password_user
      end

      it 'returns nil if no user found' do
        expect(subject.find_sessionless_user(nil)).to be_blank
      end
    end

    it 'rescue Gitlab::Auth::AuthenticationError exceptions' do
      allow_any_instance_of(described_class).to receive(:find_user_from_web_access_token).and_raise(Gitlab::Auth::UnauthorizedError)

      expect(subject.find_sessionless_user(:api)).to be_blank
    end

    context 'dependency proxy' do
      let_it_be(:dependency_proxy_user) { create(:user) }

      let(:token) { build_jwt(dependency_proxy_user).encoded }
      let(:authenticator) { described_class.new(request) }

      subject { authenticator.find_sessionless_user(:api) }

      before do
        env['SCRIPT_NAME'] = accessed_path
        env['HTTP_AUTHORIZATION'] = "Bearer #{token}"
      end

      shared_examples 'identifying dependency proxy urls properly with' do |user_type|
        context 'with pulling a manifest' do
          let(:accessed_path) { '/v2/group1/dependency_proxy/containers/alpine/manifests/latest' }

          it { is_expected.to eq(dependency_proxy_user) } if user_type == :user
          it { is_expected.to eq(nil) } if user_type == :no_user
        end

        context 'with pulling a blob' do
          let(:accessed_path) { '/v2/group1/dependency_proxy/containers/alpine/blobs/sha256:a0d0a0d46f8b52473982a3c466318f479767577551a53ffc9074c9fa7035982e' }

          it { is_expected.to eq(dependency_proxy_user) } if user_type == :user
          it { is_expected.to eq(nil) } if user_type == :no_user
        end

        context 'with any other path' do
          let(:accessed_path) { '/foo/bar' }

          it { is_expected.to eq(nil) }
        end
      end

      context 'with a user' do
        it_behaves_like 'identifying dependency proxy urls properly with', :user

        context 'with an invalid id' do
          let(:token) { build_jwt { |jwt| jwt['user_id'] = 'this_is_not_a_user' } }

          it_behaves_like 'identifying dependency proxy urls properly with', :no_user
        end
      end

      context 'with a deploy token' do
        let_it_be(:dependency_proxy_user) { create(:deploy_token) }

        it_behaves_like 'identifying dependency proxy urls properly with', :no_user
      end

      context 'with no jwt token' do
        let(:token) { nil }

        it_behaves_like 'identifying dependency proxy urls properly with', :no_user
      end

      context 'with an expired jwt token' do
        let(:token) { build_jwt(dependency_proxy_user).encoded }
        let(:accessed_path) { '/v2/group1/dependency_proxy/containers/alpine/manifests/latest' }

        it 'returns nil' do
          travel_to(Time.zone.now + Auth::DependencyProxyAuthenticationService.token_expire_at + 1.minute) do
            expect(subject).to eq(nil)
          end
        end
      end
    end
  end

  describe '#find_personal_access_token_from_http_basic_auth' do
    let_it_be(:personal_access_token) { create(:personal_access_token) }
    let_it_be(:user) { personal_access_token.user }

    before do
      allow(subject).to receive(:has_basic_credentials?).and_return(true)
      allow(subject).to receive(:user_name_and_password).and_return([user.username, personal_access_token.token])
    end

    context 'with API requests' do
      before do
        env['SCRIPT_NAME'] = '/api/endpoint'
      end

      it 'tries to find the user' do
        expect(subject.user([:api])).to eq user
      end

      it 'returns nil if the token is revoked' do
        personal_access_token.revoke!

        expect(subject.user([:api])).to be_blank
      end

      it 'returns nil if the token does not have API scope' do
        personal_access_token.update!(scopes: ['read_registry'])

        expect(subject.user([:api])).to be_blank
      end
    end

    context 'without API requests' do
      before do
        env['SCRIPT_NAME'] = '/web/endpoint'
      end

      it 'does not search for job users' do
        expect(PersonalAccessToken).not_to receive(:find_by_token)

        expect(subject.user([:api])).to be_nil
      end
    end
  end

  describe '#find_user_from_job_token' do
    let_it_be(:user) { build(:user) }
    let_it_be(:job) { build(:ci_build, user: user, status: :running) }

    before do
      env[Gitlab::Auth::AuthFinders::JOB_TOKEN_HEADER] = 'token'
    end

    context 'with API requests' do
      before do
        env['SCRIPT_NAME'] = '/api/endpoint'
        expect(::Ci::Build).to receive(:find_by_token).with('token').and_return(job)
      end

      it 'tries to find the user' do
        expect(subject.find_sessionless_user(:api)).to eq user
      end

      it 'returns nil if the job is not running' do
        job.status = :success

        expect(subject.find_sessionless_user(:api)).to be_blank
      end
    end

    context 'without API requests' do
      before do
        env['SCRIPT_NAME'] = '/web/endpoint'
      end

      it 'does not search for job users' do
        expect(::Ci::Build).not_to receive(:find_by_token)

        expect(subject.find_sessionless_user(:api)).to be_nil
      end
    end
  end

  describe '#runner' do
    let_it_be(:runner) { build(:ci_runner) }

    it 'returns the runner using #find_runner_from_token' do
      expect_any_instance_of(described_class)
        .to receive(:find_runner_from_token)
        .and_return(runner)

      expect(subject.runner).to eq runner
    end

    it 'returns nil if no runner is found' do
      expect(subject.runner).to be_blank
    end

    it 'rescue Gitlab::Auth::AuthenticationError exceptions' do
      expect_any_instance_of(described_class)
        .to receive(:find_runner_from_token)
        .and_raise(Gitlab::Auth::UnauthorizedError)

      expect(subject.runner).to be_blank
    end
  end

  describe '#route_authentication_setting' do
    using RSpec::Parameterized::TableSyntax

    where(:script_name, :expected_job_token_allowed, :expected_basic_auth_personal_access_token, :expected_deploy_token_allowed) do
      '/api/endpoint'          | true  | true  | true
      '/namespace/project.git' | false | true  | true
      '/web/endpoint'          | false | false | false
    end

    with_them do
      before do
        env['SCRIPT_NAME'] = script_name
      end

      it 'returns correct settings' do
        expect(subject.send(:route_authentication_setting)).to eql({
          job_token_allowed: expected_job_token_allowed,
          basic_auth_personal_access_token: expected_basic_auth_personal_access_token,
          deploy_token_allowed: expected_deploy_token_allowed
        })
      end
    end
  end
end
