# frozen_string_literal: true

require 'spec_helper'

RSpec.describe X509CertificateRevokeService, feature_category: :system_access do
  describe '#execute' do
    let(:service) { described_class.new }
    let!(:x509_signature_1) { create(:x509_commit_signature, x509_certificate: x509_certificate, verification_status: :verified) }
    let!(:x509_signature_2) { create(:x509_commit_signature, x509_certificate: x509_certificate, verification_status: :verified) }

    context 'for revoked certificates' do
      let(:x509_certificate) { create(:x509_certificate, certificate_status: :revoked) }

      it 'update all commit signatures' do
        expect do
          service.execute(x509_certificate)

          x509_signature_1.reload
          x509_signature_2.reload
        end
          .to change(x509_signature_1, :verification_status).from('verified').to('unverified')
          .and change(x509_signature_2, :verification_status).from('verified').to('unverified')
      end
    end

    context 'for good certificates' do
      let(:x509_certificate) { create(:x509_certificate) }

      it 'do not update any commit signature' do
        expect do
          service.execute(x509_certificate)

          x509_signature_1.reload
          x509_signature_2.reload
        end
          .to not_change(x509_signature_1, :verification_status)
          .and not_change(x509_signature_2, :verification_status)
      end
    end
  end
end
