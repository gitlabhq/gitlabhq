# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::X509::Signature, feature_category: :source_code_management do
  let(:issuer_attributes) do
    {
      subject_key_identifier: X509Helpers::User1.issuer_subject_key_identifier,
      subject: X509Helpers::User1.certificate_issuer,
      crl_url: X509Helpers::User1.certificate_crl
    }
  end

  it_behaves_like 'signature with type checking', :x509 do
    subject(:signature) do
      described_class.new(
        X509Helpers::User1.signed_commit_signature,
        X509Helpers::User1.signed_commit_base_data,
        X509Helpers::User1.certificate_email,
        X509Helpers::User1.signed_commit_time
      )
    end
  end

  shared_examples "a verified signature" do
    let!(:user) { create(:user, email: X509Helpers::User1.certificate_email) }

    subject(:signature) do
      described_class.new(
        X509Helpers::User1.signed_commit_signature,
        X509Helpers::User1.signed_commit_base_data,
        X509Helpers::User1.certificate_email,
        X509Helpers::User1.signed_commit_time
      )
    end

    it 'returns a verified signature if email does match' do
      expect(signature.x509_certificate).to have_attributes(certificate_attributes)

      expect(signature.x509_certificate.x509_issuer).to have_attributes(issuer_attributes)
      expect(signature.verified_signature).to be_truthy
      expect(signature.verification_status).to eq(:verified)
    end

    it 'returns a verified signature if email does match, case-insensitively' do
      signature = described_class.new(
        X509Helpers::User1.signed_commit_signature,
        X509Helpers::User1.signed_commit_base_data,
        X509Helpers::User1.certificate_email.upcase,
        X509Helpers::User1.signed_commit_time
      )

      expect(signature.x509_certificate).to have_attributes(certificate_attributes)
      expect(signature.x509_certificate.x509_issuer).to have_attributes(issuer_attributes)
      expect(signature.verified_signature).to be_truthy
      expect(signature.verification_status).to eq(:verified)
    end

    context 'when the certificate contains multiple emails' do
      before do
        allow_any_instance_of(described_class).to receive(:get_certificate_extension).and_call_original

        allow_any_instance_of(described_class).to receive(:get_certificate_extension)
          .with('subjectAltName')
          .and_return("email:gitlab2@example.com, othername:<unsupported>, email:#{X509Helpers::User1.certificate_email}")
      end

      context 'and the email matches one of them' do
        it 'returns a verified signature' do
          expect(signature.x509_certificate).to have_attributes(certificate_attributes.except(:email, :emails))
          expect(signature.x509_certificate.email).to eq('gitlab2@example.com')
          expect(signature.x509_certificate.emails).to contain_exactly('gitlab2@example.com', X509Helpers::User1.certificate_email)
          expect(signature.x509_certificate.x509_issuer).to have_attributes(issuer_attributes)
          expect(signature.verified_signature).to be_truthy
          expect(signature.verification_status).to eq(:verified)
        end
      end

      context 'when subjectAltName is missing' do
        before do
          allow_any_instance_of(described_class).to receive(:get_certificate_extension)
            .with('subjectAltName')
            .and_return(nil)
        end

        it 'returns nil' do
          expect(signature.x509_certificate).to be_nil
          expect(signature.verified_signature).to be_truthy
          expect(signature.verification_status).to eq(:unverified)
        end
      end
    end

    context "if the email matches but isn't confirmed" do
      let!(:user) { create(:user, :unconfirmed, email: X509Helpers::User1.certificate_email) }

      it "returns an unverified signature" do
        expect(signature.verification_status).to eq(:unverified)
      end
    end

    it 'returns an unverified signature if email does not match' do
      signature = described_class.new(
        X509Helpers::User1.signed_commit_signature,
        X509Helpers::User1.signed_commit_base_data,
        "gitlab@example.com",
        X509Helpers::User1.signed_commit_time
      )

      expect(signature.x509_certificate).to have_attributes(certificate_attributes)
      expect(signature.x509_certificate.x509_issuer).to have_attributes(issuer_attributes)
      expect(signature.verified_signature).to be_truthy
      expect(signature.verification_status).to eq(:unverified)
    end

    it 'returns an unverified signature if email does match and time is wrong' do
      signature = described_class.new(
        X509Helpers::User1.signed_commit_signature,
        X509Helpers::User1.signed_commit_base_data,
        X509Helpers::User1.certificate_email,
        Time.new(2020, 2, 22)
      )

      expect(signature.x509_certificate).to have_attributes(certificate_attributes)
      expect(signature.x509_certificate.x509_issuer).to have_attributes(issuer_attributes)
      expect(signature.verified_signature).to be_falsey
      expect(signature.verification_status).to eq(:unverified)
    end

    it 'returns an unverified signature if certificate is revoked' do
      expect(signature.verification_status).to eq(:verified)

      signature.x509_certificate.revoked!

      expect(signature.verification_status).to eq(:unverified)
    end
  end

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
        before do
          store = OpenSSL::X509::Store.new
          certificate = OpenSSL::X509::Certificate.new(X509Helpers::User1.trust_cert)
          store.add_cert(certificate)
          allow(OpenSSL::X509::Store).to receive(:new).and_return(store)
        end

        it_behaves_like "a verified signature"
      end

      context 'with the certificate defined by OpenSSL::X509::DEFAULT_CERT_FILE' do
        before do
          store = OpenSSL::X509::Store.new
          certificate = OpenSSL::X509::Certificate.new(X509Helpers::User1.trust_cert)
          file_path = Rails.root.join("tmp/cert.pem").to_s

          File.open(file_path, "wb") do |f|
            f.print certificate.to_pem
          end

          allow(Gitlab::X509::Certificate).to receive(:default_cert_file).and_return(file_path)

          allow(OpenSSL::X509::Store).to receive(:new).and_return(store)
        end

        it_behaves_like "a verified signature"
      end

      context 'without trusted certificate within store' do
        before do
          store = OpenSSL::X509::Store.new
          allow(OpenSSL::X509::Store).to receive(:new)
              .and_return(
                store
              )
        end

        it 'returns an unverified signature' do
          signature = described_class.new(
            X509Helpers::User1.signed_commit_signature,
            X509Helpers::User1.signed_commit_base_data,
            X509Helpers::User1.certificate_email,
            X509Helpers::User1.signed_commit_time
          )

          expect(signature.x509_certificate).to have_attributes(certificate_attributes)
          expect(signature.x509_certificate.x509_issuer).to have_attributes(issuer_attributes)
          expect(signature.verified_signature).to be_falsey
          expect(signature.verification_status).to eq(:unverified)
        end
      end
    end

    context 'invalid signature' do
      it 'returns nil' do
        signature = described_class.new(
          X509Helpers::User1.signed_commit_signature.tr('A', 'B'),
          X509Helpers::User1.signed_commit_base_data,
          X509Helpers::User1.certificate_email,
          X509Helpers::User1.signed_commit_time
        )
        expect(signature.x509_certificate).to be_nil
        expect(signature.verified_signature).to be_falsey
        expect(signature.verification_status).to eq(:unverified)
      end
    end

    context 'invalid commit message' do
      it 'returns nil' do
        signature = described_class.new(
          X509Helpers::User1.signed_commit_signature,
          'x',
          X509Helpers::User1.certificate_email,
          X509Helpers::User1.signed_commit_time
        )
        expect(signature.x509_certificate).to be_nil
        expect(signature.verified_signature).to be_falsey
        expect(signature.verification_status).to eq(:unverified)
      end
    end
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
        signature = described_class.new(
          X509Helpers::User1.signed_commit_signature,
          X509Helpers::User1.signed_commit_base_data,
          X509Helpers::User1.certificate_email,
          X509Helpers::User1.signed_commit_time
        )

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
        signature = described_class.new(
          X509Helpers::User1.signed_commit_signature,
          X509Helpers::User1.signed_commit_base_data,
          X509Helpers::User1.certificate_email,
          X509Helpers::User1.signed_commit_time
        )

        expect(signature.x509_certificate.x509_issuer.crl_url).to eq("http://cdp1.pca.dfn.de/dfn-ca-global-g2/pub/crl/cacrl.crl")
      end
    end
  end

  context 'email' do
    describe 'subjectAltName with email, othername' do
      before do
        allow_any_instance_of(described_class).to receive(:get_certificate_extension).and_call_original

        allow_any_instance_of(described_class).to receive(:get_certificate_extension)
          .with('subjectAltName')
          .and_return("email:gitlab@example.com, othername:<unsupported>")
      end

      let(:signature) do
        described_class.new(
          X509Helpers::User1.signed_commit_signature,
          X509Helpers::User1.signed_commit_base_data,
          'gitlab@example.com',
          X509Helpers::User1.signed_commit_time
        )
      end

      it 'extracts email' do
        expect(signature.x509_certificate.email).to eq("gitlab@example.com")
        expect(signature.x509_certificate.emails).to contain_exactly("gitlab@example.com")
      end

      context 'when there are multiple emails' do
        before do
          allow_any_instance_of(described_class).to receive(:get_certificate_extension)
            .with('subjectAltName')
            .and_return("email:gitlab@example.com, othername:<unsupported>, email:gitlab2@example.com")
        end

        it 'extracts all the emails' do
          expect(signature.x509_certificate.email).to eq("gitlab@example.com")
          expect(signature.x509_certificate.emails).to contain_exactly("gitlab@example.com", "gitlab2@example.com")
        end
      end
    end

    describe 'subjectAltName with othername, email' do
      before do
        allow_any_instance_of(described_class).to receive(:get_certificate_extension).and_call_original

        allow_any_instance_of(described_class).to receive(:get_certificate_extension)
          .with('subjectAltName')
          .and_return("othername:<unsupported>, email:gitlab@example.com")
      end

      it 'extracts email' do
        signature = described_class.new(
          X509Helpers::User1.signed_commit_signature,
          X509Helpers::User1.signed_commit_base_data,
          'gitlab@example.com',
          X509Helpers::User1.signed_commit_time
        )

        expect(signature.x509_certificate.email).to eq("gitlab@example.com")
      end
    end
  end

  describe '#signed_by_user' do
    subject do
      described_class.new(
        X509Helpers::User1.signed_tag_signature,
        X509Helpers::User1.signed_tag_base_data,
        X509Helpers::User1.certificate_email,
        X509Helpers::User1.signed_commit_time
      ).signed_by_user
    end

    context 'if email is assigned to a user' do
      let!(:signed_by_user) { create(:user, email: X509Helpers::User1.certificate_email) }

      it 'returns user' do
        is_expected.to eq(signed_by_user)
      end
    end

    it 'if email is not assigned to a user, return nil' do
      is_expected.to be_nil
    end
  end

  context 'tag signature' do
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
      let_it_be(:user) { create(:user, :unconfirmed, email: X509Helpers::User1.certificate_email) }

      subject(:signature) do
        described_class.new(
          X509Helpers::User1.signed_tag_signature,
          X509Helpers::User1.signed_tag_base_data,
          X509Helpers::User1.certificate_email,
          X509Helpers::User1.signed_commit_time
        )
      end

      context 'with trusted certificate store' do
        before do
          store = OpenSSL::X509::Store.new
          certificate = OpenSSL::X509::Certificate.new X509Helpers::User1.trust_cert
          store.add_cert(certificate)
          allow(OpenSSL::X509::Store).to receive(:new).and_return(store)
        end

        context 'when user email is confirmed' do
          before_all do
            user.confirm
          end

          it 'returns a verified signature if email does match', :aggregate_failures do
            expect(signature.x509_certificate).to have_attributes(certificate_attributes)
            expect(signature.x509_certificate.x509_issuer).to have_attributes(issuer_attributes)
            expect(signature.verified_signature).to be_truthy
            expect(signature.verification_status).to eq(:verified)
          end

          it 'returns an unverified signature if email does not match', :aggregate_failures do
            signature = described_class.new(
              X509Helpers::User1.signed_tag_signature,
              X509Helpers::User1.signed_tag_base_data,
              "gitlab@example.com",
              X509Helpers::User1.signed_commit_time
            )

            expect(signature.x509_certificate).to have_attributes(certificate_attributes)
            expect(signature.x509_certificate.x509_issuer).to have_attributes(issuer_attributes)
            expect(signature.verified_signature).to be_truthy
            expect(signature.verification_status).to eq(:unverified)
          end

          it 'returns an unverified signature if email does match and time is wrong', :aggregate_failures do
            signature = described_class.new(
              X509Helpers::User1.signed_tag_signature,
              X509Helpers::User1.signed_tag_base_data,
              X509Helpers::User1.certificate_email,
              Time.new(2020, 2, 22)
            )

            expect(signature.x509_certificate).to have_attributes(certificate_attributes)
            expect(signature.x509_certificate.x509_issuer).to have_attributes(issuer_attributes)
            expect(signature.verified_signature).to be_falsey
            expect(signature.verification_status).to eq(:unverified)
          end

          it 'returns an unverified signature if certificate is revoked' do
            expect(signature.verification_status).to eq(:verified)

            signature.x509_certificate.revoked!

            expect(signature.verification_status).to eq(:unverified)
          end
        end

        it 'returns an unverified signature if the email matches but is not confirmed' do
          expect(signature.verification_status).to eq(:unverified)
        end
      end

      context 'without trusted certificate within store' do
        before do
          store = OpenSSL::X509::Store.new
          allow(OpenSSL::X509::Store).to receive(:new)
              .and_return(
                store
              )
        end

        it 'returns an unverified signature' do
          expect(signature.x509_certificate).to have_attributes(certificate_attributes)
          expect(signature.x509_certificate.x509_issuer).to have_attributes(issuer_attributes)
          expect(signature.verified_signature).to be_falsey
          expect(signature.verification_status).to eq(:unverified)
        end
      end
    end

    context 'invalid signature' do
      it 'returns nil' do
        signature = described_class.new(
          X509Helpers::User1.signed_tag_signature.tr('A', 'B'),
          X509Helpers::User1.signed_tag_base_data,
          X509Helpers::User1.certificate_email,
          X509Helpers::User1.signed_commit_time
        )
        expect(signature.x509_certificate).to be_nil
        expect(signature.verified_signature).to be_falsey
        expect(signature.verification_status).to eq(:unverified)
      end
    end

    context 'invalid message' do
      it 'returns nil' do
        signature = described_class.new(
          X509Helpers::User1.signed_tag_signature,
          'x',
          X509Helpers::User1.certificate_email,
          X509Helpers::User1.signed_commit_time
        )
        expect(signature.x509_certificate).to be_nil
        expect(signature.verified_signature).to be_falsey
        expect(signature.verification_status).to eq(:unverified)
      end
    end
  end
end
