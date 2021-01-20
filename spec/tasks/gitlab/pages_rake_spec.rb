# frozen_string_literal: true

require 'rake_helper'

RSpec.describe 'gitlab:pages:migrate_legacy_storagerake task' do
  before(:context) do
    Rake.application.rake_require 'tasks/gitlab/pages'
  end

  subject { run_rake_task('gitlab:pages:migrate_legacy_storage') }

  let(:project) { create(:project) }

  it 'does not try to migrate pages if pages are not deployed' do
    expect(::Pages::MigrateLegacyStorageToDeploymentService).not_to receive(:new)

    subject
  end

  context 'when pages are marked as deployed' do
    before do
      project.mark_pages_as_deployed
    end

    context 'when pages directory does not exist' do
      it 'tries to migrate the project, but does not crash' do
        expect_next_instance_of(::Pages::MigrateLegacyStorageToDeploymentService, project) do |service|
          expect(service).to receive(:execute).and_call_original
        end

        subject
      end
    end

    context 'when pages directory exists on disk' do
      before do
        FileUtils.mkdir_p File.join(project.pages_path, "public")
        File.open(File.join(project.pages_path, "public/index.html"), "w") do |f|
          f.write("Hello!")
        end
      end

      it 'migrates pages projects without deployments' do
        expect_next_instance_of(::Pages::MigrateLegacyStorageToDeploymentService, project) do |service|
          expect(service).to receive(:execute).and_call_original
        end

        expect do
          subject
        end.to change { project.pages_metadatum.reload.pages_deployment }.from(nil)
      end

      context 'when deployed already exists for the project' do
        before do
          deployment = create(:pages_deployment, project: project)
          project.set_first_pages_deployment!(deployment)
        end

        it 'does not try to migrate project' do
          expect(::Pages::MigrateLegacyStorageToDeploymentService).not_to receive(:new)

          subject
        end
      end
    end
  end
end
