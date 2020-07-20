# frozen_string_literal: true

require 'spec_helper'

RSpec.describe X509CertificateRevokeWorker do
  describe '#perform' do
    context 'with a revoked certificate' do
      subject { described_class.new }

      let(:x509_certificate) { create(:x509_certificate, certificate_status: :revoked) }
      let(:job_args) { x509_certificate.id }

      include_examples 'an idempotent worker' do
        it 'executes the revoke service' do
          spy_service = X509CertificateRevokeService.new

          allow(X509CertificateRevokeService).to receive(:new) { spy_service }

          expect(spy_service).to receive(:execute)
            .exactly(IdempotentWorkerHelper::WORKER_EXEC_TIMES).times
            .with(x509_certificate)
            .and_call_original

          subject
        end
      end

      it 'executes the revoke service' do
        spy_service = X509CertificateRevokeService.new

        allow(X509CertificateRevokeService).to receive(:new) { spy_service }

        expect_next_instance_of(X509CertificateRevokeService) do |service|
          expect(service).to receive(:execute).with(x509_certificate)
        end

        subject
      end
    end
  end
end
