# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Authn::Tokens::RunnerAuthenticationToken, :aggregate_failures, feature_category: :system_access do
  let_it_be(:user) { create(:user) }
  let_it_be(:admin) { create(:admin) }
  let_it_be(:default_prefix) { ::Ci::Runner::CREATED_RUNNER_TOKEN_PREFIX }

  let(:runner) { create(:ci_runner, registration_type: :authenticated_user) }
  let(:plaintext) { runner.token }

  subject(:token) { described_class.new(plaintext, :api_admin_token) }

  describe '.prefix?' do
    it 'returns true for created runner token prefix' do
      expect(described_class.prefix?(::Ci::Runner::CREATED_RUNNER_TOKEN_PREFIX)).to be_truthy
    end

    it 'returns true for instance-prefixed created runner token' do
      expect(described_class.prefix?(::Ci::Runner.created_runner_prefix)).to be_truthy
    end

    it 'returns false for legacy registration runner token prefix' do
      expect(described_class.prefix?(::Ci::Runner::REGISTRATION_RUNNER_TOKEN_PREFIX)).to be_falsey
    end

    it 'returns false for invalid prefix' do
      expect(described_class.prefix?('invalid-prefix')).to be_falsey
    end
  end

  context 'with valid runner authentication token' do
    let(:valid_revocable) { runner }

    it_behaves_like 'finding the valid revocable'
    it_behaves_like 'contains instance prefix when enabled'

    describe '#revoke!', :enable_admin_mode do
      it 'resets the runner token' do
        expect { token.revoke!(admin) }.to change { runner.reload.token }
      end
    end
  end

  it_behaves_like 'token handling with unsupported token type'
end
