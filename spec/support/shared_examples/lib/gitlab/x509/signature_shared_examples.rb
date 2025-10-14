# frozen_string_literal: true

# Shared examples for X509 signature testing
# These examples are parameterized to handle differences between regular X509 and sigstore signatures

RSpec.shared_examples 'x509 signature verification scenarios' do
  |user_helper:, verified_status: :verified, verified_signature: true|
  let!(:user) { create(:user, email: user_helper.certificate_email) }

  it 'returns a verified signature if email does match' do
    expect(signature.x509_certificate).to have_attributes(certificate_attributes)
    expect(signature.x509_certificate.x509_issuer).to have_attributes(issuer_attributes)
    expect(signature.verified_signature).to be(verified_signature)
    expect(signature.verification_status).to eq(verified_status)
  end

  context 'when email is UPCASE' do
    let(:email) { super().upcase }

    it 'returns a verified signature if email does match, case-insensitively' do
      expect(signature.x509_certificate).to have_attributes(certificate_attributes)
      expect(signature.x509_certificate.x509_issuer).to have_attributes(issuer_attributes)
      expect(signature.verified_signature).to be(verified_signature)
      expect(signature.verification_status).to eq(verified_status)
    end
  end

  context 'when the certificate contains multiple emails' do
    before do
      allow_next_instance_of(described_class) do |instance|
        allow(instance).to receive(:get_certificate_extension).and_call_original
        allow(instance).to receive(:get_certificate_extension)
          .with('subjectAltName')
          .and_return("email:gitlab2@example.com, othername:<unsupported>, email:#{user_helper.certificate_email}")
      end
    end

    context 'and the email matches one of them' do
      it 'returns a verified signature' do
        expect(signature.x509_certificate).to have_attributes(certificate_attributes.except(:email, :emails))
        expect(signature.x509_certificate.email).to eq('gitlab2@example.com')
        expect(signature.x509_certificate.emails).to contain_exactly('gitlab2@example.com',
          user_helper.certificate_email)
        expect(signature.x509_certificate.x509_issuer).to have_attributes(issuer_attributes)
        expect(signature.verified_signature).to be(verified_signature)
        expect(signature.verification_status).to eq(verified_status)
      end
    end
  end

  context 'when subjectAltName is missing' do
    before do
      allow_next_instance_of(described_class) do |instance|
        allow(instance).to receive(:get_certificate_extension).and_call_original
        allow(instance).to receive(:get_certificate_extension)
          .with('subjectAltName')
          .and_return(nil)
      end
    end

    it 'returns nil' do
      expect(signature.x509_certificate).to be_nil
      expect(signature.verified_signature).to be(verified_signature)
      expect(signature.verification_status).to eq(:unverified)
    end
  end

  context 'when certificate has no email in subjectAltName' do
    before do
      allow_next_instance_of(described_class) do |instance|
        allow(instance).to receive(:get_certificate_extension).and_call_original
        allow(instance).to receive(:get_certificate_extension)
          .with('subjectAltName')
          .and_return("othername:<unsupported>, DNS:example.com")
      end
    end

    it 'returns nil' do
      expect(signature.x509_certificate).to be_nil
      expect(signature.verified_signature).to be(verified_signature)
      expect(signature.verification_status).to eq(:unverified)
    end
  end

  context 'when certificate has blank email in subjectAltName' do
    before do
      allow_next_instance_of(described_class) do |instance|
        allow(instance).to receive(:get_certificate_extension).and_call_original
        allow(instance).to receive(:get_certificate_extension)
          .with('subjectAltName')
          .and_return("email:")
      end
    end

    it 'returns nil' do
      expect(signature.x509_certificate).to be_nil
      expect(signature.verified_signature).to be(verified_signature)
      expect(signature.verification_status).to eq(:unverified)
    end
  end

  context "if the email matches but isn't confirmed" do
    let!(:user) { create(:user, :unconfirmed, email: user_helper.certificate_email) }

    it "returns an unverified signature" do
      expect(signature.verification_status).to eq(:unverified)
    end
  end

  context 'when email does not match' do
    let(:email) { "gitlab@example.com" }

    it 'returns an unverified signature' do
      expect(signature.x509_certificate).to have_attributes(certificate_attributes)
      expect(signature.x509_certificate.x509_issuer).to have_attributes(issuer_attributes)
      expect(signature.verified_signature).to be(verified_signature)
      expect(signature.verification_status).to eq(:unverified)
    end
  end

  context 'when created_at is wrong' do
    let(:created_at) { Time.zone.local(2020, 2, 22) }

    it 'returns an unverified signature' do
      expect(signature.x509_certificate).to have_attributes(certificate_attributes)
      expect(signature.x509_certificate.x509_issuer).to have_attributes(issuer_attributes)
      expect(signature.verified_signature).to be_falsey
      expect(signature.verification_status).to eq(:unverified)
    end
  end

  it 'returns an unverified signature if certificate is revoked' do
    expect(signature.verification_status).to eq(verified_status)

    signature.x509_certificate.revoked!

    expect(signature.verification_status).to eq(:unverified)
  end
