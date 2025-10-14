# frozen_string_literal: true

require 'spec_helper'
require 'digest'

SLSA_ATTESTATION_BUNDLE = 'spec/fixtures/slsa/attestation.bundle'

RSpec.describe Ci::Slsa::PublishProvenanceService, feature_category: :artifact_security do
  let(:service) { described_class.new(build) }
  let(:success_message) { "Attestations persisted" }
  let(:popen_result) do
    Gitlab::Popen::Result.new([], expected_stdout, expected_stderr, process_status, expected_duration)
  end

  let_it_be(:signature_bundle) { File.read(SLSA_ATTESTATION_BUNDLE) }
  let_it_be(:expected_stderr) { "expected stderr outuput string" }
  let_it_be(:expected_stdout) { "expected stderr outuput string" }
  let_it_be(:expected_duration) { 1.33337 }
  let_it_be(:expected_predicate_type) { SupplyChain::Slsa::ProvenanceStatement::PREDICATE_TYPE_V1 }
  let(:expected_predicate) { service.send(:predicate) }
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

  let(:real_tmp_files) do
    files = []
    3.times do
      file = Tempfile.new
      file.write(signature_bundle)
      file.flush

      files << file
    end

    files
  end

  include_context 'with build, pipeline and artifacts'

  before do
    # object_storage.rb moves the file on disk rather than use our file handle.
    # Because of this, we need to provide one Tempfile per artifact.
    nb = 0
    allow(Tempfile).to receive(:create) do |&block|
      block.call(real_tmp_files[nb])
      nb += 1
    end

    allow(Gitlab::Popen).to receive(:popen_with_detail).with(any_args).and_yield(popen_stdin_file)
      .and_return(popen_result)
  end

  after do
    real_tmp_files.each(&:close)
  end

  describe '#execute' do
    subject(:result) { service.execute }

    let(:attestations) { result.payload[:attestations] }

    let(:expected_hashes) do
      {
        "file.txt" => "1d3ad753c8fdb96745e9cc6ef7ff10f4b65f87a430ddb081464c4c71d3569991",
        "artifact.zip" => "a495d7bb2c57c70ed17089492ae1df663b157a6e36c0087c5729b5ed05244f39",
        "artifact.txt" => "37980c33951de6b0e450c3701b219bfeee930544705f637cd1158b63827bb390"
      }
    end

    it 'persists the attestations' do
      expect(result[:status]).to eq(:success)
      expect(result[:message]).to eq(success_message)

      expect(attestations.length).to eq(3)

      expect(attestations).to all(be_a(SupplyChain::Attestation))
      expect(attestations).to all(be_persisted)
      expect(attestations).to all(be_success)
      expect(attestations).to all(be_provenance)

      attestations.each do |att|
        expect(att.project_id).to eq(project.id)
        expect(att.build_id).to eq(build.id)
        expect(att.predicate_type).to eq(expected_predicate_type)
        expect(att.file.read).to eq(signature_bundle)
      end

      expected_hashes.each_value do |hash|
        expect(attestations).to include(an_object_having_attributes(subject_digest: hash))
      end
    end

    it 'logs the right values' do
      allow(Gitlab::AppJsonLogger).to receive(:info)

      predicate_class = SupplyChain::Slsa::ProvenanceStatement::Predicate
      expect(predicate_class).to receive(:from_build).exactly(1).time.and_call_original

      expect(result[:status]).to eq(:success)
      expect(result[:message]).to eq(success_message)

      expected_hashes.each do |path, hash|
        expect(Gitlab::AppJsonLogger).to have_received(:info).with(a_hash_including({
          message: "Attestation successful",
          hash: hash,
          blob_name: File.basename(path),
          duration: expected_duration,
          build_id: build.id
        }))
      end

      expect(popen_stdin_file).to have_received(:write).exactly(3).times.with(expected_predicate)
    end

    it 'calls attest with the right parameters' do
      expected_hashes.each do |path, hash|
        expect(service).to receive(:cosign_attest_blob).with(blob_name: path, hash: hash)
      end

      expect(result[:message]).to eq(success_message)
    end

    it 'calls cosign with the appropriate parameters' do
      expected_hashes.each do |path, hash|
        expected_parameters = ["cosign", "attest-blob", "--new-bundle-format", "--predicate", "-", "--type",
          "slsaprovenance1", "--hash", hash, "--identity-token", id_token, "--oidc-issuer",
          "http://localhost", "--yes", "--bundle", anything, "--", "./#{File.basename(path)}"]

        expect(Gitlab::Popen).to receive(:popen_with_detail).with(expected_parameters).and_return(popen_result)
      end

      expect(result[:message]).to eq(success_message)
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
              "http://localhost", "--yes", "--bundle", anything, '--fulcio-url', fulcio_url,
              '--rekor-url', rekor_url, "--", "./#{File.basename(path)}"]

            expect(Gitlab::Popen).to receive(:popen_with_detail).with(expected_parameters).and_return(popen_result)
          end

          expect(result[:message]).to eq(success_message)
        end
      end

      context 'when production' do
        it 'does not inlcude --fulcio-url or --rekor-url' do
          stub_rails_env('production')

          expected_hashes.each do |path, hash|
            expected_parameters = ["cosign", "attest-blob", "--new-bundle-format", "--predicate", "-", "--type",
              "slsaprovenance1", "--hash", hash, "--identity-token", id_token, "--oidc-issuer",
              "http://localhost", "--yes", "--bundle", anything, "--", "./#{File.basename(path)}"]

            expect(Gitlab::Popen).to receive(:popen_with_detail).with(expected_parameters).and_return(popen_result)
          end

          expect(result[:message]).to eq(success_message)
        end
      end
    end

    context "when the build does not have SIGSTORE_ID_TOKEN" do
      let(:yaml_variables) do
        [
          { key: 'GENERATE_PROVENANCE', value: 'true', public: true }
        ]
      end

      it "returns an error" do
        expect(result[:status]).to eq(:error)
        expect(result[:message]).to eq("Missing required variable SIGSTORE_ID_TOKEN")
      end
    end

    context "when the build is nil" do
      let(:service) { described_class.new(nil) }

      it "returns an error" do
        expect(result[:status]).to eq(:error)
        expect(result[:message]).to eq("Unable to find build")
      end
    end

    context "when the project is private" do
      let(:project) { create_default(:project, :private, :repository, group: group) }
      let(:build) do
        create(:ci_build, project: project)
      end

      it "returns an error" do
        expect(result[:status]).to eq(:error)
        expect(result[:message]).to eq("Attestation is only enabled for public projects")
      end
    end

    context "when the project is internal" do
      let(:project) { create_default(:project, :internal, :repository, group: group) }
      let(:build) do
        create(:ci_build, project: project)
      end

      it "returns an error" do
        expect(result[:status]).to eq(:error)
        expect(result[:message]).to eq("Attestation is only enabled for public projects")
      end
    end

    context "when attestation fails" do
      it 'persists a :failed attestation' do
        allow(Gitlab::AppJsonLogger).to receive(:info)

        expect(service).to receive(:validate_blob_name!).with(any_args).exactly(3).times.and_raise(StandardError)
        expect(Gitlab::ErrorTracking).to receive(:track_and_raise_for_dev_exception).exactly(3).times

        expect(result[:status]).to eq(:error)
        expect(result[:message]).to eq("Attestation failure")

        expect(attestations.length).to eq(3)

        expect(attestations).to all(be_a(SupplyChain::Attestation))
        expect(attestations).to all(be_persisted)
        expect(attestations).to all(be_error)
        expect(attestations).to all(be_provenance)

        attestations.each do |att|
          expect(att.project_id).to eq(project.id)
          expect(att.build_id).to eq(build.id)
          expect(att.predicate_type).to eq(expected_predicate_type)
          expect(att.file.read).to be_nil
        end

        expected_hashes.each do |path, hash|
          expect(attestations).to include(an_object_having_attributes(subject_digest: hash))
          expect(Gitlab::AppJsonLogger).to have_received(:info).with(a_hash_including({
            message: "Attestation failure",
            hash: hash,
            blob_name: File.basename(path),
            build_id: build.id
          }))
        end
      end
    end

    context "when duplicate attestations are attempted" do
      before do
        dup_hash = "5db1fee4b5703808c48078a76768b155b421b210c0761cd6a5d223f4d99f1eaa"
        allow(service).to receive(:hash).exactly(3).times.and_return(dup_hash)
        allow(Gitlab::AppJsonLogger).to receive(:info)
      end

      it "skips attestation" do
        expect(attestations.length).to eq(1)
      end
    end

    context "when a previous :error attestation exists" do
      let(:duplicate_hash) { "5db1fee4b5703808c48078a76768b155b421b210c0761cd6a5d223f2d99f1eaa" }
      let(:existing_attestation) { create(:supply_chain_attestation, subject_digest: duplicate_hash, status: :error) }

      before do
        allow_next_instance_of(SupplyChain::ArtifactsReader) do |instance|
          allow(instance).to receive(:files).and_yield("path", nil)
        end
        allow(service).to receive(:hash).exactly(1).time.and_return(duplicate_hash)
        allow(Gitlab::AppJsonLogger).to receive(:info)
      end

      it "deletes it" do
        expect(existing_attestation).to receive(:destroy).and_call_original
        allow(service).to receive(:attestation_by_hash).with(duplicate_hash).and_return(existing_attestation)

        expected_args = {
          project: project,
          subject_digest: duplicate_hash
        }
        allow(SupplyChain::Attestation).to receive(:find_provenance).with(expected_args)
          .and_return(existing_attestation)

        expect(attestations.length).to be(1)
      end
    end

    context "when a mixture of successful and unsuccessful attestations happen" do
      it "persists a mixture of :error and :success attestations" do
        nb = 0
        expect(service).to receive(:validate_blob_name!).with(any_args).exactly(3).times do
          nb += 1
          raise StandardError if nb == 2
        end

        expect(Gitlab::ErrorTracking).to receive(:track_and_raise_for_dev_exception).once

        expect(attestations.count(&:success?)).to be(2)
        expect(attestations.count(&:error?)).to be(1)
      end
    end

    context "when validation errors happen" do
      it 'persists a :failed attestation' do
        expect(service).to receive(:validate_blob_name!).with(any_args).exactly(3).times \
          .and_raise(ActiveRecord::RecordInvalid)

        expect(Gitlab::ErrorTracking).to receive(:track_and_raise_for_dev_exception).exactly(3).times

        expect(result[:status]).to eq(:error)
        expect(result[:message]).to eq("Attestation failure")

        expect(attestations.length).to eq(3)

        expect(attestations).to all(be_a(SupplyChain::Attestation))
        expect(attestations).to all(be_persisted)
        expect(attestations).to all(be_error)
        expect(attestations).to all(be_provenance)

        attestations.each do |att|
          expect(att.project_id).to eq(project.id)
          expect(att.build_id).to eq(build.id)
          expect(att.predicate_type).to eq(expected_predicate_type)
          expect(att.file.read).to be_nil
        end

        expected_hashes.each_value do |hash|
          expect(attestations).to include(an_object_having_attributes(subject_digest: hash))
        end
      end
    end
  end

  describe '#cosign_attest_blob' do
    let(:hash) { "5db1fee4b5703808c48078a76768b155b421b210c0761cd6a5d223f4d99f1eaa" }
    let(:blob_name) { "test.txt" }

    subject(:cosign_attest_blob) do
      service.send(:cosign_attest_blob, blob_name: 'test.txt', hash: hash)
    end

    context "when called normally" do
      it 'calls the validate* methods' do
        expect(service).to receive(:validate_blob_name!).with(blob_name)
        expect(service).to receive(:validate_hash!).with(hash)
        expect(service).to receive(:validate_id_token!).with(id_token)

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

  describe '#validate_id_token!' do
    subject(:validate_id_token) { service.send(:validate_id_token!, id_token) }

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
    subject(:validate_hash) { service.send(:validate_hash!, hash) }

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
    subject(:validate_blob_name) { service.send(:validate_blob_name!, blob_name) }

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
