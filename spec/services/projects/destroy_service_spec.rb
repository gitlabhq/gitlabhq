require 'spec_helper'

describe Projects::DestroyService, services: true do
  let!(:user) { create(:user) }
  let!(:project) { create(:project, namespace: user.namespace) }
  let!(:path) { project.repository.path_to_repo }
  let!(:remove_path) { path.sub(/\.git\Z/, "+#{project.id}+deleted.git") }
  let!(:async) { false } # execute or async_execute

  shared_examples 'deleting the project' do
    it 'deletes the project' do
      expect(Project.unscoped.all).not_to include(project)
      expect(Dir.exist?(path)).to be_falsey
      expect(Dir.exist?(remove_path)).to be_falsey
    end
  end

  shared_examples 'deleting the project with pipeline and build' do
    context 'with pipeline and build' do # which has optimistic locking
      let!(:pipeline) { create(:ci_pipeline, project: project) }
      let!(:build) { create(:ci_build, :artifacts, pipeline: pipeline) }

      before do
        perform_enqueued_jobs do
          destroy_project(project, user, {})
        end
      end

      it_behaves_like 'deleting the project'
    end
  end

  context 'Sidekiq inline' do
    before do
      # Run sidekiq immediatly to check that renamed repository will be removed
      Sidekiq::Testing.inline! { destroy_project(project, user, {}) }
    end

    context 'when has remote mirrors' do
      let!(:project) do
        create(:project, namespace: user.namespace).tap do |project|
          project.remote_mirrors.create(url: 'http://test.com')
        end
      end
      let!(:async) { true }

      it 'destroys them' do
        expect(RemoteMirror.count).to eq(0)
      end
    end

    it_behaves_like 'deleting the project'
  end

  context 'Sidekiq fake' do
    before do
      # Dont run sidekiq to check if renamed repository exists
      Sidekiq::Testing.fake! { destroy_project(project, user, {}) }
    end

    it { expect(Project.all).not_to include(project) }
    it { expect(Dir.exist?(path)).to be_falsey }
    it { expect(Dir.exist?(remove_path)).to be_truthy }
  end

  context 'when flushing caches fail' do
    before do
      new_user = create(:user)
      project.team.add_user(new_user, Gitlab::Access::DEVELOPER)
      allow_any_instance_of(Projects::DestroyService).to receive(:flush_caches).and_raise(Redis::CannotConnectError)
    end

    it 'keeps project team intact upon an error' do
      Sidekiq::Testing.inline! do
        begin
          destroy_project(project, user, {})
        rescue Redis::CannotConnectError
        end
      end

      expect(project.team.members.count).to eq 1
    end
  end

  context 'with async_execute' do
    let(:async) { true }

    context 'async delete of project with private issue visibility' do
      before do
        project.project_feature.update_attribute("issues_access_level", ProjectFeature::PRIVATE)
        # Run sidekiq immediately to check that renamed repository will be removed
        Sidekiq::Testing.inline! { destroy_project(project, user, {}) }
      end

      it_behaves_like 'deleting the project'
    end

    it_behaves_like 'deleting the project with pipeline and build'
  end

  context 'with execute' do
    it_behaves_like 'deleting the project with pipeline and build'
  end

  context 'container registry' do
    before do
      stub_container_registry_config(enabled: true)
      stub_container_registry_tags('tag')
    end

    context 'tags deletion succeeds' do
      it do
        expect_any_instance_of(ContainerRegistry::Tag).to receive(:delete).and_return(true)

        destroy_project(project, user, {})
      end
    end

    context 'tags deletion fails' do
      before { expect_any_instance_of(ContainerRegistry::Tag).to receive(:delete).and_return(false) }

      subject { destroy_project(project, user, {}) }

      it { expect{subject}.to raise_error(Projects::DestroyService::DestroyError) }
    end
  end

  def destroy_project(project, user, params)
    if async
      Projects::DestroyService.new(project, user, params).async_execute
    else
      Projects::DestroyService.new(project, user, params).execute
    end
  end
end