end

RSpec.shared_examples 'x509 signature with trusted certificate store' do
  |user_helper:, verified_status: :verified, verified_signature: true|
  before do
    store = OpenSSL::X509::Store.new
    certificate = OpenSSL::X509::Certificate.new(user_helper.trust_cert)
    store.add_cert(certificate)
    allow(OpenSSL::X509::Store).to receive(:new).and_return(store)
  end

  it_behaves_like 'x509 signature verification scenarios',
    user_helper: user_helper,
    verified_status: verified_status,
    verified_signature: verified_signature
end

RSpec.shared_examples 'x509 signature with default cert file' do
  |user_helper:, verified_status: :verified, verified_signature: true|
  before do
    store = OpenSSL::X509::Store.new
    certificate = OpenSSL::X509::Certificate.new(user_helper.trust_cert)
    file_path = Rails.root.join("tmp/cert.pem").to_s

    File.open(file_path, "wb") do |f|
      f.print certificate.to_pem
    end

    allow(Gitlab::X509::Certificate).to receive(:default_cert_file).and_return(file_path)
    allow(OpenSSL::X509::Store).to receive(:new).and_return(store)
  end

  it_behaves_like 'x509 signature verification scenarios',
    user_helper: user_helper,
    verified_status: verified_status,
    verified_signature: verified_signature
end

RSpec.shared_examples 'x509 signature without trusted certificate' do
  before do
    store = OpenSSL::X509::Store.new
    allow(OpenSSL::X509::Store).to receive(:new).and_return(store)
  end

  it 'returns an unverified signature' do
    expect(signature.x509_certificate).to have_attributes(certificate_attributes)
    expect(signature.x509_certificate.x509_issuer).to have_attributes(issuer_attributes)
    expect(signature.verified_signature).to be_falsey
    expect(signature.verification_status).to eq(:unverified)
  end
end

RSpec.shared_examples 'x509 signature invalid scenarios' do
  context 'with invalid signature' do
    let(:signature_text) { super().tr('A', 'B') }

    it 'returns nil' do
      expect(signature.x509_certificate).to be_nil
      expect(signature.verified_signature).to be_falsey
      expect(signature.verification_status).to eq(:unverified)
    end
  end

  context 'with invalid message' do
    let(:signed_text) { 'x' }

    it 'returns nil' do
      expect(signature.x509_certificate).to be_nil
      expect(signature.verified_signature).to be_falsey
      expect(signature.verification_status).to eq(:unverified)
    end
  end
end

