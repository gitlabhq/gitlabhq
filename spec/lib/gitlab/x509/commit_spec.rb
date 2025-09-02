# frozen_string_literal: true
require 'spec_helper'

# This class inherits from Gitlab::Repositories::BaseSignedCommit
RSpec.describe Gitlab::X509::Commit, feature_category: :source_code_management do
  let(:commit_sha) { '189a6c924013fc3fe40d6f1ec1dc20214183bc97' }
  let_it_be(:user) { create(:user, email: X509Helpers::User1.certificate_email) }
  let_it_be(:project) { create(:project, :repository, path: X509Helpers::User1.path, creator: user) }
  let(:commit) { project.commit_by(oid: commit_sha) }
  let(:x509_commit) { described_class.new(commit) }
  # A new instance is required so that @signature will be empty,
  # but that the lazy_signature exists in the database
  # You have to instantiate x509_commit before x509_with_cached_signature
  let(:x509_commit_with_cached_signature) { described_class.new(commit) }
  let(:signature) { x509_commit.signature }
  let(:store) { OpenSSL::X509::Store.new }
  let(:certificate) { OpenSSL::X509::Certificate.new(X509Helpers::User1.trust_cert) }
  let(:stored_signature) { CommitSignatures::X509CommitSignature.find_by_commit_sha(commit_sha) }

  before do
    store.add_cert(certificate) if certificate
    allow(OpenSSL::X509::Store).to receive(:new).and_return(store)
  end

  describe "attributes" do
    it 'x509 commit signature contains committer email' do
      expect(signature.committer_email).to eq("r.meier@siemens.com")
    end

    context 'when check_for_mailmapped_commit_emails feature flag is disabled' do
      before do
        stub_feature_flags(check_for_mailmapped_commit_emails: false)
      end

      it 'x509 commit signature does not contain an committer email' do
        expect(signature.committer_email).to be_nil
      end
    end
  end

  context 'when signature committer_email is nil' do
    before do
      # lazyily load a signature
      signature
      # update the signature in the db
      stored_signature.update!(committer_email: nil)
    end

    it 'updates committer_email with signature_data committer_email' do
      expect { described_class.new(commit).update_signature!(stored_signature) }.to(
        change { signature.reload.committer_email }.from(nil).to('r.meier@siemens.com')
      )
    end

    context 'when check_for_mailmapped_commit_emails feature flag is disabled' do
      before do
        stub_feature_flags(check_for_mailmapped_commit_emails: false)
      end

      it 'does not update committer_email with signature_data committer_email' do
        expect { described_class.new(commit).update_signature!(stored_signature) }.not_to change {
          stored_signature.reload.committer_email
        }
      end
    end
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

    describe 'updating the cached signature' do
      shared_examples "does not update the cached signature" do
        it "does not update the cached signature" do
          expect_any_instance_of(CommitSignatures::X509CommitSignature)
            .not_to receive(:update!)

          # only check committer email update if stored_signature exists
          if stored_signature
            expect { x509_commit_with_cached_signature.signature }.not_to change { stored_signature.committer_email }
          else
            x509_commit_with_cached_signature.signature
          end
        end
      end

      context "when cached_signature is nil" do
        it_behaves_like "does not update the cached signature"
      end

      context "when cached_signature exists" do
        let(:certificate) { nil }
        let(:signature_data) do
          {
            signature: GpgHelpers::User1.signed_commit_signature,
            signed_text: GpgHelpers::User1.signed_commit_base_data,
            signer: signer,
            author_email: user_email
          }
        end

        before do
          # Instantiating this will put the commit signature in the database.
          # This way we can make sure the cached_signature exists to test the logic flow.
          x509_commit.signature

          cert = OpenSSL::X509::Certificate.new(X509Helpers::User1.trust_cert)

          store.add_cert(cert)

          # This will get set to `@signature_data` in the class
          allow(Gitlab::Git::Commit).to receive(:extract_signature_lazily)
            .with(Gitlab::Git::Repository, commit_sha)
            .and_return(stored_signature.attributes.symbolize_keys)

          stored_signature.update!(committer_email: committer_email)

          # Ensure we're retrieving from the db not from batch loader cache
          BatchLoader::Executor.clear_current
        end

        context "when committer email is not missing" do
          let(:committer_email) { 'test@test.com' }

          it_behaves_like "does not update the cached signature"
        end

        context "when committer email is missing" do
          let(:committer_email) { nil }

          it 'updates the cached signature' do
            result = x509_commit_with_cached_signature.signature
            expect(result.committer_email).to eq('r.meier@siemens.com')
          end

          context "when check_for_mailmapped_commit_emails is disabled" do
            before do
              stub_feature_flags(check_for_mailmapped_commit_emails: false)
            end

            it_behaves_like "does not update the cached signature"
          end
        end
      end
    end
  end

  describe '#update_signature!' do
    let(:certificate) { nil }

    it 'updates verification status' do
      signature

      cert = OpenSSL::X509::Certificate.new(X509Helpers::User1.trust_cert)
      store.add_cert(cert)

      expect { described_class.new(commit).update_signature!(stored_signature) }.to(
        change { signature.reload.verification_status }.from('unverified').to('verified')
      )
    end
  end
end
