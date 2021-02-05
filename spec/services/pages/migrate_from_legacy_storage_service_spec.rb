# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Pages::MigrateFromLegacyStorageService do
  let(:service) { described_class.new(Rails.logger, 3, 10) }

  it 'does not try to migrate pages if pages are not deployed' do
    expect(::Pages::MigrateLegacyStorageToDeploymentService).not_to receive(:new)

    expect(service.execute).to eq(migrated: 0, errored: 0)
  end

  it 'uses multiple threads' do
    projects = create_list(:project, 20)
    projects.each do |project|
      project.mark_pages_as_deployed

      FileUtils.mkdir_p File.join(project.pages_path, "public")
      File.open(File.join(project.pages_path, "public/index.html"), "w") do |f|
        f.write("Hello!")
      end
    end

    service = described_class.new(Rails.logger, 3, 2)

    threads = Concurrent::Set.new

    expect(service).to receive(:migrate_project).exactly(20).times.and_wrap_original do |m, *args|
      threads.add(Thread.current)

      # sleep to be 100% certain that once thread can't consume all the queue
      # it works without it, but I want to avoid making this test flaky
      sleep(0.01)

      m.call(*args)
    end

    expect(service.execute).to eq(migrated: 20, errored: 0)
    expect(threads.length).to eq(3)
  end

  context 'when pages are marked as deployed' do
    let(:project) { create(:project) }

    before do
      project.mark_pages_as_deployed
    end

    context 'when pages directory does not exist' do
      it 'tries to migrate the project, but does not crash' do
        expect_next_instance_of(::Pages::MigrateLegacyStorageToDeploymentService, project) do |service|
          expect(service).to receive(:execute).and_call_original
        end

        expect(service.execute).to eq(migrated: 0, errored: 1)
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
          expect(service.execute).to eq(migrated: 1, errored: 0)
        end.to change { project.pages_metadatum.reload.pages_deployment }.from(nil)
      end

      context 'when deployed already exists for the project' do
        before do
          deployment = create(:pages_deployment, project: project)
          project.set_first_pages_deployment!(deployment)
        end

        it 'does not try to migrate project' do
          expect(::Pages::MigrateLegacyStorageToDeploymentService).not_to receive(:new)

          expect(service.execute).to eq(migrated: 0, errored: 0)
        end
      end
    end
  end
end
