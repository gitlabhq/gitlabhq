# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Ci::Runners::ResetAuthenticationTokenService, :aggregate_failures, feature_category: :runner do
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

  subject(:execute) { service.execute! }

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
end
