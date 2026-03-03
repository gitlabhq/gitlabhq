# frozen_string_literal: true

require 'spec_helper'
require 'digest'

RSpec.describe SupplyChain::ArtifactProvenancePublisher, feature_category: :artifact_security do
  let(:publisher) { described_class.new(build) }
  let(:success_message) { "Attestations persisted" }

  include_context 'with mocked cosign execution'

  describe '#publish' do
    subject(:result) { publisher.publish }

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
      expect(popen_stdin_file).to receive(:write).exactly(3).times.with(expected_predicate)
      expect(predicate_class).to receive(:from_build).exactly(1).time.and_call_original

      expect(result[:message]).to eq(success_message)
      expect(result[:status]).to eq(:success)

      expected_hashes.each do |path, hash|
        expect(Gitlab::AppJsonLogger).to have_received(:info).with(a_hash_including({
          message: "Attestation successful",
          hash: hash,
          blob_name: File.basename(path),
          duration: expected_duration,
          build_id: build.id
        }))
      end
    end

    it 'calls attest with the right parameters' do
      expected_hashes.each do |path, hash|
        expect(publisher).to receive(:cosign_attest_blob).with(blob_name: path, hash: hash)
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

    context "when attestation fails" do
      it 'persists a :failed attestation' do
        allow(Gitlab::AppJsonLogger).to receive(:info)

        expect(publisher).to receive(:validate_blob_name!).with(any_args).exactly(3).times.and_raise(StandardError)
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
        allow(publisher).to receive(:hash).exactly(3).times.and_return(dup_hash)
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
        allow(publisher).to receive(:hash).exactly(1).time.and_return(duplicate_hash)
        allow(Gitlab::AppJsonLogger).to receive(:info)
      end

      it "deletes it" do
        expect(existing_attestation).to receive(:destroy).and_call_original
        allow(publisher).to receive(:attestation_by_hash).with(duplicate_hash).and_return(existing_attestation)

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
        expect(publisher).to receive(:validate_blob_name!).with(any_args).exactly(3).times do
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
        expect(publisher).to receive(:validate_blob_name!).with(any_args).exactly(3).times \
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

  describe '#should_publish?' do
    subject(:should_publish) { publisher.should_publish? }

    context 'when ::SupplyChain.publish_artifact_provenance? is true' do
      before do
        allow(::SupplyChain).to receive(:publish_artifact_provenance?).and_return(true)
      end

      it 'returns true' do
        expect(should_publish).to be_truthy
      end
    end

    context 'when ::SupplyChain.publish_artifact_provenance? is false' do
      before do
        allow(::SupplyChain).to receive(:publish_artifact_provenance?).and_return(false)
      end

      it 'returns false' do
        expect(should_publish).to be_falsey
      end
    end
  end
end