RSpec.shared_examples 'x509 signature email extraction' do
  describe 'subjectAltName with email, othername' do
    let(:email) { 'gitlab@example.com' }

    before do
      allow_next_instance_of(described_class) do |instance|
        allow(instance).to receive(:get_certificate_extension).and_call_original
        allow(instance).to receive(:get_certificate_extension)
          .with('subjectAltName')
          .and_return("email:gitlab@example.com, othername:<unsupported>")
      end
    end

    it 'extracts email' do
      expect(signature.x509_certificate.email).to eq("gitlab@example.com")
      expect(signature.x509_certificate.emails).to contain_exactly("gitlab@example.com")
    end

    context 'when there are multiple emails' do
      before do
        allow_next_instance_of(described_class) do |instance|
          allow(instance).to receive(:get_certificate_extension).and_call_original
          allow(instance).to receive(:get_certificate_extension)
            .with('subjectAltName')
            .and_return("email:gitlab@example.com, othername:<unsupported>, email:gitlab2@example.com")
        end
      end

      it 'extracts all the emails' do
        expect(signature.x509_certificate.email).to eq("gitlab@example.com")
        expect(signature.x509_certificate.emails).to contain_exactly("gitlab@example.com", "gitlab2@example.com")
      end
    end
  end

  describe 'subjectAltName with othername, email' do
    let(:email) { 'gitlab@example.com' }

    before do
      allow_next_instance_of(described_class) do |instance|
        allow(instance).to receive(:get_certificate_extension).and_call_original
        allow(instance).to receive(:get_certificate_extension)
          .with('subjectAltName')
          .and_return("othername:<unsupported>, email:gitlab@example.com")
      end
    end

    it 'extracts email' do
      expect(signature.x509_certificate.email).to eq("gitlab@example.com")
    end
  end
end

RSpec.shared_examples 'x509 signature signed_by_user' do |user_helper:|
  describe '#signed_by_user' do
    subject { signature.signed_by_user }

    context 'if email is assigned to a user' do
      let!(:signed_by_user) { create(:user, email: user_helper.certificate_email) }

      it 'returns user' do
        is_expected.to eq(signed_by_user)
      end
    end

    context 'if email is not assigned to a user' do
      it { is_expected.to be_nil }
    end
  end
end

RSpec.shared_examples 'x509 signature tag verification' do
  |user_helper:, verified_status: :verified, verified_signature: true|
  let_it_be(:user) { create(:user, :unconfirmed, email: user_helper.certificate_email) }

  context 'with trusted certificate store' do
    before do
      store = OpenSSL::X509::Store.new
      certificate = OpenSSL::X509::Certificate.new user_helper.trust_cert
      store.add_cert(certificate)
      allow(OpenSSL::X509::Store).to receive(:new).and_return(store)
    end

    context 'when user email is confirmed' do
      before_all do
        user.confirm
      end

      it 'returns a verified signature', :aggregate_failures do
        expect(signature.x509_certificate).to have_attributes(certificate_attributes)
        expect(signature.x509_certificate.x509_issuer).to have_attributes(issuer_attributes)
        expect(signature.verified_signature).to be(verified_signature)
        expect(signature.verification_status).to eq(verified_status)
      end

      context 'when email does not match' do
        let(:email) { "gitlab@example.com" }

        it 'returns an unverified signature', :aggregate_failures do
          expect(signature.x509_certificate).to have_attributes(certificate_attributes)
          expect(signature.x509_certificate.x509_issuer).to have_attributes(issuer_attributes)
          expect(signature.verified_signature).to be(verified_signature)
          expect(signature.verification_status).to eq(:unverified)
        end
      end

      context 'when created_at is wrong' do
        let(:created_at) { Time.zone.local(2020, 2, 22) }

        it 'returns an unverified signature', :aggregate_failures do
          expect(signature.x509_certificate).to have_attributes(certificate_attributes)
          expect(signature.x509_certificate.x509_issuer).to have_attributes(issuer_attributes)
          expect(signature.verified_signature).to be_falsey
          expect(signature.verification_status).to eq(:unverified)
        end
      end

      it 'returns an unverified signature if certificate is revoked' do
        expect(signature.verification_status).to eq(verified_status)

        signature.x509_certificate.revoked!

        expect(signature.verification_status).to eq(:unverified)
      end
    end

    context 'when user email is not confirmed' do
      it 'returns an unverified signature' do
        expect(signature.verification_status).to eq(:unverified)
      end
    end
  end

  it_behaves_like 'x509 signature without trusted certificate'
end
