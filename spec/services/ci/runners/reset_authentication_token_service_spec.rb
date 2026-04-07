# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Ci::Runners::ResetAuthenticationTokenService, '#execute', :aggregate_failures, feature_category: :runner_core do
  shared_examples 'is not permitted to reset token' do
    it 'does not reset authentication token and returns error response' do
      expect(execute.error?).to be_truthy
      expect(execute.message).to eq('Not permitted to reset')
    end
  end

  shared_examples 'resets authentication token and returns success' do
    it 'does reset authentication token and returns success' do
      expect { execute }.to change { runner.reload.token }
      expect(execute).to be_success
    end
  end

  let(:runner) { create(:ci_runner) }

  let(:service) { described_class.new(runner: runner, current_user: current_user, source: source) }

  subject(:execute) { service.execute }

  context 'without source' do
    let(:source) { nil }

    context 'with unauthorized user' do
      let(:current_user) { build(:user) }

      it_behaves_like 'is not permitted to reset token'
    end

    context 'with admin', :enable_admin_mode do
      let(:current_user) { build(:admin) }

      it_behaves_like 'resets authentication token and returns success'
    end
  end

  context 'with source' do
    let(:current_user) { nil }

    context 'with permitted source' do
      let(:source) { :runner_api }

      it_behaves_like 'resets authentication token and returns success'
    end

    context 'with source lacking permissions' do
      let(:source) { :other }

      it 'raises an error' do
        expect { execute }.to raise_error NoMethodError
      end
    end
  end

  context 'when runner is in an invalid state' do
    let(:current_user) { nil }
    let(:source) { :runner_api }
    let(:runner) { create(:ci_runner, :project, :without_projects) }

    it 'returns an error response instead of raising an exception' do
      expect(execute).to be_error
      expect(execute.message).to include('needs to be assigned to at least one project')
      expect(execute.reason).to eq(:unprocessable_entity)
    end

    it 'does not change the token' do
      expect { execute }.not_to change { runner.reload.token }
    end
  end
end
