# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Import::UserCredential, feature_category: :importers do
  subject(:credential) { build(:import_user_credential) }

  describe 'associations' do
    it { is_expected.to belong_to(:user).required }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:provider) }
    it { is_expected.to validate_presence_of(:provider_host) }
    it { is_expected.to validate_presence_of(:provider_account_xid) }
    it { is_expected.to validate_presence_of(:access_token) }
    it { is_expected.to validate_length_of(:access_token).is_at_most(described_class::TOKEN_MAX_LENGTH) }
    it { is_expected.to validate_length_of(:refresh_token).is_at_most(described_class::TOKEN_MAX_LENGTH) }
    it { is_expected.to validate_length_of(:provider_host).is_at_most(255) }
    it { is_expected.to validate_length_of(:scopes).is_at_most(255) }
  end

  it { is_expected.to define_enum_for(:provider).with_values(github: 0) }

  it 'encrypts the tokens' do
    credential = create(:import_user_credential, access_token: 'gho_secret', refresh_token: 'ghr_secret')

    expect(credential.encrypted_attribute?(:access_token)).to be(true)
    expect(credential.encrypted_attribute?(:refresh_token)).to be(true)
    expect(credential.ciphertext_for(:access_token)).not_to include('gho_secret')
  end

  it 'does not serialize the tokens' do
    expect(credential.serializable_hash).not_to include('access_token', 'refresh_token')
  end

  it 'downcases the provider host' do
    expect(build(:import_user_credential, provider_host: 'GitHub.com').provider_host).to eq('github.com')
  end

  describe '.for_account' do
    let_it_be(:user) { create(:user) }
    let_it_be(:credential) { create(:import_user_credential, user: user, provider_account_xid: 1) }

    before_all do
      create(:import_user_credential, user: user, provider_account_xid: 2)
      create(:import_user_credential, user: user, provider_account_xid: 1, provider_host: 'ghe.example.com')
      create(:import_user_credential, provider_account_xid: 1)
    end

    it 'returns the credential for the user, provider, host and account' do
      expect(
        described_class.for_account(user: user, provider: :github, provider_host: 'github.com', provider_account_xid: 1)
      ).to contain_exactly(credential)
    end
  end

  describe '.store!', :freeze_time do
    let_it_be(:user) { create(:user) }

    let(:token_attributes) do
      {
        access_token: 'gho_new',
        refresh_token: 'ghr_new',
        expires_at: 8.hours.from_now,
        refresh_token_expires_at: 6.months.from_now,
        scopes: 'repo,read:org'
      }
    end

    def store!(provider_account_xid: 1)
      described_class.store!(
        user: user,
        provider: :github,
        provider_host: 'github.com',
        provider_account_xid: provider_account_xid,
        **token_attributes
      )
    end

    it 'creates a credential' do
      expect { store! }.to change { described_class.count }.by(1)

      expect(described_class.last).to have_attributes(
        user: user,
        provider: 'github',
        provider_host: 'github.com',
        provider_account_xid: 1,
        **token_attributes
      )
    end

    it 'replaces the token of an existing credential for the same account' do
      existing = create(:import_user_credential,
        user: user, provider_account_xid: 1, access_token: 'gho_old', refresh_token: 'ghr_old')

      token_attributes[:refresh_token] = nil

      expect { store! }.not_to change { described_class.count }

      expect(existing.reload).to have_attributes(access_token: 'gho_new', refresh_token: nil)
    end

    it 'matches the existing credential regardless of host casing' do
      existing = create(:import_user_credential, user: user, provider_account_xid: 1)

      expect do
        described_class.store!(
          user: user, provider: :github, provider_host: 'GitHub.com', provider_account_xid: 1, **token_attributes
        )
      end.not_to change { described_class.count }

      expect(existing.reload.access_token).to eq('gho_new')
    end

    it 'raises when the token is invalid' do
      token_attributes[:access_token] = 'a' * (described_class::TOKEN_MAX_LENGTH + 1)

      expect { store! }.to raise_error(ActiveRecord::RecordInvalid)
    end

    context 'when another request creates the credential at the same time' do
      it 'updates the credential created by the other request' do
        existing = create(:import_user_credential, user: user, provider_account_xid: 1)
        calls = 0

        allow(described_class).to receive(:find_or_initialize_by).and_wrap_original do |method, attributes|
          calls += 1
          calls == 1 ? described_class.new(attributes) : method.call(attributes)
        end

        expect { store! }.not_to change { described_class.count }

        expect(existing.reload.access_token).to eq('gho_new')
      end

      it 'raises when the retry also conflicts', :aggregate_failures do
        create(:import_user_credential, user: user, provider_account_xid: 1)

        allow(described_class).to receive(:find_or_initialize_by) { |attributes| described_class.new(attributes) }

        expect { store! }.to raise_error(ActiveRecord::RecordNotUnique)
        expect(described_class).to have_received(:find_or_initialize_by).twice
      end
    end

    it 'creates a separate credential for another GitHub account' do
      create(:import_user_credential, user: user, provider_account_xid: 1)

      expect { store!(provider_account_xid: 2) }.to change { described_class.count }.by(1)
    end
  end
end
