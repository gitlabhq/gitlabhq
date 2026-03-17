# frozen_string_literal: true

require 'spec_helper'
require 'digest'

RSpec.describe Ci::Slsa::PublishProvenanceService, feature_category: :artifact_security do
  let(:service) { described_class.new(build) }
  let(:message) { "Attestations persisted" }
  let(:service_response) { ServiceResponse.success(message: message) }

  include_context 'with build, pipeline and artifacts'

  describe '#execute' do
    subject(:result) { service.execute }

    context "when passing invalid parameters" do
      context "when the build is nil" do
        let(:service) { described_class.new(nil) }

        it "returns an error" do
          expect(result[:message]).to eq("Unable to find build")
          expect(result[:status]).to eq(:error)
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
    end

    context "when calling publisher" do
      let(:publisher) { instance_double(SupplyChain::ArtifactProvenancePublisher) }

      before do
        allow(SupplyChain::ArtifactProvenancePublisher)
          .to receive(:new)
          .with(build)
          .and_return(publisher)
      end

      it "calls publish if artifact_publisher.should_publish? is true" do
        expect(publisher).to receive(:should_publish?).and_return(true)
        expect(publisher).to receive(:publish).and_return(service_response)

        expect(result[:message]).to eq(message)
        expect(result[:status]).to eq(:success)
      end

      it "does not publish if artifact_publisher.should_publish? is false" do
        expect(publisher).to receive(:should_publish?).and_return(false)

        expect(result[:message]).to eq("No attestations performed")
        expect(result[:status]).to eq(:error)
      end
    end
  end
end
