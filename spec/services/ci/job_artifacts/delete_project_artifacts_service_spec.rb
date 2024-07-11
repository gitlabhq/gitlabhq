# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::JobArtifacts::DeleteProjectArtifactsService, feature_category: :job_artifacts do
  let_it_be(:project) { create(:project) }

  subject { described_class.new(project: project) }

  describe '#execute' do
    it 'enqueues a Ci::ExpireProjectBuildArtifactsWorker' do
      expect(Ci::JobArtifacts::ExpireProjectBuildArtifactsWorker).to receive(:perform_async).with(project.id).and_call_original

      subject.execute
    end
  end
end
