# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::APIAuthentication::TokenResolver do
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

    context 'with :personal_access_token' do
      let(:type) { :personal_access_token }
      let(:token) { personal_access_token }

      context 'with valid credentials' do
        let(:raw) { username_and_password(user.username, token.token) }

        it_behaves_like 'an authorized request'
      end

      context 'with an invalid username' do
        let(:raw) { username_and_password("not-my-#{user.username}", token.token) }

        it_behaves_like 'an unauthorized request'
      end
    end

    context 'with :job_token' do
      let(:type) { :job_token }
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

    context 'with :deploy_token' do
      let(:type) { :deploy_token }
      let(:token) { deploy_token }

      context 'with a valid deploy token' do
        let(:raw) { username_and_password(token.username, token.token) }

        it_behaves_like 'an authorized request'
      end

      context 'with an invalid username' do
        let(:raw) { username_and_password("not-my-#{token.username}", token.token) }

        it_behaves_like 'an unauthorized request'
      end
    end
  end

  def username_and_password(username, password)
    ::Gitlab::APIAuthentication::TokenLocator::UsernameAndPassword.new(username, password)
  end
end
