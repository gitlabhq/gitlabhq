# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SupplyChain::PostgresCaDriver, :freeze_time, feature_category: :artifact_security do
  let_it_be(:project) { create(:project) }

  let(:driver) { described_class.new(project) }
  let(:unusable_certificate) do
    key = OpenSSL::PKey::EC.generate(described_class::EC_CURVE)
    certificate = driver.send(:build_ca_certificate, key: key)
    certificate.not_after = 1.month.from_now
    certificate.sign(key, OpenSSL::Digest.new(described_class::DIGEST_ALGORITHM))

    create(:supply_chain_signing_certificate, project: project,
      private_key: key.to_pem, certificate: certificate.to_pem)
  end

  describe '#ca_certificate' do
    context 'when no certificate exists for the project' do
      it 'provisions and stores a new CA certificate' do
        expect { driver.ca_certificate }.to change { SupplyChain::SigningCertificate.count }.by(1)
      end

      it 'returns the certificate and stores an active record scoped to the project' do
        cert = driver.ca_certificate
        record = driver.signing_certificate

        expect(cert).to be_a(OpenSSL::X509::Certificate)
        expect(record).to be_a(SupplyChain::SigningCertificate)
        expect(record).to be_active
        expect(record.project).to eq(project)
        expect(record.certificate).to eq(cert.to_pem)
      end

      it 'generates a self-signed P-256 CA certificate with SHA-256' do
        cert = driver.ca_certificate

        expect(cert.signature_algorithm).to eq('ecdsa-with-SHA256')
        expect(cert.public_key.group.curve_name).to eq('prime256v1')
        expect(cert.subject).to eq(cert.issuer)
        expect(cert.verify(cert.public_key)).to be(true)
      end

      it 'marks the certificate as a CA with certificate signing key usage' do
        extensions = driver.ca_certificate.extensions.index_by(&:oid)

        expect(extensions['basicConstraints'].value).to eq('CA:TRUE')
        expect(extensions['basicConstraints'].critical?).to be(true)
        expect(extensions['keyUsage'].critical?).to be(true)
        expect(extensions['keyUsage'].value).to include('Certificate Sign')
        expect(extensions['subjectKeyIdentifier']).to be_present
      end

      it 'stores a private key matching the certificate' do
        cert = driver.ca_certificate
        key = OpenSSL::PKey.read(driver.signing_certificate.private_key)

        expect(cert.check_private_key(key)).to be(true)
      end

      it 'sets the expiry ten years out with clock skew tolerance' do
        cert = driver.ca_certificate

        expect(cert.not_before).to eq(described_class::CLOCK_SKEW.ago)
        expect(cert.not_after).to eq(described_class::CA_VALIDITY.from_now)
      end

      it 'uses a random serial number' do
        serials = [driver.ca_certificate, described_class.new(create(:project)).ca_certificate]
          .map { |cert| cert.serial.to_i }

        expect(serials.uniq.length).to eq(2)
        expect(serials).to all(be_positive)
      end
    end

    context 'when an active certificate exists for the project' do
      let_it_be(:existing) { create(:supply_chain_signing_certificate, project: project) }

      it 'returns it without creating a new record' do
        expect { expect(driver.ca_certificate.to_pem).to eq(existing.certificate) }
          .not_to change { SupplyChain::SigningCertificate.count }

        expect(driver.signing_certificate).to eq(existing)
      end
    end

    context 'when the active certificate has expired' do
      let!(:expired) do
        key = OpenSSL::PKey::EC.generate(described_class::EC_CURVE)
        certificate = driver.send(:build_ca_certificate, key: key)
        certificate.not_before = 2.days.ago
        certificate.not_after = 1.day.ago
        certificate.sign(key, OpenSSL::Digest.new(described_class::DIGEST_ALGORITHM))

        create(:supply_chain_signing_certificate, project: project).tap do |record|
          record.update_columns(private_key: key.to_pem, certificate: certificate.to_pem,
            expires_at: certificate.not_after)
        end
      end

      it 'raises without replacing the expired certificate' do
        expect { driver.ca_certificate }
          .to raise_error(described_class::InvalidCaCertificate)
          .and not_change { SupplyChain::SigningCertificate.count }

        expect(expired.reload).to be_active
      end
    end

    context 'when the active certificate expires before a new leaf certificate would' do
      let!(:expiring) do
        key = OpenSSL::PKey::EC.generate(described_class::EC_CURVE)
        certificate = driver.send(:build_ca_certificate, key: key)
        certificate.not_after = (described_class::LEAF_VALIDITY + described_class::CLOCK_SKEW - 1.second).from_now
        certificate.sign(key, OpenSSL::Digest.new(described_class::DIGEST_ALGORITHM))

        create(:supply_chain_signing_certificate, project: project,
          private_key: key.to_pem, certificate: certificate.to_pem)
      end

      it 'raises without replacing the expiring certificate' do
        expect { driver.ca_certificate }
          .to raise_error(described_class::InvalidCaCertificate)
          .and not_change { SupplyChain::SigningCertificate.count }

        expect(expiring.reload).to be_active
      end
    end

    context 'when an inactive certificate exists for the project' do
      let!(:inactive) { create(:supply_chain_signing_certificate, :inactive, project: project) }

      it 'ignores it and provisions a new active certificate' do
        driver.ca_certificate

        expect(driver.signing_certificate).not_to eq(inactive)
        expect(driver.signing_certificate).to be_active
      end
    end

    context 'when a concurrent process stores the first certificate' do
      it 'returns the concurrently created certificate' do
        winner = create(:supply_chain_signing_certificate, project: project)

        allow(driver).to receive(:find_active_certificate).and_return(nil, winner)

        expect(driver.ca_certificate.to_pem).to eq(winner.certificate)
        expect(winner.reload).to be_active
        expect(SupplyChain::SigningCertificate.where(project: project).count).to eq(1)
      end

      it 'returns the winner when model validation detects the conflict' do
        winner = create(:supply_chain_signing_certificate, project: project)
        conflict = SupplyChain::SigningCertificate.new(active: true)
        conflict.errors.add(:active, :taken)

        allow(driver).to receive(:find_active_certificate).and_return(nil, nil, winner)
        allow(SupplyChain::SigningCertificate).to receive(:create!)
          .and_raise(ActiveRecord::RecordInvalid.new(conflict))

        expect(driver.ca_certificate.to_pem).to eq(winner.certificate)
      end

      it 're-raises when no certificate can be found after the conflict' do
        allow(driver).to receive(:find_active_certificate).and_return(nil)
        allow(SupplyChain::SigningCertificate).to receive(:create!).and_raise(ActiveRecord::RecordNotUnique)

        expect { driver.ca_certificate }.to raise_error(ActiveRecord::RecordNotUnique)
      end

      it 're-raises unrelated validation errors' do
        invalid_certificate = SupplyChain::SigningCertificate.new
        error = ActiveRecord::RecordInvalid.new(invalid_certificate)

        allow(SupplyChain::SigningCertificate).to receive(:create!).and_raise(error)

        expect { driver.ca_certificate }.to raise_error(error)
      end

      it 'raises instead of replacing an unusable certificate stored by the other process' do
        allow(driver).to receive(:find_active_certificate).and_return(nil, unusable_certificate)

        expect { driver.ca_certificate }
          .to raise_error(described_class::InvalidCaCertificate, /unusable active CA certificate already exists/)
          .and not_change { SupplyChain::SigningCertificate.count }
      end

      it 'rejects an unusable winner' do
        allow(driver).to receive(:find_active_certificate).and_return(nil, nil, unusable_certificate)
        allow(SupplyChain::SigningCertificate).to receive(:create!).and_raise(ActiveRecord::RecordNotUnique)

        expect { driver.ca_certificate }.to raise_error(described_class::InvalidCaCertificate)
      end
    end
  end

  describe '#signing_certificate' do
    it 'provisions the CA when called first' do
      expect { driver.signing_certificate }.to change { SupplyChain::SigningCertificate.count }.by(1)
    end

    it 'memoizes the record' do
      driver.signing_certificate

      expect(driver).not_to receive(:find_active_certificate)

      driver.signing_certificate
    end

    it 'does not cache a rejected certificate' do
      unusable_certificate

      expect { driver.signing_certificate }.to raise_error(described_class::InvalidCaCertificate)

      unusable_certificate.update_columns(active: false)
      replacement = create(:supply_chain_signing_certificate, project: project)

      expect(driver.signing_certificate).to eq(replacement)
    end

    it 'switches to a replacement certificate on the next CA lookup' do
      original = driver.signing_certificate
      original.update_columns(active: false)
      replacement = create(:supply_chain_signing_certificate, project: project)

      replacement_ca = driver.ca_certificate

      expect(replacement_ca.to_pem).to eq(replacement.certificate)
      expect(driver.signing_certificate).to eq(replacement)
    end
  end

  describe '#generate_leaf_certificate' do
    let(:ci_config_ref_uri) { 'gitlab.example.com/group/project//.gitlab-ci.yml@refs/heads/main' }

    subject(:leaf) { driver.generate_leaf_certificate(ci_config_ref_uri: ci_config_ref_uri) }

    it 'returns an in-memory key and certificate without persisting anything' do
      driver.ca_certificate # settle CA creation first

      expect { leaf }.not_to change { SupplyChain::SigningCertificate.count }
      expect(leaf.key).to be_a(OpenSSL::PKey::EC)
      expect(leaf.certificate).to be_a(OpenSSL::X509::Certificate)
    end

    it 'signs the certificate with the CA key' do
      ca_cert = driver.ca_certificate

      expect(leaf.certificate.verify(ca_cert.public_key)).to be(true)
      expect(leaf.certificate.issuer).to eq(ca_cert.subject)
    end

    it 'generates a P-256 key that matches the certificate' do
      expect(leaf.key.group.curve_name).to eq('prime256v1')
      expect(leaf.certificate.check_private_key(leaf.key)).to be(true)
      expect(leaf.certificate.signature_algorithm).to eq('ecdsa-with-SHA256')
    end

    it 'places the identity in a subject alternative name URI entry' do
      extensions = leaf.certificate.extensions.index_by(&:oid)

      expected_uri = "#{Gitlab.config.gitlab.protocol}://#{ci_config_ref_uri}"

      expect(extensions['subjectAltName'].value).to eq("URI:#{expected_uri}")
      expect(extensions['subjectAltName'].critical?).to be(true)
    end

    it 'includes the Fulcio OIDC issuer extension with the instance URL' do
      extension = leaf.certificate.extensions.find do |ext|
        ext.oid == described_class::FULCIO_ISSUER_OID
      end

      decoded = OpenSSL::ASN1.decode(extension.value_der)

      expect(decoded.value).to eq(Gitlab.config.gitlab.url)
    end

    it 'is not usable as a CA and is limited to digital signatures' do
      extensions = leaf.certificate.extensions.index_by(&:oid)

      expect(extensions['basicConstraints'].value).to eq('CA:FALSE')
      expect(extensions['basicConstraints'].critical?).to be(true)
      expect(extensions['keyUsage'].value).to eq('Digital Signature')
      expect(extensions['keyUsage'].critical?).to be(true)
      expect(extensions['extendedKeyUsage'].value).to eq('Code Signing')
      expect(extensions['subjectKeyIdentifier']).to be_present
      expect(extensions['authorityKeyIdentifier']).to be_present

      ca_extensions = driver.ca_certificate.extensions.index_by(&:oid)

      expect(extensions['authorityKeyIdentifier'].value)
        .to eq(ca_extensions['subjectKeyIdentifier'].value)
    end

    it 'is valid for five years with clock skew tolerance' do
      expect(leaf.certificate.not_before).to eq(described_class::CLOCK_SKEW.ago)
      expect(leaf.certificate.not_after).to eq(described_class::LEAF_VALIDITY.from_now)
    end

    it 'generates a distinct key and serial for every call' do
      other = driver.generate_leaf_certificate(ci_config_ref_uri: ci_config_ref_uri)

      expect(leaf.key.to_pem).not_to eq(other.key.to_pem)
      expect(leaf.certificate.serial).not_to eq(other.certificate.serial)
    end

    it 'produces a key readable by generic PEM parsers' do
      parsed = OpenSSL::PKey.read(leaf.key.to_pem)

      expect(parsed.group.curve_name).to eq('prime256v1')
    end

    context 'when the ref uri contains DN and SAN metacharacters' do
      let(:ci_config_ref_uri) { 'gitlab.example.com/g/p//.gitlab-ci.yml@refs/heads/a,b=c+d' }

      it 'preserves the identity verbatim in the SAN' do
        expected_uri = "#{Gitlab.config.gitlab.protocol}://#{ci_config_ref_uri}"

        expect(leaf.certificate.extensions.find { |ext| ext.oid == 'subjectAltName' }.value)
          .to eq("URI:#{expected_uri}")
      end
    end

    context 'when the ref contains Unicode characters' do
      let(:ci_config_ref_uri) { 'gitlab.example.com/g/p//.gitlab-ci.yml@refs/heads/ü/unicode' }

      it 'percent-encodes the identity in the SAN' do
        expected_uri = "#{Gitlab.config.gitlab.protocol}://" \
          'gitlab.example.com/g/p//.gitlab-ci.yml@refs/heads/%C3%BC/unicode'

        expect(leaf.certificate.extensions.find { |ext| ext.oid == 'subjectAltName' }.value)
          .to eq("URI:#{expected_uri}")
      end
    end

    context 'when the CI config path is remote' do
      let(:ci_config_ref_uri) do
        'gitlab.example.com/g/p//https://example.com/pipeline.yml@refs/heads/main'
      end

      it 'preserves the nested URL in the SAN identity' do
        expected_uri = "#{Gitlab.config.gitlab.protocol}://#{ci_config_ref_uri}"

        expect(leaf.certificate.extensions.find { |ext| ext.oid == 'subjectAltName' }.value)
          .to eq("URI:#{expected_uri}")
      end
    end
  end
end
