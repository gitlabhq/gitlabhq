# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::JobArtifacts::ExpireProjectBuildArtifactsWorker, feature_category: :job_artifacts do
  let(:worker) { described_class.new }
  let(:current_time) { Time.current }

  let_it_be(:project) { create(:project) }

  around do |example|
    freeze_time { example.run }
  end

  describe '#perform' do
    it 'executes ExpireProjectArtifactsService service with the project' do
      expect_next_instance_of(Ci::JobArtifacts::ExpireProjectBuildArtifactsService, project.id, current_time) do |instance|
        expect(instance).to receive(:execute).and_call_original
      end

      worker.perform(project.id)
    end

    context 'when project does not exist' do
      it 'does nothing' do
        expect(Ci::JobArtifacts::ExpireProjectBuildArtifactsService).not_to receive(:new)

        worker.perform(non_existing_record_id)
      end
    end
  end
end
