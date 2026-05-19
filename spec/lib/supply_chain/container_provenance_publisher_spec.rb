# frozen_string_literal: true

require 'spec_helper'
require 'digest'

RSpec.describe SupplyChain::ContainerProvenancePublisher, feature_category: :artifact_security do
  let(:publisher) { described_class.new(build) }
  let(:success_message) { "Attestations persisted" }
  let(:hash) { '5db1fee4b5703808c48078a76768b155b421b210c0761cd6a5d223f4d99f1eaa' }

  include_context 'with mocked cosign execution'

  describe '#publish' do
    subject(:result) { publisher.publish }

    let(:result_status) { result[1] }
    let(:attestations) { result[0] }
    let(:yaml_variables) { [{ key: 'IMAGE_DIGEST', value: hash, public: true }] }

    before do
      allow(Gitlab::Ci::JwtV2).to receive(:for_build).and_return(id_token)
    end

    it 'persists the attestations' do
      expect(result_status).to be(true)

      expect(attestations.length).to eq(1)

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

      expect(attestations).to include(an_object_having_attributes(subject_digest: hash))
    end

    it 'logs the right values' do
      allow(Gitlab::AppJsonLogger).to receive(:info)

      predicate_class = SupplyChain::Slsa::ProvenanceStatement::Predicate
      expect(popen_stdin_file).to receive(:write).once.with(expected_predicate)
      expect(predicate_class).to receive(:from_build).exactly(1).time.and_call_original

      expect(result_status).to be(true)

      expect(Gitlab::AppJsonLogger).to have_received(:info).with(a_hash_including({
        message: "Container attestation successful",
        hash: hash,
        duration: expected_duration,
        build_id: build.id
      }))
    end

    it 'calls attest with the right parameters' do
      expect(publisher).to receive(:cosign_attest_blob).with(hash: hash)
      expect(result_status).to be(true)
    end

    it 'calls cosign with the appropriate parameters' do
      expected_parameters = ["cosign", "attest-blob", "--new-bundle-format", "--predicate", "-", "--type",
        "slsaprovenance1", "--hash", hash, "--identity-token", id_token, "--oidc-issuer",
        "http://localhost", "--yes", '--use-signing-config=false', "--bundle", anything, "--",
        "./#{hash}"]

      expect(Gitlab::Popen).to receive(:popen_with_detail).with(expected_parameters).and_return(popen_result)

      expect(result_status).to be(true)
    end

    context "when IMAGE_DIGEST variable is not set" do
      let(:yaml_variables) { [] }

      it "returns a failure response" do
        allow(Gitlab::AppJsonLogger).to receive(:info)

        expect(result_status).to be(false)
        expect(attestations).to eq([])

        expect(Gitlab::AppJsonLogger).to have_received(:info).with(a_hash_including({
          message: "Image digest not present in build",
          build_id: build.id
        }))
      end
    end

    context "when attestation fails" do
      it 'persists a :failed attestation' do
        allow(Gitlab::AppJsonLogger).to receive(:info)

        expect(publisher).to receive(:validate_hash!).with(any_args).once.and_raise(StandardError)
        expect(Gitlab::ErrorTracking).to receive(:track_and_raise_for_dev_exception).once

        expect(result_status).to be(false)
        expect(attestations.length).to eq(1)

        expect(attestations).to all(be_a(SupplyChain::Attestation))
        expect(attestations).to all(be_persisted)
        expect(attestations).to all(be_error)
        expect(attestations).to all(be_provenance)

        att = attestations[0]

        expect(att.project_id).to eq(project.id)
        expect(att.build_id).to eq(build.id)
        expect(att.predicate_type).to eq(expected_predicate_type)
        expect(att.file.read).to be_nil

        expect(attestations).to include(an_object_having_attributes(subject_digest: hash))
        expect(Gitlab::AppJsonLogger).to have_received(:info).with(a_hash_including({
          message: "Container attestation failure",
          hash: hash,
          build_id: build.id
        }))
      end
    end

    context "when duplicate attestations are attempted" do
      let!(:existing_attestation) { create(:supply_chain_attestation, project: project, subject_digest: hash) }

      it "skips attestation" do
        expect(attestations.length).to eq(0)
      end
    end

    context "when a previous :error attestation exists" do
      let(:existing_attestation) { create(:supply_chain_attestation, subject_digest: hash, status: :error) }

      it "deletes it" do
        expect(existing_attestation).to receive(:destroy).and_call_original

        expected_args = {
          project: project,
          subject_digest: hash
        }
        allow(SupplyChain::Attestation).to receive(:find_provenance).with(expected_args)
          .and_return(existing_attestation)

        expect(attestations.length).to be(1)
      end
    end

    context "when validation errors happen" do
      it 'persists a :failed attestation' do
        expect(publisher).to receive(:validate_hash!).with(any_args).once \
          .and_raise(ActiveRecord::RecordInvalid)

        expect(Gitlab::ErrorTracking).to receive(:track_and_raise_for_dev_exception).once

        expect(result_status).to be(false)
        expect(attestations.length).to eq(1)

        expect(attestations).to all(be_a(SupplyChain::Attestation))
        expect(attestations).to all(be_persisted)
        expect(attestations).to all(be_error)
        expect(attestations).to all(be_provenance)

        att = attestations[0]

        expect(att.project_id).to eq(project.id)
        expect(att.build_id).to eq(build.id)
        expect(att.predicate_type).to eq(expected_predicate_type)
        expect(att.file.read).to be_nil

        expect(attestations).to include(an_object_having_attributes(subject_digest: hash))
      end

      it 'handles failures persisting errors gracefully' do
        expect(publisher).to receive(:validate_hash!).with(any_args).once \
          .and_raise(ActiveRecord::RecordInvalid)

        expect(publisher).to receive(:persist_attestation!).with(any_args).once \
          .and_raise(StandardError)

        # Once for original exception, and again for failure to persist attestation
        expect(Gitlab::ErrorTracking).to receive(:track_and_raise_for_dev_exception).twice

        expect(result_status).to be(false)
        expect(attestations.length).to eq(0)
      end
    end
  end

  describe '#image_digest' do
    context "when IMAGE_DIGEST is set" do
      where(:image_digest_value, :expected_result) do
        [
          [
            "sha256:9bf00f5090086aba643d21f8ed663576855add63b7b780b4eaffc5124812c3c9",
            "9bf00f5090086aba643d21f8ed663576855add63b7b780b4eaffc5124812c3c9"
          ],
          [
            "sroqueworcel/test-slsa-sbom@sha256:9bf00f5090086aba643d21f8ed663576855add63b7b780b4eaffc5124812c3c9",
            "9bf00f5090086aba643d21f8ed663576855add63b7b780b4eaffc5124812c3c9"
          ],
          [
            "9bf00f5090086aba643d21f8ed663576855add63b7b780b4eaffc5124812c3c9",
            "9bf00f5090086aba643d21f8ed663576855add63b7b780b4eaffc5124812c3c9"
          ]
        ]
      end

      with_them do
        let(:yaml_variables) { [{ key: 'IMAGE_DIGEST', value: image_digest_value, public: true }] }

        it "behaves correctly" do
          expect(publisher.send(:image_digest)).to eq(expected_result)
        end
      end
    end

    context "when no IMAGE_DIGEST is set" do
      let(:yaml_variables) { [] }

      it "behaves correctly" do
        expect(publisher.send(:image_digest)).to be_nil
      end
    end
  end

  describe '#should_publish?' do
    subject(:should_publish) { described_class.should_publish?(build) }

    context 'when ::SupplyChain.publish_container_provenance? is true' do
      before do
        allow(::SupplyChain).to receive(:publish_container_provenance?).and_return(true)
      end

      it 'returns true' do
        expect(should_publish).to be_truthy
      end
    end

    context 'when ::SupplyChain.publish_container_provenance? is false' do
      before do
        allow(::SupplyChain).to receive(:publish_container_provenance?).and_return(false)
      end

      it 'returns false' do
        expect(should_publish).to be_falsey
      end
    end
  end
end
