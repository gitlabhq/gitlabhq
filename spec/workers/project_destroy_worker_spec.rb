require 'spec_helper'

describe ProjectDestroyWorker do
  let(:project) { create(:project, pending_delete: true) }
  let(:path) { project.repository.path_to_repo }

  subject { ProjectDestroyWorker.new }

  describe '#perform' do
    context 'with pipelines and builds' do
      let!(:pipeline) { create(:ci_pipeline, project: project) }
      let!(:build) { create(:ci_build, :artifacts, pipeline: pipeline) }

      it 'deletes the project along with pipelines and builds' do
        subject.perform(project.id, project.owner.id, {})

        expect(Project.all).not_to include(project)
        expect(Ci::Pipeline.all).not_to include(pipeline)
        expect(Ci::Build.all).not_to include(build)
        expect(Dir.exist?(path)).to be_falsey
      end
    end

    it 'deletes the project but skips repo deletion' do
      subject.perform(project.id, project.owner.id, { 'skip_repo' => true })

      expect(Project.all).not_to include(project)
      expect(Dir.exist?(path)).to be_truthy
    end
  end
end
