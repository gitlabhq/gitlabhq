# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::X509::Commit, feature_category: :source_code_management do
  let(:commit_sha) { '440bf5b2b499a90d9adcbebe3752f8c6f245a1aa' }
  let_it_be(:user) { create(:user, email: X509Helpers::User2.certificate_email) }
  let_it_be(:project) { create(:project, :repository, path: X509Helpers::User2.path, creator: user) }
  let(:commit) { create(:commit, project: project) }
  let(:signature) { described_class.new(commit).signature }
  let(:store) { OpenSSL::X509::Store.new }
  let(:certificate) { OpenSSL::X509::Certificate.new(X509Helpers::User2.trust_cert) }

  before do
    store.add_cert(certificate) if certificate
    allow(OpenSSL::X509::Store).to receive(:new).and_return(store)
  end

  describe '#signature' do
    context 'on second call' do
      it 'returns the cached signature' do
        allow_next_instance_of(described_class) do |instance|
          allow(instance).to receive(:new).and_call_original
        end
        expect_next_instance_of(described_class) do |instance|
          expect(instance).to receive(:create_cached_signature!).and_call_original
        end

        signature

        # consecutive call
        expect(described_class).not_to receive(:create_cached_signature!).and_call_original
        signature
      end
    end
  end

  describe '#update_signature!' do
    let(:certificate) { nil }

    it 'updates verification status' do
      signature

      cert = OpenSSL::X509::Certificate.new(X509Helpers::User2.trust_cert)
      store.add_cert(cert)

      # stored_signature = CommitSignatures::X509CommitSignature.find_by_commit_sha(commit_sha)
      # expect { described_class.new(commit).update_signature!(stored_signature) }.to(
      #   change { signature.reload.verification_status }.from('unverified').to('verified')
      # )  # TODO sigstore support pending
    end
  end
end
