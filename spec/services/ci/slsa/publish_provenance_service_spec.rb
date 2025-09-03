# frozen_string_literal: true

require 'spec_helper'
require 'digest'

RSpec.describe Ci::Slsa::PublishProvenanceService, feature_category: :artifact_security do
  let(:service) { described_class.new(build) }

  describe '#execute' do
    subject(:execute) { service.execute }

    include_context 'with build, pipeline and artifacts'

    it 'returns result from ProvenanceStatement.from_build' do
      allow(Gitlab::AppJsonLogger).to receive(:info)

      expect(execute[:status]).to eq(:success)
      expect(execute[:message]).to eq("OK")

      expected_hashes = {
        "file.txt" => "1d3ad753c8fdb96745e9cc6ef7ff10f4b65f87a430ddb081464c4c71d3569991",
        "artifact.zip" => "a495d7bb2c57c70ed17089492ae1df663b157a6e36c0087c5729b5ed05244f39",
        "artifact.txt" => "37980c33951de6b0e450c3701b219bfeee930544705f637cd1158b63827bb390"
      }

      expected_hashes.each do |path, hash|
        expect(Gitlab::AppJsonLogger).to have_received(:info).with(a_hash_including({
          message: "Performing attestation for artifact",
          hash: hash,
          path: end_with(path)
        }))
      end
    end

    context "when the build is nil" do
      let(:service) { described_class.new(nil) }

      it "returns an error" do
        expect(execute[:status]).to eq(:error)
        expect(execute[:message]).to eq("Unable to find build")
      end
    end
  end
end
