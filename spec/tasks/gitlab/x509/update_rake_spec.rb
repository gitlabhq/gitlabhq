# frozen_string_literal: true

require 'rake_helper'

describe 'gitlab:x509 namespace rake task' do
  before :all do
    Rake.application.rake_require 'tasks/gitlab/x509/update'
  end

  describe 'update_signatures' do
    subject { run_rake_task('gitlab:x509:update_signatures') }

    let(:project) { create :project, :repository, path: X509Helpers::User1.path }
    let(:x509_signed_commit) { project.commit_by(oid: '189a6c924013fc3fe40d6f1ec1dc20214183bc97') }
    let(:x509_commit) { Gitlab::X509::Commit.new(x509_signed_commit).signature }

    it 'changes from unverified to verified if the certificate store contains the root certificate' do
      x509_commit

      store = OpenSSL::X509::Store.new
      certificate = OpenSSL::X509::Certificate.new X509Helpers::User1.trust_cert
      store.add_cert(certificate)
      allow(OpenSSL::X509::Store).to receive(:new).and_return(store)

      expect(x509_commit.verification_status).to eq('unverified')
      expect_any_instance_of(Gitlab::X509::Commit).to receive(:update_signature!).and_call_original

      subject

      x509_commit.reload
      expect(x509_commit.verification_status).to eq('verified')
    end

    it 'returns if no signature is available' do
      expect_any_instance_of(Gitlab::X509::Commit) do |x509_commit|
        expect(x509_commit).not_to receive(:update_signature!)

        subject
      end
    end
  end
end
