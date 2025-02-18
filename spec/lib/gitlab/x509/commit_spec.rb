# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Gitlab::X509::Commit, feature_category: :source_code_management do
  let(:commit_sha) { '189a6c924013fc3fe40d6f1ec1dc20214183bc97' }
  let_it_be(:user) { create(:user, email: X509Helpers::User1.certificate_email) }
  let_it_be(:project) { create(:project, :repository, path: X509Helpers::User1.path, creator: user) }
  let(:commit) { project.commit_by(oid: commit_sha) }
  let(:signature) { described_class.new(commit).signature }
  let(:store) { OpenSSL::X509::Store.new }
  let(:certificate) { OpenSSL::X509::Certificate.new(X509Helpers::User1.trust_cert) }

  before do
    store.add_cert(certificate) if certificate
    allow(OpenSSL::X509::Store).to receive(:new).and_return(store)
  end

  describe '#signature' do
    context 'returns the cached signature' do
      it 'on second call' do
        allow_any_instance_of(described_class).to receive(:new).and_call_original
        expect_any_instance_of(described_class).to receive(:create_cached_signature!).and_call_original

        signature

        # consecutive call
        expect(described_class).not_to receive(:create_cached_signature!).and_call_original
        signature
      end
    end

    context 'unsigned commit' do
      let(:project) { create :project, :repository, path: X509Helpers::User1.path }
      let(:commit_sha) { X509Helpers::User1.commit }
      let(:commit) { create :commit, project: project, sha: commit_sha }

      it 'returns nil' do
        expect(signature).to be_nil
      end
    end
  end

  describe '#update_signature!' do
    let(:certificate) { nil }

    it 'updates verification status' do
      signature

      cert = OpenSSL::X509::Certificate.new(X509Helpers::User1.trust_cert)
      store.add_cert(cert)

      stored_signature = CommitSignatures::X509CommitSignature.find_by_commit_sha(commit_sha)
      expect { described_class.new(commit).update_signature!(stored_signature) }.to(
        change { signature.reload.verification_status }.from('unverified').to('verified')
      )
    end
  end
end
