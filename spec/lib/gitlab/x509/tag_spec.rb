# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Gitlab::X509::Tag do
  subject(:signature) { described_class.new(tag).signature }

  describe '#signature' do
    let(:repository) { Gitlab::Git::Repository.new('default', TEST_REPO_PATH, '', 'group/project') }
    let(:project) { create(:project, :repository) }

    describe 'signed tag' do
      let(:tag) { project.repository.find_tag('v1.1.1') }
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

    context 'unsigned tag' do
      let(:tag) { project.repository.find_tag('v1.0.0') }

      it { expect(signature).to be_nil }
    end
  end
end
