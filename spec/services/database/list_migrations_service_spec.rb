# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Database::ListMigrationsService, feature_category: :database do
  let(:service) { described_class.new(connection: connection, status: status) }
  let(:connection) { ApplicationRecord.connection }
  let(:status) { 'pending' }

  describe '#execute' do
    subject(:execute) { service.execute }

    context 'with mocked migration context' do
      let(:pending_migration) do
        instance_double(
          ActiveRecord::MigrationProxy,
          version: 1,
          name: 'migration_pending',
          filename: 'db/migrate/1_migration_pending.rb'
        )
      end

      let(:executed_migration) do
        instance_double(
          ActiveRecord::MigrationProxy,
          version: 2,
          name: 'migration_executed',
          filename: 'db/migrate/2_migration_executed.rb'
        )
      end

      let(:migrations) { [pending_migration, executed_migration] }

      before do
        ctx = instance_double(ActiveRecord::MigrationContext, migrations: migrations)

        allow(connection.pool).to receive(:migration_context).and_return(ctx)
        allow(service).to receive(:executed_versions).and_return([2])
      end

      it 'returns a success response' do
        is_expected.to be_success
      end

      context 'when status is pending' do
        let(:status) { 'pending' }

        it 'returns pending migrations' do
          result = execute.payload[:migrations]

          expect(result.size).to eq(1)
          expect(result.first).to eq({
            version: 1,
            name: 'migration_pending',
            filename: '1_migration_pending.rb',
            status: 'pending'
          })
        end

        context 'when all migrations are executed' do
          before do
            allow(service).to receive(:executed_versions).and_return([1, 2])
          end

          it 'returns an empty array' do
            result = execute.payload[:migrations]

            expect(result).to be_empty
          end
        end

        context 'when multiple pending migrations exist' do
          let(:another_pending_migration) do
            instance_double(
              ActiveRecord::MigrationProxy,
              version: 3,
              name: 'another_pending',
              filename: 'db/migrate/3_another_pending.rb'
            )
          end

          let(:migrations) { [another_pending_migration, pending_migration, executed_migration] }

          it 'returns migrations sorted by version ascending' do
            result = execute.payload[:migrations]

            expect(result.size).to eq(2)
            expect(result.pluck(:version)).to eq([1, 3])
          end
        end
      end

      context 'when status is executed' do
        let(:status) { 'executed' }

        it 'returns executed migrations' do
          result = execute.payload[:migrations]

          expect(result.size).to eq(1)
          expect(result.first).to eq({
            version: 2,
            name: 'migration_executed',
            filename: '2_migration_executed.rb',
            status: 'executed'
          })
        end
      end

      context 'when status is all' do
        let(:status) { 'all' }

        it 'returns all migrations' do
          result = execute.payload[:migrations]

          expect(result.size).to eq(2)
          expect(result.pluck(:version)).to eq([1, 2])
        end

        it 'includes correct status for each migration' do
          result = execute.payload[:migrations]

          expect(result.find { |m| m[:version] == 1 }[:status]).to eq('pending')
          expect(result.find { |m| m[:version] == 2 }[:status]).to eq('executed')
        end
      end

      context 'when no migrations exist' do
        let(:migrations) { [] }

        it 'returns an empty array' do
          result = execute.payload[:migrations]

          expect(result).to be_empty
        end
      end

      context 'when status is invalid' do
        let(:status) { 'invalid' }

        it 'returns an empty array' do
          result = execute.payload[:migrations]

          expect(result).to be_empty
        end
      end
    end

    context 'with actual migration context', :delete do
      it 'returns a success response with actual migrations' do
        result = service.execute

        expect(result).to be_success
        expect(result.payload[:migrations]).to be_an(Array)
      end

      it 'returns migrations with required attributes' do
        result = service.execute
        migrations = result.payload[:migrations]

        next if migrations.empty?

        migration = migrations.first
        expect(migration).to have_key(:version)
        expect(migration).to have_key(:name)
        expect(migration).to have_key(:filename)
        expect(migration).to have_key(:status)
        expect(migration[:status]).to eq('pending')
      end
    end
  end
end
