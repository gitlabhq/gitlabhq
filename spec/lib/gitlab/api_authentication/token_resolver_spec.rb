# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::APIAuthentication::TokenResolver, feature_category: :system_access do
  let_it_be(:user) { create(:user) }
  let_it_be(:project, reload: true) { create(:project, :public) }
  let_it_be(:personal_access_token) { create(:personal_access_token, user: user) }
  let_it_be(:ci_job) { create(:ci_build, project: project, user: user, status: :running) }
  let_it_be(:ci_job_done) { create(:ci_build, project: project, user: user, status: :success) }
  let_it_be(:deploy_token) { create(:deploy_token, read_package_registry: true, write_package_registry: true) }

  shared_examples 'an authorized request' do
    it 'returns the correct token' do
      expect(subject).to eq(token)
    end
  end

  shared_examples 'an unauthorized request' do
    it 'raises an error' do
      expect { subject }.to raise_error(Gitlab::Auth::UnauthorizedError)
    end
  end

  shared_examples 'an anoymous request' do
    it 'returns nil' do
      expect(subject).to eq(nil)
    end
  end

  describe '.new' do
    context 'with a valid type' do
      it 'creates a new instance' do
        expect(described_class.new(:personal_access_token)).to be_a(described_class)
      end
    end

    context 'with an invalid type' do
      it 'raises a validation error' do
        expect { described_class.new(:not_a_real_locator) }.to raise_error(ActiveModel::ValidationError)
      end
    end
  end

  describe '#resolve' do
    let(:resolver) { described_class.new(type) }

    subject { resolver.resolve(raw) }

    context 'with :personal_access_token_with_username' do
      let(:type) { :personal_access_token_with_username }
      let(:token) { personal_access_token }

      context 'with valid credentials' do
        let(:raw) { username_and_password(user.username, token.token) }

        it_behaves_like 'an authorized request'
      end

      context 'with an invalid username' do
        let(:raw) { username_and_password("not-my-#{user.username}", token.token) }

        it_behaves_like 'an unauthorized request'
      end

      context 'with no username' do
        let(:raw) { username_and_password(nil, token.token) }

        it_behaves_like 'an unauthorized request'
      end
    end

    context 'with :job_token_with_username' do
      let(:type) { :job_token_with_username }
      let(:token) { ci_job }

      context 'with valid credentials' do
        let(:raw) { username_and_password(Gitlab::Auth::CI_JOB_USER, token.token) }

        it_behaves_like 'an authorized request'
      end

      context 'when the job is not running' do
        let(:raw) { username_and_password(Gitlab::Auth::CI_JOB_USER, ci_job_done.token) }

        it_behaves_like 'an unauthorized request'
      end

      context 'with the wrong username' do
        let(:raw) { username_and_password("not-#{Gitlab::Auth::CI_JOB_USER}", nil) }

        it_behaves_like 'an anoymous request'
      end

      context 'with an invalid job token' do
        let(:raw) { username_and_password(Gitlab::Auth::CI_JOB_USER, "not a valid CI job token") }

        it_behaves_like 'an unauthorized request'
      end
    end

    context 'with :deploy_token_with_username' do
      let(:type) { :deploy_token_with_username }
      let(:token) { deploy_token }

      context 'with a valid deploy token' do
        let(:raw) { username_and_password(token.username, token.token) }

        it_behaves_like 'an authorized request'
      end

      context 'with an invalid username' do
        let(:raw) { username_and_password("not-my-#{token.username}", token.token) }

        it_behaves_like 'an unauthorized request'
      end

      context 'when the the deploy token is restricted with external_authorization' do
        before do
          allow(Gitlab::ExternalAuthorization).to receive(:allow_deploy_tokens_and_deploy_keys?).and_return(false)
        end

        context 'with a valid deploy token' do
          let(:raw) { username_and_password(token.username, token.token) }

          it_behaves_like 'an unauthorized request'
        end
      end
    end

    context 'with :personal_access_token' do
      let(:type) { :personal_access_token }
      let(:token) { personal_access_token }

      context 'with valid credentials' do
        let(:raw) { username_and_password(nil, token.token) }

        it_behaves_like 'an authorized request'
      end
    end

    context 'with :job_token' do
      let(:type) { :job_token }
      let(:token) { ci_job }

      context 'with valid credentials' do
        let(:raw) { username_and_password(nil, token.token) }

        it_behaves_like 'an authorized request'
      end

      context 'when the job is not running' do
        let(:raw) { username_and_password(nil, ci_job_done.token) }

        it_behaves_like 'an unauthorized request'
      end

      context 'with an invalid job token' do
        let(:raw) { username_and_password(nil, "not a valid CI job token") }

        it_behaves_like 'an unauthorized request'
      end
    end

    context 'with :deploy_token' do
      let(:type) { :deploy_token }
      let(:token) { deploy_token }

      context 'with a valid deploy token' do
        let(:raw) { username_and_password(nil, token.token) }

        it_behaves_like 'an authorized request'
      end
    end

    context 'with :personal_access_token_from_jwt' do
      let(:type) { :personal_access_token_from_jwt }
      let(:token) { personal_access_token }

      context 'with valid credentials' do
        let(:raw) { username_and_password_from_jwt(token.id) }

        it_behaves_like 'an authorized request'
      end
    end

    context 'with :deploy_token_from_jwt' do
      let(:type) { :deploy_token_from_jwt }
      let(:token) { deploy_token }

      context 'with valid credentials' do
        let(:raw) { username_and_password_from_jwt(token.token) }

        it_behaves_like 'an authorized request'
      end
    end

    context 'with :job_token_from_jwt' do
      let(:type) { :job_token_from_jwt }
      let(:token) { ci_job }

      context 'with valid credentials' do
        let(:raw) { username_and_password_from_jwt(token.token) }

        it_behaves_like 'an authorized request'
      end

      context 'when the job is not running' do
        let(:raw) { username_and_password_from_jwt(ci_job_done.token) }

        it_behaves_like 'an unauthorized request'
      end

      context 'with an invalid job token' do
        let(:raw) { username_and_password_from_jwt('not a valid CI job token') }

        it_behaves_like 'an unauthorized request'
      end
    end
  end

  def username_and_password(username, password)
    ::Gitlab::APIAuthentication::TokenLocator::UsernameAndPassword.new(username, password)
  end

  def username_and_password_from_jwt(token)
    username_and_password(nil, ::Gitlab::JWTToken.new.tap { |jwt| jwt['token'] = token }.encoded)
  end
end
