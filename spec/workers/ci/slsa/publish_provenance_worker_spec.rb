# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::Slsa::PublishProvenanceWorker, feature_category: :artifact_security do
  let(:worker) { described_class.new }

  include_context 'with build, pipeline and artifacts'

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

      before do
        # TODO: remove mocking once database persistence is in place in PublishProvenanceService.
        upload_statement_service = instance_double(Ci::Slsa::PublishProvenanceService)
        allow(Ci::Slsa::PublishProvenanceService)
          .to receive(:new).with(build).and_return(upload_statement_service)
        allow(upload_statement_service).to receive(:execute).twice
      end

      it 'does not crash when called twice' do
        expect { perform_idempotent_work }.not_to raise_error
      end
    end
  end
end
