# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Gitlab::X509::Tag, feature_category: :source_code_management do
  describe '#signature' do
    let(:tag_id) { 'v1.1.1' }
    let(:tag) { instance_double('Gitlab::Git::Tag') }
    let_it_be(:user) { create(:user, email: X509Helpers::User1.tag_email) }
    let_it_be(:project) { create(:project, path: X509Helpers::User1.path, creator: user) }
    let(:signature) { described_class.new(project.repository, tag).signature }

    before do
      allow(tag).to receive(:id).and_return(tag_id)
      allow(tag).to receive(:has_signature?).and_return(true)
      allow(tag).to receive(:user_email).and_return(user.email)
      allow(tag).to receive(:date).and_return(X509Helpers::User1.signed_tag_time)
      allow(Gitlab::Git::Tag).to receive(:extract_signature_lazily).with(project.repository, tag_id)
        .and_return([X509Helpers::User1.signed_tag_signature, X509Helpers::User1.signed_tag_base_data])
    end

    describe 'signed tag' do
      let(:certificate_attributes) do
        {
          subject_key_identifier: X509Helpers::User1.tag_certificate_subject_key_identifier,
          subject: X509Helpers::User1.certificate_subject,
          email: X509Helpers::User1.certificate_email,
          serial_number: X509Helpers::User1.tag_certificate_serial
        }
      end

      let(:issuer_attributes) do
        {
          subject_key_identifier: X509Helpers::User1.tag_issuer_subject_key_identifier,
          subject: X509Helpers::User1.tag_certificate_issuer,
          crl_url: X509Helpers::User1.tag_certificate_crl
        }
      end

      it { expect(signature).not_to be_nil }
      it { expect(signature.verification_status).to eq(:unverified) }
      it { expect(signature.x509_certificate).to have_attributes(certificate_attributes) }
      it { expect(signature.x509_certificate.x509_issuer).to have_attributes(issuer_attributes) }
    end
  end
end
