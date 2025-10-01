# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::X509::Signature, feature_category: :source_code_management do
  subject(:signature) do
    described_class.new(
      signature_text,
      signed_text,
      email,
      created_at
    )
  end

  let(:signature_text) { X509Helpers::User1.signed_commit_signature }
  let(:signed_text) { X509Helpers::User1.signed_commit_base_data }
  let(:email) { X509Helpers::User1.certificate_email }
  let(:created_at) { X509Helpers::User1.signed_commit_time }

  let(:issuer_attributes) do
    {
      subject_key_identifier: X509Helpers::User1.issuer_subject_key_identifier,
      subject: X509Helpers::User1.certificate_issuer,
      crl_url: X509Helpers::User1.certificate_crl
    }
  end

  it_behaves_like 'signature with type checking', :x509

  context 'commit signature' do
    let(:certificate_attributes) do
      {
        subject_key_identifier: X509Helpers::User1.certificate_subject_key_identifier,
        subject: X509Helpers::User1.certificate_subject,
        email: X509Helpers::User1.certificate_email,
        emails: [X509Helpers::User1.certificate_email],
        serial_number: X509Helpers::User1.certificate_serial
      }
    end

    context 'verified signature' do
      context 'with trusted certificate store' do
        it_behaves_like 'x509 signature with trusted certificate store', user_helper: X509Helpers::User1
      end

      context 'with the certificate defined by OpenSSL::X509::DEFAULT_CERT_FILE' do
        it_behaves_like 'x509 signature with default cert file',
          user_helper: X509Helpers::User1
      end

      context 'without trusted certificate within store' do
        it_behaves_like 'x509 signature without trusted certificate'
      end
    end

    it_behaves_like 'x509 signature invalid scenarios'
  end

  context 'certificate_crl' do
    describe 'valid crlDistributionPoints' do
      before do
        allow_any_instance_of(described_class).to receive(:get_certificate_extension).and_call_original

        allow_any_instance_of(described_class).to receive(:get_certificate_extension)
          .with('crlDistributionPoints')
          .and_return("\nFull Name:\n  URI:http://ch.siemens.com/pki?ZZZZZZA2.crl\n  URI:ldap://cl.siemens.net/CN=ZZZZZZA2,L=PKI?certificateRevocationList\n  URI:ldap://cl.siemens.com/CN=ZZZZZZA2,o=Trustcenter?certificateRevocationList\n")
      end

      it 'creates an issuer' do
        expect(signature.x509_certificate.x509_issuer).to have_attributes(issuer_attributes)
      end
    end

    describe 'valid crlDistributionPoints providing multiple http URIs' do
      before do
        allow_any_instance_of(described_class).to receive(:get_certificate_extension).and_call_original

        allow_any_instance_of(described_class).to receive(:get_certificate_extension)
          .with('crlDistributionPoints')
          .and_return("\nFull Name:\n  URI:http://cdp1.pca.dfn.de/dfn-ca-global-g2/pub/crl/cacrl.crl\n\nFull Name:\n  URI:http://cdp2.pca.dfn.de/dfn-ca-global-g2/pub/crl/cacrl.crl\n")
      end

      it 'extracts the first URI' do
        expect(signature.x509_certificate.x509_issuer.crl_url).to eq("http://cdp1.pca.dfn.de/dfn-ca-global-g2/pub/crl/cacrl.crl")
      end
    end
  end

  context 'email' do
    it_behaves_like 'x509 signature email extraction'
  end

  it_behaves_like 'x509 signature signed_by_user', user_helper: X509Helpers::User1

  context 'tag signature' do
    let(:signature_text) { X509Helpers::User1.signed_tag_signature }
    let(:signed_text) { X509Helpers::User1.signed_tag_base_data }

    let(:certificate_attributes) do
      {
        subject_key_identifier: X509Helpers::User1.tag_certificate_subject_key_identifier,
        subject: X509Helpers::User1.certificate_subject,
        email: X509Helpers::User1.certificate_email,
        emails: [X509Helpers::User1.certificate_email],
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

    context 'verified signature' do
      it_behaves_like 'x509 signature tag verification',
        user_helper: X509Helpers::User1
    end

    it_behaves_like 'x509 signature invalid scenarios'
  end
end
