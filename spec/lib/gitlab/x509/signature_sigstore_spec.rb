# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::X509::Signature, feature_category: :source_code_management do
  subject(:signature) do
    described_class.new(
      signature_text,
      signed_text,
      email,
      created_at,
      project
    )
  end

  let_it_be(:project) { create(:project) }

  let(:signature_text) { X509Helpers::User2.signed_commit_signature }
  let(:signed_text) { X509Helpers::User2.signed_commit_base_data }
  let(:email) { X509Helpers::User2.certificate_email }
  let(:created_at) { X509Helpers::User2.signed_commit_time }

  let(:issuer_attributes) do
    {
      subject_key_identifier: X509Helpers::User2.issuer_subject_key_identifier,
      subject: X509Helpers::User2.certificate_issuer,
      project_id: project.id
    }
  end

  it_behaves_like 'signature with type checking', :x509

  context 'with commit signature' do
    let(:certificate_attributes) do
      {
        subject_key_identifier: X509Helpers::User2.certificate_subject_key_identifier,
        subject: X509Helpers::User2.certificate_subject,
        email: X509Helpers::User2.certificate_email,
        emails: [X509Helpers::User2.certificate_email],
        serial_number: X509Helpers::User2.certificate_serial,
        project_id: project.id
      }
    end

    context 'with verified signature' do
      context 'with trusted certificate store' do
        it_behaves_like 'x509 signature with trusted certificate store',
          user_helper: X509Helpers::User2,
          verified_status: :unverified,  # TODO sigstore support pending
          verified_signature: false
      end

      context 'with the certificate defined by OpenSSL::X509::DEFAULT_CERT_FILE' do
        it_behaves_like 'x509 signature with default cert file',
          user_helper: X509Helpers::User2,
          verified_status: :unverified,  # TODO sigstore support pending
          verified_signature: false
      end

      context 'without trusted certificate within store' do
        it_behaves_like 'x509 signature without trusted certificate'
      end
    end

    it_behaves_like 'x509 signature invalid scenarios'
  end

  context 'with email' do
    it_behaves_like 'x509 signature email extraction'
  end

  it_behaves_like 'x509 signature signed_by_user', user_helper: X509Helpers::User2

  context 'with tag signature' do
    let(:signature_text) { X509Helpers::User2.signed_tag_signature }
    let(:signed_text) { X509Helpers::User2.signed_tag_base_data }

    let(:certificate_attributes) do
      {
        subject_key_identifier: X509Helpers::User2.tag_certificate_subject_key_identifier,
        subject: X509Helpers::User2.certificate_subject,
        email: X509Helpers::User2.certificate_email,
        emails: [X509Helpers::User2.certificate_email],
        serial_number: X509Helpers::User2.tag_certificate_serial,
        project_id: project.id
      }
    end

    let(:issuer_attributes) do
      {
        subject_key_identifier: X509Helpers::User2.tag_issuer_subject_key_identifier,
        subject: X509Helpers::User2.tag_certificate_issuer,
        project_id: project.id
      }
    end

    context 'with verified signature' do
      it_behaves_like 'x509 signature tag verification',
        user_helper: X509Helpers::User2,
        verified_status: :unverified, # TODO sigstore support pending
        verified_signature: false
    end

    it_behaves_like 'x509 signature invalid scenarios'
  end
end
