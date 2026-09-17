# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Organizations::MaintenanceReadiness, feature_category: :organization do
  let_it_be(:organization) { create(:organization) }

  subject(:readiness) { described_class.new(organization) }

  describe '#blocking_reason' do
    context 'when nothing blocks maintenance' do
      it 'is nil' do
        expect(readiness.blocking_reason).to be_nil
      end

      it 'ignores non-active batched background migrations' do
        create(:batched_background_migration, :paused)
        create(:batched_background_migration, :finished)
        create(:batched_background_migration, :finalized)

        expect(readiness.blocking_reason).to be_nil
      end
    end

    context 'with an active batched background migration' do
      Gitlab::Database.database_base_models.each do |name, model|
        context "on the #{name} database" do
          before do
            skip "#{name} database is not configured" unless Gitlab::Database.has_database?(name)

            Gitlab::Database::SharedModel.using_connection(model.connection) do
              create(:batched_background_migration, :active)
            end
          end

          it 'reports the active migrations' do
            expect(readiness.blocking_reason).to eq('active batched background migrations')
          end
        end
      end
    end

    context 'with pending migrations' do
      def stub_pending_migration(filename)
        proxy = instance_double(ActiveRecord::MigrationProxy, version: 99999999999999, filename: filename)

        allow_next_instances_of(ActiveRecord::MigrationContext, nil) do |context|
          allow(context).to receive_messages(migrations: [proxy], get_all_versions: [])
        end
      end

      it 'reports a pending regular migration' do
        stub_pending_migration('db/migrate/99999999999999_pending_probe.rb')

        expect(readiness.blocking_reason).to eq('pending migrations')
      end

      it 'reports a pending post-deploy migration' do
        stub_pending_migration('db/post_migrate/99999999999999_pending_probe.rb')

        expect(readiness.blocking_reason).to eq('pending migrations')
      end
    end
  end
end
