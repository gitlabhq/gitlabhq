# frozen_string_literal: true

require 'spec_helper'

RSpec.describe X509CertificateRevokeWorker, feature_category: :source_code_management do
  describe '#perform' do
    context 'with a revoked certificate' do
      subject { described_class.new.perform(job_args) }

      let(:x509_certificate) { create(:x509_certificate, certificate_status: :revoked) }
      let(:job_args) { x509_certificate.id }

      it_behaves_like 'an idempotent worker'

      it 'executes the revoke service' do
        expect_next_instance_of(X509CertificateRevokeService) do |service|
          expect(service).to receive(:execute).with(x509_certificate)
        end

        subject
      end
    end
  end
end
