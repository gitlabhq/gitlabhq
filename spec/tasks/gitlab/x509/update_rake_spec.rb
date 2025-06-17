# frozen_string_literal: true

require 'spec_helper'

# rubocop:disable RSpec/AvoidTestProf -- this is not a migration spec
RSpec.describe 'gitlab:x509 namespace rake task', :silence_stdout, feature_category: :source_code_management do
  before(:all) do
    Rake.application.rake_require 'tasks/gitlab/x509/update'
  end

  describe 'update_signatures' do
    subject { run_rake_task('gitlab:x509:update_signatures') }

    context 'with commit signatures' do
      let_it_be(:user) { create(:user, email: X509Helpers::User1.certificate_email) }
      let_it_be(:project) { create(:project, :repository, path: X509Helpers::User1.path, creator: user) }

      let!(:x509_commit_signature) do
        create(:x509_commit_signature, project: project, verification_status: :unverified,
          commit_sha: x509_signed_commit.sha)
      end

      let(:x509_signed_commit) { project.commit_by(oid: '189a6c924013fc3fe40d6f1ec1dc20214183bc97') }
      let(:x509_commit) { x509_commit_signature.x509_commit }

      let(:store) { OpenSSL::X509::Store.new.tap { |s| s.add_cert(certificate) } }
      let(:certificate) { OpenSSL::X509::Certificate.new(X509Helpers::User1.trust_cert) }

      before do
        allow(OpenSSL::X509::Store).to receive(:new).and_return(store)

        allow(Gitlab::X509::Commit).to receive(:new).and_return(x509_commit)
      end

      it 'changes from unverified to verified if the certificate store contains the root certificate' do
        expect(x509_commit).to receive(:update_signature!).and_call_original

        expect { subject }.to change {
          x509_commit_signature.reload.verification_status
        }.from('unverified').to('verified')
      end

      context 'when error occurrs' do
        let(:grpc_deadline_error) { GRPC::DeadlineExceeded.new('deadline exceeded') }

        it 'retries updating signature on GRPC::DeadlineExceeded error' do
          # Simulate GRPC::DeadlineExceeded on first `update_signature!` call, then succeed
          # Note: Using the mock helper `expect_any_instance_of` leads to a mock error,
          # see https://gitlab.com/gitlab-org/gitlab/-/merge_requests/192543#note_2526028297.
          expect(x509_commit).to receive(:update_signature!).and_raise(grpc_deadline_error)
          expect(x509_commit).to receive(:update_signature!).and_call_original

          expect { subject }.to change {
            x509_commit_signature.reload.verification_status
          }.from('unverified').to('verified')
        end

        it 'raises GRPC::DeadlineExceeded error if the retry limit is reached (by default 5 times)' do
          expect(x509_commit).to(receive(:update_signature!).exactly(5).times.and_raise(grpc_deadline_error))

          expect { subject }.to raise_error(GRPC::DeadlineExceeded)
        end

        context 'when GRPC_DEADLINE_EXCEEDED_RETRY_LIMIT is set' do
          before do
            stub_env('GRPC_DEADLINE_EXCEEDED_RETRY_LIMIT' => '2')
          end

          it 'raises GRPC::DeadlineExceeded error if the set retry limit is reached' do
            expect(x509_commit).to(receive(:update_signature!).twice.and_raise(grpc_deadline_error))

            expect { subject }.to raise_error(GRPC::DeadlineExceeded)
          end
        end

        it 'raises errors by default' do
          expect(x509_commit).to(receive(:update_signature!).and_raise(StandardError, 'Some error'))

          expect { subject }.to raise_error(StandardError)
        end
      end

      it 'logs debug message for each updated signature' do
        logger = Logger.new($stdout)

        allow(Gitlab::X509::Commit).to receive(:new).and_return(x509_commit)
        expect(x509_commit).to receive(:update_signature!).and_call_original

        allow(Logger).to receive(:new).and_return(logger)
        expect(logger).to receive(:debug) do |_, &block|
          expect(block.call).to start_with('Start to update x509 commit signature')
        end

        expect { subject }.to change { x509_commit_signature.reload.verification_status }
          .from('unverified').to('verified')
      end
    end

    context 'without commit signatures' do
      it 'returns if no signature is available' do
        expect_any_instance_of(Gitlab::X509::Commit).not_to receive(:update_signature!)

        subject
      end
    end
  end
end
# rubocop:enable RSpec/AvoidTestProf
