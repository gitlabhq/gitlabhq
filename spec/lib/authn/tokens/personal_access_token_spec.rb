# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Authn::Tokens::PersonalAccessToken, feature_category: :system_access do
  let_it_be(:user) { create(:user) }
  let_it_be(:admin) { create(:admin) }
  let_it_be(:personal_access_token) { create(:personal_access_token, user: user) }

  subject(:token) { described_class.new(plaintext, :group_token_revocation_service) }

  RSpec.shared_examples 'validates prefix' do
    it 'returns true if token starts with valid prefix' do
      expect(described_class.prefix?(token_lookalike)).to eq(is_valid)
    end
  end

  describe '.prefix?' do
    let_it_be(:token_lookalike) { 'glpat-1234abcd' }

    it 'returns true if token starts with a prefix' do
      expect(described_class.prefix?(token_lookalike)).to be_truthy
    end

    it 'is true and falls back to the default token prefix if token setting is nil' do
      stub_application_setting(personal_access_token_prefix: nil)

      expect(described_class.prefix?(token_lookalike)).to be_truthy
    end

    # An empty string sent to `start_with?` would cause every value to be true
    it 'is false if token setting is an empty string' do
      stub_application_setting(personal_access_token_prefix: '')

      expect(described_class.prefix?('non-token')).to be_falsey
    end

    context 'with custom personal access token prefix configured' do
      let_it_be(:personal_access_token_prefix) { 'custom-pat-prefix-' }

      before do
        stub_application_setting(personal_access_token_prefix: personal_access_token_prefix)
      end

      using RSpec::Parameterized::TableSyntax

      where(:token_lookalike, :is_valid) do
        'glpat-1234abcd' | true
        'custom-pat-prefix-1234abcd' | true
        'instancetokenprefix-glpat-1234abcd' | false
      end

      with_them do
        it_behaves_like 'validates prefix'
      end

      context 'with instance wide token prefix configured' do
        let_it_be(:instance_token_prefix) { 'instancetokenprefix' }

        before do
          stub_application_setting(instance_token_prefix: instance_token_prefix)
        end

        using RSpec::Parameterized::TableSyntax

        where(:token_lookalike, :is_valid) do
          'glpat-1234abcd' | true
          'custom-pat-prefix-1234abcd' | true
          'instancetokenprefix-glpat-1234abcd' | true
        end

        with_them do
          it_behaves_like 'validates prefix'
        end
      end
    end

    context 'with instance wide token prefix configured' do
      let_it_be(:instance_token_prefix) { 'instancetokenprefix' }

      before do
        stub_application_setting(instance_token_prefix: instance_token_prefix)
      end

      using RSpec::Parameterized::TableSyntax

      where(:token_lookalike, :is_valid) do
        'glpat-1234abcd' | true
        'custom-pat-prefix-1234abcd' | false
        'instancetokenprefix-glpat-1234abcd' | true
      end

      with_them do
        it_behaves_like 'validates prefix'
      end
    end
  end

  context 'with valid personal access token' do
    let(:plaintext) { personal_access_token.token }
    let(:valid_revocable) { personal_access_token }

    it_behaves_like 'finding the valid revocable'

    describe '#revoke!' do
      it 'successfully revokes the token' do
        expect(token.revoke!(admin).status).to eq(:success)
      end
    end

    describe '#resource_name' do
      subject(:resource_name) { token.resource_name }

      it { is_expected.to eq 'PersonalAccessToken' }
    end
  end

  context 'when the token is a resource token' do
    context 'when the token is a project access token' do
      let_it_be(:bot) { create(:user, :project_bot) }
      let_it_be(:project_member) { create(:project_member, source: create(:project), user: bot) }
      let_it_be(:plaintext) { create(:personal_access_token, user: bot).token }

      it 'successfully revokes the token', :enable_admin_mode do
        expect(token.revoke!(admin).status).to eq(:success)
      end

      describe '#resource_name' do
        subject(:resource_name) { token.resource_name }

        it { is_expected.to eq 'ProjectAccessToken' }
      end
    end

    context 'when the token is a group access token' do
      let_it_be(:bot) { create(:user, :project_bot) }
      let_it_be(:group_member) { create(:group_member, source: create(:group), user: bot) }
      let_it_be(:plaintext) { create(:personal_access_token, user: bot).token }

      it 'successfully revokes the token', :enable_admin_mode do
        expect(token.revoke!(admin).status).to eq(:success)
      end

      describe '#resource_name' do
        subject(:resource_name) { token.resource_name }

        it { is_expected.to eq 'GroupAccessToken' }
      end
    end
  end

  context 'when the token is from a bot without a resource' do
    let_it_be(:plaintext) { create(:personal_access_token, user: create(:user, :project_bot)).token }

    describe '#resource_name' do
      subject(:resource_name) { token.resource_name }

      it { is_expected.to be_nil }
    end
  end

  context 'when the user is neither a human nor a bot' do
    let(:plaintext) { personal_access_token.token }

    it 'raises unsupported deploy token type' do
      expect(user).to receive(:human?).and_return(false)
      expect(user).to receive(:project_bot?).and_return(false)

      expect(::PersonalAccessToken).to receive(:find_by_token).with(plaintext).and_return(personal_access_token)

      expect do
        token.revoke!(admin)
      end
        .to raise_error(::Authn::AgnosticTokenIdentifier::UnsupportedTokenError,
          'Unsupported personal access token type')
    end
  end

  it_behaves_like 'token handling with unsupported token type'
end
