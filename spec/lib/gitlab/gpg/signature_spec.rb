# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Gpg::Signature, feature_category: :source_code_management do
  let_it_be(:project) { create(:project, :repository, path: 'sample-project') }

  let(:commit_sha) { '0beec7b5ea3f0fdbc95d0dd47f3c5bc275da8a33' }
  let(:committer_email) { GpgHelpers::User1.emails.first }
  let(:user_email) { committer_email }
  let(:signature) { GpgHelpers::User1.signed_commit_signature }
  let(:signed_text) { GpgHelpers::User1.signed_commit_base_data }
  let(:signer) { :SIGNER_USER }
  let(:crypto) { instance_double(GPGME::Crypto) }
  let(:user) { create(:user, email: user_email) }
  let!(:gpg_key) { create(:gpg_key, key: public_key, user: user) }
  let(:public_key) { GpgHelpers::User1.public_key }
  let(:commit) { create(:commit, project: project, sha: commit_sha, committer_email: committer_email) }
  let(:gpg_signature) { described_class.new(signature, signed_text, signer, committer_email) }

  it_behaves_like 'signature with type checking', :gpg do
    subject { gpg_signature }
  end

  describe '#verification_status' do
    subject { gpg_signature.verification_status }

    context 'when the fingerprint in the signature matches a key belonging to a matching user' do
      it { is_expected.to eq(:verified) }
    end

    context 'when the signature is invalid' do
      let(:signature) { GpgHelpers::User1.signed_commit_signature.tr('=', 'a') }

      it { is_expected.to be_nil }
    end

    context 'when commit has multiple signatures' do
      before do
        verified_signature = instance_double(GPGME::Signature, fingerprint: GpgHelpers::User1.fingerprint, valid?: true)
        allow(GPGME::Crypto).to receive(:new).and_return(crypto)
        allow(crypto).to receive(:verify).and_yield(verified_signature).and_yield(instance_double(GPGME::Signature))
      end

      it { is_expected.to eq(:multiple_signatures) }
    end

    context 'when commit signed with a subkey' do
      let(:committer_email) { GpgHelpers::User3.emails.first }
      let(:public_key) { GpgHelpers::User3.public_key }
      let(:signature) { GpgHelpers::User3.signed_commit_signature }
      let(:signed_text) { GpgHelpers::User3.signed_commit_base_data }

      it { is_expected.to eq(:verified) }
    end

    context 'when gpg key email does not match the committer_email but is the same user when the committer_email \
      belongs to the user as a confirmed secondary email' do
      let(:committer_email) { GpgHelpers::User2.emails.first }

      let(:user) do
        create(:user, email: GpgHelpers::User1.emails.first).tap do |user|
          create :email, :confirmed, user: user, email: committer_email
        end
      end

      it { is_expected.to eq(:same_user_different_email) }
    end

    context 'when gpg key email does not match the committer_email when the committer_email belongs to the user \
      as a unconfirmed secondary email' do
      let(:committer_email) { GpgHelpers::User2.emails.first }

      let(:user) do
        create(:user, email: GpgHelpers::User1.emails.first).tap do |user|
          create :email, user: user, email: committer_email
        end
      end

      it { is_expected.to eq(:other_user) }
    end

    context 'when user email does not match the committer email' do
      let(:committer_email) { GpgHelpers::User2.emails.first }
      let(:user_email) { GpgHelpers::User1.emails.first }

      it { is_expected.to eq(:other_user) }
    end

    context 'when user does not match the key uid' do
      let(:user_email) { GpgHelpers::User2.emails.first }
      let(:public_key) { GpgHelpers::User1.public_key }

      it { is_expected.to eq(:unverified_key) }
    end

    context 'when there is no matching gpg key' do
      let(:gpg_key) { nil }

      it { is_expected.to eq(:unknown_key) }
    end

    context 'when signature created by GitLab' do
      let(:signer) { :SIGNER_SYSTEM }
      let(:gpg_key) { nil }

      it { is_expected.to eq(:verified_system) }
    end
  end

  describe '#gpg_key' do
    subject { gpg_signature.gpg_key }

    context 'when a valid key signed using recent version of Gnupg' do
      before do
        verified_signature = instance_double(GPGME::Signature, fingerprint: GpgHelpers::User1.fingerprint, valid?: true)
        allow(GPGME::Crypto).to receive(:new).and_return(crypto)
        allow(crypto).to receive(:verify).and_yield(verified_signature)
      end

      it { is_expected.to eq(gpg_key) }
    end

    context 'when a valid key signed using older version of Gnupg' do
      before do
        keyid = GpgHelpers::User1.fingerprint.last(16)
        verified_signature = instance_double(GPGME::Signature, fingerprint: keyid, valid?: true)
        allow(GPGME::Crypto).to receive(:new).and_return(crypto)
        allow(crypto).to receive(:verify).and_yield(verified_signature)
      end

      it { is_expected.to eq(gpg_key) }
    end

    context 'when commit has multiple signatures' do
      before do
        verified_signature = instance_double(GPGME::Signature, fingerprint: GpgHelpers::User1.fingerprint, valid?: true)
        allow(GPGME::Crypto).to receive(:new).and_return(crypto)
        allow(crypto).to receive(:verify).and_yield(verified_signature).and_yield(instance_double(GPGME::Signature))
      end

      it 'returns the key matching the first signature' do
        is_expected.to eq(gpg_key)
      end
    end

    context 'when commit signed with a subkey' do
      let(:committer_email) { GpgHelpers::User3.emails.first }
      let(:public_key) { GpgHelpers::User3.public_key }
      let(:signature) { GpgHelpers::User3.signed_commit_signature }
      let(:signed_text) { GpgHelpers::User3.signed_commit_base_data }

      let(:gpg_key_subkey) do
        gpg_key.subkeys.find_by(fingerprint: GpgHelpers::User3.subkey_fingerprints.last)
      end

      it { is_expected.to eq(gpg_key_subkey) }
    end

    context 'when there is no matching gpg key' do
      let(:gpg_key) { nil }

      it { is_expected.to be_nil }
    end

    context 'when signature created by GitLab' do
      let(:signer) { :SIGNER_SYSTEM }
      let(:gpg_key) { nil }

      it { is_expected.to be_nil }
    end
  end

  describe '#gpg_key_primary_keyid' do
    subject(:gpg_key_primary_keyid) { gpg_signature.gpg_key_primary_keyid }

    context 'when a gpg key exists' do
      it { is_expected.to eq(gpg_key.keyid) }
    end

    context 'when a no gpg key does not exist' do
      let(:gpg_key) { nil }

      it 'returns fingerprint' do
        allow(gpg_signature).to receive(:fingerprint).and_return('stubbed_fingerprint')

        expect(gpg_key_primary_keyid).to eq('stubbed_fingerprint')
      end
    end
  end

  describe '#fingerprint' do
    subject(:fingerprint)  { gpg_signature.fingerprint }

    let(:signature_double) { instance_double(GPGME::Signature, fingerprint: 'stubbed_fingerprint') }

    it 'delegates to signature' do
      expect_next_instance_of(GPGME::Crypto) do |instance|
        expect(instance).to receive(:verify)
          .with(signature, signed_text: signed_text)
          .and_yield(signature_double)
      end

      expect(fingerprint).to eq('stubbed_fingerprint')
    end
  end
end
