# frozen_string_literal: true

require 'spec_helper'
require 'digest'

SLSA_ATTESTATION_BUNDLE = 'app/validators/json_schemas/slsa/in_toto_v1/provenance_v1.json'

RSpec.describe Ci::Slsa::PublishProvenanceService, feature_category: :artifact_security do
  let(:service) { described_class.new(build) }
  let(:popen_result) do
    Gitlab::Popen::Result.new([], expected_stdout, expected_stderr, process_status, expected_duration)
  end

  let_it_be(:signature_bundle) { File.read(SLSA_ATTESTATION_BUNDLE) }
  let_it_be(:expected_stderr) { "expected stderr outuput string" }
  let_it_be(:expected_stdout) { "expected stderr outuput string" }
  let_it_be(:tmp_file_path) { "/tmp/folder/file.bundle" }
  let_it_be(:expected_duration) { 1.33337 }
  let(:expected_predicate) { SupplyChain::Slsa::ProvenanceStatement::Predicate.from_build(build).to_json }
  let(:popen_success) { true }
  let(:process_status) do
    process_status = instance_double(Process::Status)
    allow(process_status).to receive(:success?).and_return(popen_success)

    process_status
  end

  let(:popen_stdin_file) do
    fh = instance_double(File)
    allow(fh).to receive(:write).with(any_args)
    fh
  end

  include_context 'with build, pipeline and artifacts'

  before do
    file = instance_double(File)

    allow(Tempfile).to receive(:create).and_yield(file)
    allow(file).to receive_messages(read: signature_bundle, path: tmp_file_path, rewind: nil)
    allow(Gitlab::Popen).to receive(:popen_with_detail).with(any_args).and_yield(popen_stdin_file)
      .and_return(popen_result)
  end

  describe '#execute' do
    subject(:execute) { service.execute }

    let(:expected_hashes) do
      {
        "file.txt" => "1d3ad753c8fdb96745e9cc6ef7ff10f4b65f87a430ddb081464c4c71d3569991",
        "artifact.zip" => "a495d7bb2c57c70ed17089492ae1df663b157a6e36c0087c5729b5ed05244f39",
        "artifact.txt" => "37980c33951de6b0e450c3701b219bfeee930544705f637cd1158b63827bb390"
      }
    end

    it 'logs the right hash and attestation' do
      allow(Gitlab::AppJsonLogger).to receive(:info)

      expect(execute[:status]).to eq(:success)
      expect(execute[:message]).to eq("OK")

      expected_hashes.each do |path, hash|
        expect(Gitlab::AppJsonLogger).to have_received(:info).with(a_hash_including({
          message: "Performing attestation for artifact",
          hash: hash,
          path: end_with(path),
          build_id: build.id
        }))

        expect(Gitlab::AppJsonLogger).to have_received(:info).with(a_hash_including({
          message: "Attestation successful",
          hash: hash,
          blob_name: File.basename(path),
          attestation: signature_bundle,
          duration: expected_duration,
          build_id: build.id
        }))
      end

      expect(popen_stdin_file).to have_received(:write).exactly(3).times.with(expected_predicate)
    end

    it 'calls attest with the right parameters' do
      expected_hashes.each do |path, hash|
        expect(service).to receive(:attest_blob!).with(blob_name: path, id_token: id_token,
          predicate: expected_predicate, hash: hash)
      end

      expect(execute[:message]).to eq("OK")
    end

    it 'calls cosign with the appropriate parameters' do
      expected_hashes.each do |path, hash|
        expected_parameters = ["cosign", "attest-blob", "--new-bundle-format", "--predicate", "-", "--type",
          "slsaprovenance1", "--hash", hash, "--identity-token", id_token, "--oidc-issuer",
          "http://localhost", "--yes", "--bundle", tmp_file_path, "--", "./#{File.basename(path)}"]

        expect(Gitlab::Popen).to receive(:popen_with_detail).with(expected_parameters).and_return(popen_result)
      end

      expect(execute[:message]).to eq("OK")
    end

    context 'when environment variables for optional parameters exist' do
      let(:fulcio_url) { 'http://192.168.1.13:5555/fulcio' }
      let(:rekor_url) { 'http://127.0.0.1:8090/rekor' }

      before do
        stub_env('COSIGN_FULCIO_URL', fulcio_url)
        stub_env('COSIGN_REKOR_URL', rekor_url)
      end

      context 'when non-production' do
        it 'calls cosign with --fulcio-url and --rekor-url' do
          expected_hashes.each do |path, hash|
            expected_parameters = ["cosign", "attest-blob", "--new-bundle-format", "--predicate", "-", "--type",
              "slsaprovenance1", "--hash", hash, "--identity-token", id_token, "--oidc-issuer",
              "http://localhost", "--yes", "--bundle", tmp_file_path, '--fulcio-url', fulcio_url,
              '--rekor-url', rekor_url, "--", "./#{File.basename(path)}"]

            expect(Gitlab::Popen).to receive(:popen_with_detail).with(expected_parameters).and_return(popen_result)
          end

          expect(execute[:message]).to eq("OK")
        end
      end

      context 'when production' do
        it 'does not inlcude --fulcio-url or --rekor-url' do
          stub_rails_env('production')

          expected_hashes.each do |path, hash|
            expected_parameters = ["cosign", "attest-blob", "--new-bundle-format", "--predicate", "-", "--type",
              "slsaprovenance1", "--hash", hash, "--identity-token", id_token, "--oidc-issuer",
              "http://localhost", "--yes", "--bundle", tmp_file_path, "--", "./#{File.basename(path)}"]

            expect(Gitlab::Popen).to receive(:popen_with_detail).with(expected_parameters).and_return(popen_result)
          end

          expect(execute[:message]).to eq("OK")
        end
      end
    end

    context 'when popen returns an error' do
      let(:popen_success) { false }

      it 'raises the appropriate exception' do
        expect { execute }.to raise_exception(described_class::AttestationFailure)
      end
    end

    context "when the build does not have SIGSTORE_ID_TOKEN" do
      let(:yaml_variables) do
        [
          { key: 'GENERATE_PROVENANCE', value: 'true', public: true }
        ]
      end

      it "returns an error" do
        expect(execute[:status]).to eq(:error)
        expect(execute[:message]).to eq("Missing required variable SIGSTORE_ID_TOKEN")
      end
    end

    context "when the build is nil" do
      let(:service) { described_class.new(nil) }

      it "returns an error" do
        expect(execute[:status]).to eq(:error)
        expect(execute[:message]).to eq("Unable to find build")
      end
    end

    context "when the project is private" do
      let(:project) { create_default(:project, :private, :repository, group: group) }
      let(:build) do
        create(:ci_build, project: project)
      end

      it "returns an error" do
        expect(execute[:status]).to eq(:error)
        expect(execute[:message]).to eq("Attestation is only enabled for public projects")
      end
    end

    context "when the project is internal" do
      let(:project) { create_default(:project, :internal, :repository, group: group) }
      let(:build) do
        create(:ci_build, project: project)
      end

      it "returns an error" do
        expect(execute[:status]).to eq(:error)
        expect(execute[:message]).to eq("Attestation is only enabled for public projects")
      end
    end
  end

  describe '#attest_blob!' do
    let(:hash) { "5db1fee4b5703808c48078a76768b155b421b210c0761cd6a5d223f4d99f1eaa" }
    let(:blob_name) { "test.txt" }

    subject(:attest_blob) do
      service.attest_blob!(blob_name: 'test.txt', hash: hash, predicate: "{}", id_token: id_token)
    end

    context "when called normally" do
      it 'calls the validate* methods' do
        expect(service).to receive(:validate_blob_name!).with(blob_name)
        expect(service).to receive(:validate_hash!).with(hash)
        expect(service).to receive(:validate_id_token!).with(id_token)

        attest_blob
      end
    end
  end

  describe '#validate_id_token!' do
    subject(:validate_id_token) { service.validate_id_token!(id_token) }

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
    subject(:validate_hash) { service.validate_hash!(hash) }

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
    subject(:validate_blob_name) { service.validate_blob_name!(blob_name) }

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
end
