# frozen_string_literal: true

require 'spec_helper'

RSpec.describe DeleteContainerRepositoryWorker do
  let_it_be(:repository) { create(:container_repository) }

  let(:project) { repository.project }
  let(:user) { project.first_owner }
  let(:worker) { described_class.new }

  describe '#perform' do
    let(:user_id) { user.id }
    let(:repository_id) { repository.id }

    subject(:perform) { worker.perform(user_id, repository_id) }

    it 'executes the destroy service' do
      expect_destroy_service_execution

      perform
    end

    context 'with an invalid user id' do
      let(:user_id) { -1 }

      it { expect { perform }.not_to raise_error }
    end

    context 'with an invalid repository id' do
      let(:repository_id) { -1 }

      it { expect { perform }.not_to raise_error }
    end

    context 'with a repository being migrated', :freeze_time do
      before do
        stub_application_setting(
          container_registry_pre_import_tags_rate: 0.5,
          container_registry_import_timeout: 10.minutes.to_i
        )
      end

      shared_examples 'destroying the repository' do
        it 'does destroy the repository' do
          expect_next_found_instance_of(ContainerRepository) do |container_repository|
            expect(container_repository).not_to receive(:tags_count)
          end
          expect(described_class).not_to receive(:perform_in)
          expect_destroy_service_execution

          perform
        end
      end

      shared_examples 'not re enqueuing job if feature flag is disabled' do
        before do
          stub_feature_flags(container_registry_migration_phase2_delete_container_repository_worker_support: false)
        end

        it_behaves_like 'destroying the repository'
      end

      context 'with migration state set to pre importing' do
        let_it_be(:repository) { create(:container_repository, :pre_importing) }

        let(:tags_count) { 60 }
        let(:delay) { (tags_count * 0.5).seconds + 10.minutes + described_class::FIXED_DELAY }

        it 'does not destroy the repository and re enqueue the job' do
          expect_next_found_instance_of(ContainerRepository) do |container_repository|
            expect(container_repository).to receive(:tags_count).and_return(tags_count)
          end
          expect(described_class).to receive(:perform_in).with(delay.from_now)
          expect(worker).to receive(:log_extra_metadata_on_done).with(:delete_postponed, delay)
          expect(::Projects::ContainerRepository::DestroyService).not_to receive(:new)

          perform
        end

        it_behaves_like 'not re enqueuing job if feature flag is disabled'
      end

      %i[pre_import_done importing import_aborted].each do |migration_state|
        context "with migration state set to #{migration_state}" do
          let_it_be(:repository) { create(:container_repository, migration_state) }

          let(:delay) { 10.minutes + described_class::FIXED_DELAY }

          it 'does not destroy the repository and re enqueue the job' do
            expect_next_found_instance_of(ContainerRepository) do |container_repository|
              expect(container_repository).not_to receive(:tags_count)
            end
            expect(described_class).to receive(:perform_in).with(delay.from_now)
            expect(worker).to receive(:log_extra_metadata_on_done).with(:delete_postponed, delay)
            expect(::Projects::ContainerRepository::DestroyService).not_to receive(:new)

            perform
          end

          it_behaves_like 'not re enqueuing job if feature flag is disabled'
        end
      end

      %i[default import_done import_skipped].each do |migration_state|
        context "with migration state set to #{migration_state}" do
          let_it_be(:repository) { create(:container_repository, migration_state) }

          it_behaves_like 'destroying the repository'
          it_behaves_like 'not re enqueuing job if feature flag is disabled'
        end
      end
    end

    def expect_destroy_service_execution
      service = instance_double(Projects::ContainerRepository::DestroyService)
      expect(service).to receive(:execute)
      expect(Projects::ContainerRepository::DestroyService).to receive(:new).with(project, user).and_return(service)
    end
  end
end
