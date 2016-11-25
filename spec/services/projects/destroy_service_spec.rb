require 'spec_helper'

describe Projects::DestroyService, services: true do
  include DatabaseConnectionHelpers
  let!(:user) { create(:user) }
  let!(:project) { create(:project, namespace: user.namespace) }
  let!(:path) { project.repository.path_to_repo }
  let!(:remove_path) { path.sub(/\.git\Z/, "+#{project.id}+deleted.git") }
  let!(:async) { false } # execute or async_execute

  context 'Sidekiq inline' do
    before do
      # Run sidekiq immediatly to check that renamed repository will be removed
      Sidekiq::Testing.inline! { destroy_project(project, user, {}) }
    end

    it { expect(Project.all).not_to include(project) }
    it { expect(Dir.exist?(path)).to be_falsey }
    it { expect(Dir.exist?(remove_path)).to be_falsey }
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

  context 'async delete of project with private issue visibility' do
    let!(:async) { true }

    before do
      project.project_feature.update_attribute("issues_access_level", ProjectFeature::PRIVATE)
      # Run sidekiq immediately to check that renamed repository will be removed
      Sidekiq::Testing.inline! { destroy_project(project, user, {}) }
    end

    it 'deletes the project' do
      expect(Project.all).not_to include(project)
      expect(Dir.exist?(path)).to be_falsey
      expect(Dir.exist?(remove_path)).to be_falsey
    end
  end

  context 'potential race conditions' do
    context "when the `ProjectDestroyWorker` task runs immediately" do
      it "deletes the project" do
        # Commit the contents of this spec's transaction so far
        # so subsequent db connections can see it.
        #
        # DO NOT REMOVE THIS LINE, even if you see a WARNING with "No
        # transaction is currently in progress". Without this, this
        # spec will always be green, since the project created in setup
        # cannot be seen by any other connections / threads in this spec.
        Project.connection.commit_db_transaction

        project_record = run_with_new_database_connection do |conn|
          conn.execute("SELECT * FROM projects WHERE id = #{project.id}").first
        end

        expect(project_record).not_to be_nil

        # Execute the contents of `ProjectDestroyWorker` in a separate thread, to
        # simulate data manipulation by the Sidekiq worker (different database
        # connection / transaction).
        expect(ProjectDestroyWorker).to receive(:perform_async).and_wrap_original do |m, project_id, user_id, params|
          Thread.new { m[project_id, user_id, params] }.join(5)
        end

        # Kick off the initial project destroy in a new thread, so that
        # it doesn't share this spec's database transaction.
        Thread.new { described_class.new(project, user).async_execute }.join(5)

        project_record = run_with_new_database_connection do |conn|
          conn.execute("SELECT * FROM projects WHERE id = #{project.id}").first
        end

        expect(project_record).to be_nil
      end
    end
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
