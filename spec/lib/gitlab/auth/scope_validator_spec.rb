# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Auth::ScopeValidator, feature_category: :system_access do
  let(:user) { build(:user) }
  let(:authenticator) { instance_double(Gitlab::Auth::RequestAuthenticator) }
  let(:validator) { described_class.new(user, authenticator) }

  describe '#ai_workflow_request?' do
    context 'when current_token_scopes includes ai_workflows' do
      it 'returns true' do
        allow(authenticator).to receive(:current_token_scopes).and_return(%w[api ai_workflows])

        expect(validator.ai_workflow_request?).to be(true)
      end
    end

    context 'when current_token_scopes does not include ai_workflows' do
      it 'returns false' do
        allow(authenticator).to receive(:current_token_scopes).and_return(%w[api read_user])

        expect(validator.ai_workflow_request?).to be(false)
      end
    end

    context 'when current_token_scopes is empty (e.g. session request)' do
      it 'returns false' do
        allow(authenticator).to receive(:current_token_scopes).and_return([])

        expect(validator.ai_workflow_request?).to be(false)
      end
    end
  end
end
