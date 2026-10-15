# frozen_string_literal: true

require 'spec_helper'
require 'digest'

RSpec.describe SupplyChain::ProvenancePublisher, feature_category: :artifact_security do
  let(:publisher) { described_class.new(build) }

  include_context 'with mocked cosign execution'

  describe '#initialize' do
    context 'when a nil build is passed' do
      let(:build) { nil }

      it 'raises the appropriate exception' do
        expect { publisher }.to raise_exception(described_class::Error)
      end
    end

    context "when id_token is nil" do
      before do
        allow(build).to receive(:project).and_return(nil)
      end

      it 'raises the appropriate exception' do
        expect { publisher }.to raise_exception(described_class::JwtGenerationError)
      end
    end
  end

  describe '#cosign_attest_blob' do
    let(:hash) { "5db1fee4b5703808c48078a76768b155b421b210c0761cd6a5d223f4d99f1eaa" }
    let(:blob_name) { "test.txt" }

    subject(:cosign_attest_blob) do
      publisher.send(:cosign_attest_blob, blob_name: 'test.txt', hash: hash)
    end

    context "when called normally" do
      it 'calls the validate* methods' do
        expect(publisher).to receive(:validate_blob_name!).with(blob_name)
        expect(publisher).to receive(:validate_hash!).with(hash)
        expect(publisher).to receive(:validate_id_token!).with(publisher.send(:id_token))

        cosign_attest_blob
      end
    end

    context 'when popen returns an error' do
      let(:popen_success) { false }

      it 'raises the appropriate exception' do
        expect { cosign_attest_blob }.to raise_exception(described_class::AttestationFailure)
      end
    end
  end

  describe '#cosign_import_key_pair' do
    let(:leaf_key) { OpenSSL::PKey::EC.generate(SupplyChain::RootCaDriver::EC_CURVE) }
    let(:dir) { Dir.tmpdir }

    subject(:imported) { publisher.send(:cosign_import_key_pair, key: leaf_key, dir: dir) }

    it 'imports the key over stdin with a random password in the environment', :aggregate_failures do
      expect(imported).to match(key_path: File.join(dir, 'cosign.key'), password: match(/\A\h{64}\z/))
      expect(Gitlab::Popen).to have_received(:popen_with_detail).with(
        ['cosign', 'import-key-pair', '--yes', '--key', '/dev/stdin', '--output-key-prefix', File.join(dir, 'cosign')],
        nil,
        { 'COSIGN_PASSWORD' => imported[:password] }
      )
      expect(popen_stdin_file).to have_received(:write).with(leaf_key.private_to_pem)
    end

    it 'validates the dir before running cosign', :aggregate_failures do
      expect(publisher).to receive(:validate_key_dir!).with(dir).and_raise(described_class::InvalidInput)

      expect { imported }.to raise_exception(described_class::InvalidInput)
      expect(Gitlab::Popen).not_to have_received(:popen_with_detail)
    end

    it 'generates a different password for each import' do
      expect(imported[:password]).not_to eq(publisher.send(:cosign_import_key_pair, key: leaf_key, dir: dir)[:password])
    end

    context 'when cosign fails' do
      let(:popen_success) { false }

      it 'raises KeyImportFailure with the cosign error' do
        expect { imported }.to raise_error(described_class::KeyImportFailure,
          "Key import failed after #{expected_duration}s: #{expected_stderr}")
      end
    end
  end

  describe '#with_local_ca_signing_material' do
    def with_signing_material(&block)
      publisher.send(:with_local_ca_signing_material, &block)
    end

    it 'yields signing material for a fresh leaf certificate and removes it afterwards', :aggregate_failures do
      material_dir = nil

      with_signing_material do |material|
        material_dir = File.dirname(material.certificate_path)
        certificate = OpenSSL::X509::Certificate.new(File.read(material.certificate_path))
        leaf_private_key = satisfy { |pem| OpenSSL::PKey.read(pem).public_to_pem == certificate.public_key.public_to_pem }

        # cosign is mocked, so this only proves we never write the plaintext leaf key ourselves.
        expect(Dir.children(material_dir)).to contain_exactly('leaf.crt.pem')
        expect(File.stat(material.certificate_path).mode & 0o777).to eq(0o600)
        expect(certificate.extensions.find { |ext| ext.oid == 'subjectAltName' }.value)
          .to include(pipeline.ci_config_ref_uri)
        expect(popen_stdin_file).to have_received(:write).with(leaf_private_key)
        expect(material.key_path).to eq(File.join(material_dir, 'cosign.key'))
        expect(Gitlab::Popen).to have_received(:popen_with_detail)
          .with(array_including('import-key-pair'), nil, { 'COSIGN_PASSWORD' => material.password })
        expect(material.signing_certificate_id)
          .to eq(SupplyChain::SigningCertificate.for_project(project).with_active.sole.id)
      end

      expect(Dir).not_to exist(material_dir)
    end

    it 'removes the signing material and re-raises errors from the block unchanged', :aggregate_failures do
      material_dir = nil

      expect do
        with_signing_material do |material|
          material_dir = File.dirname(material.certificate_path)
          raise described_class::AttestationFailure, 'attest-blob failed'
        end
      end.to raise_error(described_class::AttestationFailure, 'attest-blob failed')

      expect(Dir).not_to exist(material_dir)
    end

    shared_examples 'a signing material failure' do
      it 'raises without yielding and removes the signing material', :aggregate_failures do
        material_dir = nil
        allow(Dir).to receive(:mktmpdir).and_wrap_original do |original, *args, &block|
          original.call(*args) { |dir| block.call(material_dir = dir) }
        end
        yielded = false

        expect { with_signing_material { yielded = true } }.to raise_error(expected_error, expected_message)

        expect(yielded).to be(false)
        expect(Dir).not_to exist(material_dir)
      end
    end

    context 'when the CA driver fails' do
      let(:expected_error) { described_class::LocalCaSigningError }
      let(:expected_message) { 'Unable to prepare local CA signing material: CA certificate expired' }

      before do
        allow_next_instance_of(SupplyChain::PostgresCaDriver) do |driver|
          allow(driver).to receive(:generate_leaf_certificate)
            .and_raise(SupplyChain::RootCaDriver::InvalidCaCertificate, 'CA certificate expired')
        end
      end

      it_behaves_like 'a signing material failure'
    end

    context 'when cosign fails to import the leaf key' do
      let(:popen_success) { false }
      let(:expected_error) { described_class::KeyImportFailure }
      let(:expected_message) { "Key import failed after #{expected_duration}s: #{expected_stderr}" }

      it_behaves_like 'a signing material failure'
    end
  end

  describe '#validate_id_token!' do
    subject(:validate_id_token) { publisher.send(:validate_id_token!, id_token) }

    context "when an valid looking JWT is passed" do
      it 'does not raise_error when a valid JWT is passed' do
        expect { validate_id_token }.not_to raise_error
      end
    end

    context "when random text is passed" do
      let(:id_token) { "this is very interesting. but not a JWT. Despite having three dots. etc" }

      it 'raises an InvalidInput Error' do
        expect { validate_id_token }.to raise_exception(described_class::InvalidInput)
      end
    end

    context "when path traversal is passed" do
      let(:id_token) { "../../../etc/passwd" }

      it 'raises the appropriate exception' do
        expect { validate_id_token }.to raise_exception(Gitlab::PathTraversal::PathTraversalAttackError)
      end
    end
  end

  describe '#validate_hash!' do
    subject(:validate_hash) { publisher.send(:validate_hash!, hash) }

    context "when an valid SHA-256 is passed" do
      let(:hash) { "5db1fee4b5703808c48078a76768b155b421b210c0761cd6a5d223f4d99f1eaa" }

      it 'does not raise an error' do
        expect { validate_hash }.not_to raise_error
      end
    end

    context "when an invalid SHA-256 is passed" do
      let(:hash) { "sample invalid input" }

      it 'raises InvalidInput' do
        expect { validate_hash }.to raise_exception(described_class::InvalidInput)
      end
    end
  end

  describe '#validate_blob_name!' do
    subject(:validate_blob_name) { publisher.send(:validate_blob_name!, blob_name) }

    context "when a valid base name is passed" do
      let(:blob_name) { "artifact.tar.gz" }

      it 'does not raise an error' do
        expect { validate_blob_name }.not_to raise_error
      end
    end

    context "when valid name including underscore and dash is passed" do
      let(:blob_name) { "artifact_final-1.tar.gz" }

      it 'does not raise an error' do
        expect { validate_blob_name }.not_to raise_error
      end
    end

    context "when a full path is passed" do
      let(:blob_name) { "path/artifact.tar.gz" }

      it 'raises an exception' do
        expect { validate_blob_name }.to raise_exception(described_class::InvalidInput)
      end
    end

    context "when path traversal is passed" do
      let(:blob_name) { "../../path/artifact.tar.gz" }

      it 'raises an exception' do
        expect { validate_blob_name }.to raise_exception(Gitlab::PathTraversal::PathTraversalAttackError)
      end
    end
  end

  describe '#validate_key_dir!' do
    subject(:validate_key_dir) { publisher.send(:validate_key_dir!, dir) }

    context "when an existing absolute directory is passed" do
      let(:dir) { Dir.tmpdir }

      it 'does not raise an error' do
        expect { validate_key_dir }.not_to raise_error
      end
    end

    context "when nil is passed" do
      let(:dir) { nil }

      it 'raises InvalidInput' do
        expect { validate_key_dir }.to raise_exception(described_class::InvalidInput)
      end
    end

    context "when a Pathname is passed" do
      let(:dir) { Pathname.new(Dir.tmpdir) }

      it 'raises InvalidInput' do
        expect { validate_key_dir }.to raise_exception(described_class::InvalidInput)
      end
    end

    context "when a relative path to an existing directory that looks like an option is passed" do
      let(:dir) { "--yes" }

      around do |example|
        Dir.mktmpdir do |tmp|
          Dir.chdir(tmp) do
            Dir.mkdir(dir)
            example.run
          end
        end
      end

      it 'raises InvalidInput' do
        expect { validate_key_dir }.to raise_exception(described_class::InvalidInput)
      end
    end

    context "when a directory that does not exist is passed" do
      let(:dir) { File.join(Dir.tmpdir, "missing-#{SecureRandom.hex(8)}") }

      it 'raises InvalidInput' do
        expect { validate_key_dir }.to raise_exception(described_class::InvalidInput)
      end
    end

    context "when path traversal is passed" do
      let(:dir) { File.join(Dir.tmpdir, "../etc") }

      it 'raises an exception' do
        expect { validate_key_dir }.to raise_exception(Gitlab::PathTraversal::PathTraversalAttackError)
      end
    end
  end

  describe '#id_token' do
    subject(:id_token) { publisher.send(:id_token) }

    context "when run normally" do
      it "is expected to return a valid JWT token" do
        sub_components = build.project.ci_id_token_sub_claim_components.map(&:to_sym)
        return_value = "test.test.test"
        expect(Gitlab::Ci::JwtV2).to receive(:for_build).with(build, aud: "sigstore",
          sub_components: sub_components).and_return(return_value)

        expect(id_token).to eq(return_value)
      end
    end
  end
end
