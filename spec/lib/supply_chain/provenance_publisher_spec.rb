# frozen_string_literal: true

require 'spec_helper'
require 'digest'

RSpec.describe SupplyChain::ProvenancePublisher, feature_category: :artifact_security do
  let(:publisher) { described_class.new(build) }
  let(:success_message) { "Attestations persisted" }

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
