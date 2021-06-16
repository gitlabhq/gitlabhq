# frozen_string_literal: true

require 'rake_helper'

RSpec.describe 'gitlab:x509 namespace rake task', :silence_stdout do
  before :all do
    Rake.application.rake_require 'tasks/gitlab/x509/update'
  end

  describe 'update_signatures' do
    let(:user) { create(:user, email: X509Helpers::User1.certificate_email) }
    let(:project) { create(:project, :repository, path: X509Helpers::User1.path, creator: user) }
    let(:x509_signed_commit) { project.commit_by(oid: '189a6c924013fc3fe40d6f1ec1dc20214183bc97') }
    let(:x509_commit) { Gitlab::X509::Commit.new(x509_signed_commit).signature }

    subject { run_rake_task('gitlab:x509:update_signatures') }

    it 'changes from unverified to verified if the certificate store contains the root certificate' do
      x509_commit

      store = OpenSSL::X509::Store.new
      certificate = OpenSSL::X509::Certificate.new X509Helpers::User1.trust_cert
      store.add_cert(certificate)
      allow(OpenSSL::X509::Store).to receive(:new).and_return(store)

      expect_any_instance_of(Gitlab::X509::Commit).to receive(:update_signature!).and_call_original
      expect { subject }.to change { x509_commit.reload.verification_status }.from('unverified').to('verified')
    end

    it 'returns if no signature is available' do
      expect_any_instance_of(Gitlab::X509::Commit).not_to receive(:update_signature!)

      subject
    end
  end
end
