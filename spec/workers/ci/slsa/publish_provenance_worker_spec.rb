# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::Slsa::PublishProvenanceWorker, feature_category: :artifact_security do
  let_it_be(:build) { create(:ci_build, :artifacts, :finished) }
  let_it_be(:provenance_statement) { create(:provenance_statement) }
  let(:worker) { described_class.new }

  let(:file_contents) { statement_artifact.file.file.read }
  let(:statement_artifact) { statement_artifacts.first }

  before do
    allow(Ci::Slsa::ProvenanceStatement).to receive(:from_build).with(build).and_return(provenance_statement)
  end

  describe '#perform' do
    subject(:perform) { worker.perform(build.id) }

    it 'executes a service' do
      expect(Ci::Build)
        .to receive(:find_by_id).with(build.id).and_return(build)

      upload_statement_service = instance_double(Ci::Slsa::PublishProvenanceService)
      expect(Ci::Slsa::PublishProvenanceService)
        .to receive(:new).with(build).and_return(upload_statement_service)

      expect(upload_statement_service).to receive(:execute)

      perform
    end

    it_behaves_like 'an idempotent worker' do
      let(:job_args) { [build.id] }

      it 'does not crash when called twice' do
        expect { perform_idempotent_work }.not_to raise_error
      end
    end
  end
end
