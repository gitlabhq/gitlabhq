# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ContainerRegistry::Migration::GuardWorker, :aggregate_failures do
  include_context 'container registry client'

  let(:worker) { described_class.new }

  describe '#perform' do
    let(:pre_importing_migrations) { ::ContainerRepository.with_migration_states(:pre_importing) }
    let(:pre_import_done_migrations) { ::ContainerRepository.with_migration_states(:pre_import_done) }
    let(:importing_migrations) { ::ContainerRepository.with_migration_states(:importing) }
    let(:import_aborted_migrations) { ::ContainerRepository.with_migration_states(:import_aborted) }
    let(:import_done_migrations) { ::ContainerRepository.with_migration_states(:import_done) }

    subject { worker.perform }

    before do
      stub_container_registry_config(enabled: true, api_url: registry_api_url, key: 'spec/fixtures/x509_certificate_pk.key')
      allow(::ContainerRegistry::Migration).to receive(:max_step_duration).and_return(5.minutes)
    end

    context 'on gitlab.com' do
      before do
        allow(::Gitlab).to receive(:com?).and_return(true)
      end

      context 'with no stale migrations' do
        it_behaves_like 'an idempotent worker'

        it 'will not update any migration state' do
          expect(worker).to receive(:log_extra_metadata_on_done).with(:stale_migrations_count, 0)
          expect { subject }
            .to not_change(pre_importing_migrations, :count)
            .and not_change(pre_import_done_migrations, :count)
            .and not_change(importing_migrations, :count)
            .and not_change(import_aborted_migrations, :count)
        end
      end

      context 'with pre_importing stale migrations' do
        let(:ongoing_migration) { create(:container_repository, :pre_importing) }
        let(:stale_migration) { create(:container_repository, :pre_importing, migration_pre_import_started_at: 10.minutes.ago) }

        it 'will abort the migration' do
          expect(worker).to receive(:log_extra_metadata_on_done).with(:stale_migrations_count, 1)
          expect { subject }
              .to change(pre_importing_migrations, :count).by(-1)
              .and not_change(pre_import_done_migrations, :count)
              .and not_change(importing_migrations, :count)
              .and not_change(import_done_migrations, :count)
              .and change(import_aborted_migrations, :count).by(1)
              .and change { stale_migration.reload.migration_state }.from('pre_importing').to('import_aborted')
              .and not_change { ongoing_migration.migration_state }
        end
      end

      context 'with pre_import_done stale migrations' do
        let(:ongoing_migration) { create(:container_repository, :pre_import_done) }
        let(:stale_migration) { create(:container_repository, :pre_import_done, migration_pre_import_done_at: 10.minutes.ago) }

        before do
          allow(::ContainerRegistry::Migration).to receive(:max_step_duration).and_return(5.minutes)
          expect(worker).to receive(:log_extra_metadata_on_done).with(:stale_migrations_count, 1)
        end

        it 'will abort the migration' do
          expect { subject }
              .to not_change(pre_importing_migrations, :count)
              .and change(pre_import_done_migrations, :count).by(-1)
              .and not_change(importing_migrations, :count)
              .and not_change(import_done_migrations, :count)
              .and change(import_aborted_migrations, :count).by(1)
              .and change { stale_migration.reload.migration_state }.from('pre_import_done').to('import_aborted')
              .and not_change { ongoing_migration.migration_state }
        end
      end

      context 'with importing stale migrations' do
        let(:ongoing_migration) { create(:container_repository, :importing) }
        let(:stale_migration) { create(:container_repository, :importing, migration_import_started_at: 10.minutes.ago) }

        before do
          allow(::ContainerRegistry::Migration).to receive(:max_step_duration).and_return(5.minutes)
          expect(worker).to receive(:log_extra_metadata_on_done).with(:stale_migrations_count, 1)
        end

        it 'will abort the migration' do
          expect { subject }
              .to not_change(pre_importing_migrations, :count)
              .and not_change(pre_import_done_migrations, :count)
              .and change(importing_migrations, :count).by(-1)
              .and not_change(import_done_migrations, :count)
              .and change(import_aborted_migrations, :count).by(1)
              .and change { stale_migration.reload.migration_state }.from('importing').to('import_aborted')
              .and not_change { ongoing_migration.migration_state }
        end
      end
    end

    context 'not on gitlab.com' do
      before do
        allow(::Gitlab).to receive(:com?).and_return(false)
      end

      it 'is a no op' do
        expect(::ContainerRepository).not_to receive(:with_stale_migration)
        expect(worker).not_to receive(:log_extra_metadata_on_done)

        subject
      end
    end
  end
end
