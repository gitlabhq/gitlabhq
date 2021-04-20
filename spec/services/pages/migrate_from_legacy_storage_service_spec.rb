# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Pages::MigrateFromLegacyStorageService do
  let(:batch_size) { 10 }
  let(:mark_projects_as_not_deployed) { false }
  let(:service) { described_class.new(Rails.logger, ignore_invalid_entries: false, mark_projects_as_not_deployed: mark_projects_as_not_deployed) }

  shared_examples "migrates projects properly" do
    it 'does not try to migrate pages if pages are not deployed' do
      expect(::Pages::MigrateLegacyStorageToDeploymentService).not_to receive(:new)

      is_expected.to eq(migrated: 0, errored: 0)
    end

    context 'when pages are marked as deployed' do
      let(:project) { create(:project) }

      before do
        project.mark_pages_as_deployed
      end

      context 'when pages directory does not exist' do
        context 'when mark_projects_as_not_deployed is set' do
          let(:mark_projects_as_not_deployed) { true }

          it 'counts project as migrated' do
            expect_next_instance_of(::Pages::MigrateLegacyStorageToDeploymentService, project, ignore_invalid_entries: false, mark_projects_as_not_deployed: true) do |service|
              expect(service).to receive(:execute).and_call_original
            end

            is_expected.to eq(migrated: 1, errored: 0)
          end
        end

        it 'counts project as errored' do
          expect_next_instance_of(::Pages::MigrateLegacyStorageToDeploymentService, project, ignore_invalid_entries: false, mark_projects_as_not_deployed: false) do |service|
            expect(service).to receive(:execute).and_call_original
          end

          is_expected.to eq(migrated: 0, errored: 1)
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
          expect_next_instance_of(::Pages::MigrateLegacyStorageToDeploymentService, project, ignore_invalid_entries: false, mark_projects_as_not_deployed: false) do |service|
            expect(service).to receive(:execute).and_call_original
          end

          expect(project.pages_metadatum.reload.pages_deployment).to eq(nil)
          expect(subject).to eq(migrated: 1, errored: 0)
          expect(project.pages_metadatum.reload.pages_deployment).to be
        end

        context 'when deployed already exists for the project' do
          before do
            deployment = create(:pages_deployment, project: project)
            project.set_first_pages_deployment!(deployment)
          end

          it 'does not try to migrate project' do
            expect(::Pages::MigrateLegacyStorageToDeploymentService).not_to receive(:new)

            is_expected.to eq(migrated: 0, errored: 0)
          end
        end
      end
    end
  end

  describe '#execute_with_threads' do
    subject { service.execute_with_threads(threads: 3, batch_size: batch_size) }

    include_examples "migrates projects properly"

    context 'when there is work for multiple threads' do
      let(:batch_size) { 2 } # override to force usage of multiple threads

      it 'uses multiple threads' do
        projects = create_list(:project, 20)
        projects.each do |project|
          project.mark_pages_as_deployed

          FileUtils.mkdir_p File.join(project.pages_path, "public")
          File.open(File.join(project.pages_path, "public/index.html"), "w") do |f|
            f.write("Hello!")
          end
        end

        threads = Concurrent::Set.new

        expect(service).to receive(:migrate_project).exactly(20).times.and_wrap_original do |m, *args|
          threads.add(Thread.current)

          # sleep to be 100% certain that once thread can't consume all the queue
          # it works without it, but I want to avoid making this test flaky
          sleep(0.01)

          m.call(*args)
        end

        is_expected.to eq(migrated: 20, errored: 0)
        expect(threads.length).to eq(3)
      end
    end
  end

  describe "#execute_for_batch" do
    subject { service.execute_for_batch(Project.ids) }

    include_examples "migrates projects properly"

    it 'only tries to migrate projects with passed ids' do
      projects = create_list(:project, 5)

      projects.each(&:mark_pages_as_deployed)
      projects_to_migrate = projects.first(3)

      projects_to_migrate.each do |project|
        expect_next_instance_of(::Pages::MigrateLegacyStorageToDeploymentService, project, ignore_invalid_entries: false, mark_projects_as_not_deployed: false) do |service|
          expect(service).to receive(:execute).and_call_original
        end
      end

      expect(service.execute_for_batch(projects_to_migrate.pluck(:id))).to eq(migrated: 0, errored: 3)
    end
  end
end
