# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe ScheduleSecuritySettingCreation, :sidekiq, feature_category: :projects do
  describe '#up' do
    let(:projects) { table(:projects) }
    let(:namespaces) { table(:namespaces) }

    context 'for EE version' do
      before do
        stub_const("#{described_class.name}::BATCH_SIZE", 2)
        allow(Gitlab).to receive(:ee?).and_return(true)
      end

      it 'schedules background migration job' do
        namespace = namespaces.create!(name: 'test', path: 'test')
        projects.create!(id: 12, namespace_id: namespace.id, name: 'red', path: 'red')
        projects.create!(id: 13, namespace_id: namespace.id, name: 'green', path: 'green')
        projects.create!(id: 14, namespace_id: namespace.id, name: 'blue', path: 'blue')

        Sidekiq::Testing.fake! do
          freeze_time do
            migrate!

            expect(described_class::MIGRATION)
              .to be_scheduled_delayed_migration(5.minutes, 12, 13)

            expect(described_class::MIGRATION)
              .to be_scheduled_delayed_migration(10.minutes, 14, 14)

            expect(BackgroundMigrationWorker.jobs.size).to eq(2)
          end
        end
      end
    end

    context 'for FOSS version' do
      before do
        allow(Gitlab).to receive(:ee?).and_return(false)
      end

      it 'does not schedule any jobs' do
        namespace = namespaces.create!(name: 'test', path: 'test')
        projects.create!(id: 12, namespace_id: namespace.id, name: 'red', path: 'red')

        Sidekiq::Testing.fake! do
          freeze_time do
            migrate!

            expect(BackgroundMigrationWorker.jobs.size).to eq(0)
          end
        end
      end
    end
  end
end
