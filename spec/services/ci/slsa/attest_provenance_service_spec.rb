# frozen_string_literal: true

require 'spec_helper'
require 'digest'

RSpec.describe Ci::Slsa::AttestProvenanceService, feature_category: :continuous_integration do
  let(:service) { described_class.new(build) }

  describe '#execute' do
    subject(:execute) { service.execute }

    let_it_be(:build) { create(:ci_build, :artifacts, :finished) }
    let_it_be(:provenance_statement) { create(:provenance_statement) }

    it 'returns result from ProvenanceStatement.from_build' do
      expect(Ci::Slsa::ProvenanceStatement).to receive(:from_build).with(build).and_return(provenance_statement)

      execute
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
