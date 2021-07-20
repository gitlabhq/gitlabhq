# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Auth::RequestAuthenticator do
  let(:env) do
    {
      'rack.input' => '',
      'REQUEST_METHOD' => 'GET'
    }
  end

  let(:request) { ActionDispatch::Request.new(env) }

  subject { described_class.new(request) }

  describe '#user' do
    let!(:sessionless_user) { build(:user) }
    let!(:session_user) { build(:user) }

    it 'returns sessionless user first' do
      allow_any_instance_of(described_class).to receive(:find_sessionless_user).and_return(sessionless_user)
      allow_any_instance_of(described_class).to receive(:find_user_from_warden).and_return(session_user)

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

  describe '#find_sessionless_user' do
    let!(:access_token_user) { build(:user) }
    let!(:feed_token_user) { build(:user) }
    let!(:static_object_token_user) { build(:user) }
    let!(:job_token_user) { build(:user) }
    let!(:lfs_token_user) { build(:user) }
    let!(:basic_auth_access_token_user) { build(:user) }
    let!(:basic_auth_password_user) { build(:user) }

    it 'returns access_token user first' do
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

    it 'returns lfs_token user if no job_token user found' do
      allow_any_instance_of(described_class)
        .to receive(:find_user_from_lfs_token)
        .and_return(lfs_token_user)

      expect(subject.find_sessionless_user(:api)).to eq lfs_token_user
    end

    it 'returns basic_auth_access_token user if no lfs_token user found' do
      allow_any_instance_of(described_class)
        .to receive(:find_user_from_personal_access_token)
        .and_return(basic_auth_access_token_user)

      expect(subject.find_sessionless_user(:api)).to eq basic_auth_access_token_user
    end

    it 'returns basic_auth_access_password user if no basic_auth_access_token user found' do
      allow_any_instance_of(described_class)
        .to receive(:find_user_from_basic_auth_password)
        .and_return(basic_auth_password_user)

      expect(subject.find_sessionless_user(:api)).to eq basic_auth_password_user
    end

    it 'returns nil if no user found' do
      expect(subject.find_sessionless_user(:api)).to be_blank
    end

    it 'rescue Gitlab::Auth::AuthenticationError exceptions' do
      allow_any_instance_of(described_class).to receive(:find_user_from_web_access_token).and_raise(Gitlab::Auth::UnauthorizedError)

      expect(subject.find_sessionless_user(:api)).to be_blank
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
    let!(:user) { build(:user) }
    let!(:job) { build(:ci_build, user: user, status: :running) }

    before do
      env[Gitlab::Auth::AuthFinders::JOB_TOKEN_HEADER] = 'token'
    end

    context 'with API requests' do
      before do
        env['SCRIPT_NAME'] = '/api/endpoint'
        expect(::Ci::Build).to receive(:find_by_token).with('token').and_return(job)
      end

      it 'tries to find the user' do
        expect(subject.find_sessionless_user([:api])).to eq user
      end

      it 'returns nil if the job is not running' do
        job.status = :success

        expect(subject.find_sessionless_user([:api])).to be_blank
      end
    end

    context 'without API requests' do
      before do
        env['SCRIPT_NAME'] = '/web/endpoint'
      end

      it 'does not search for job users' do
        expect(::Ci::Build).not_to receive(:find_by_token)

        expect(subject.find_sessionless_user([:api])).to be_nil
      end
    end
  end

  describe '#runner' do
    let!(:runner) { build(:ci_runner) }

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

    where(:script_name, :expected_job_token_allowed, :expected_basic_auth_personal_access_token) do
      '/api/endpoint'          | true  | true
      '/namespace/project.git' | false | true
      '/web/endpoint'          | false | false
    end

    with_them do
      before do
        env['SCRIPT_NAME'] = script_name
      end

      it 'returns correct settings' do
        expect(subject.send(:route_authentication_setting)).to eql({
          job_token_allowed: expected_job_token_allowed,
          basic_auth_personal_access_token: expected_basic_auth_personal_access_token
        })
      end
    end
  end
end
