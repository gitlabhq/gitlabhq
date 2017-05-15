require 'spec_helper'
require Rails.root.join('db', 'post_migrate', '20170301205640_migrate_build_events_to_pipeline_events.rb')

# This migration uses multiple threads, and thus different transactions. This
# means data created in this spec may not be visible to some threads. To work
# around this we use the TRUNCATE cleaning strategy.
describe MigrateBuildEventsToPipelineEvents, truncate: true do
  let(:migration) { described_class.new }
  let(:project_with_pipeline_service) { create(:empty_project) }
  let(:project_with_build_service) { create(:empty_project) }

  before do
    ActiveRecord::Base.connection.execute <<-SQL
      INSERT INTO services (properties, build_events, pipeline_events, type)
      VALUES
        ('{"notify_only_broken_builds":true}', true, false, 'SlackService')
      , ('{"notify_only_broken_builds":true}', true, false, 'MattermostService')
      , ('{"notify_only_broken_builds":true}', true, false, 'HipchatService')
      ;
    SQL

    ActiveRecord::Base.connection.execute <<-SQL
      INSERT INTO services
        (properties, build_events, pipeline_events, type, project_id)
      VALUES
        ('{"notify_only_broken_builds":true}', true, false,
         'BuildsEmailService', #{project_with_pipeline_service.id})
      , ('{"notify_only_broken_pipelines":true}', false, true,
         'PipelinesEmailService', #{project_with_pipeline_service.id})
      , ('{"notify_only_broken_builds":true}', true, false,
         'BuildsEmailService', #{project_with_build_service.id})
      ;
    SQL
  end

  describe '#up' do
    before do
      silence_migration = Module.new do
        # rubocop:disable Rails/Delegate
        def execute(query)
          connection.execute(query)
        end
      end

      migration.extend(silence_migration)
      migration.up
    end

    it 'migrates chat service properly' do
      [SlackService, MattermostService, HipchatService].each do |service|
        expect(service.count).to eq(1)

        verify_service_record(service.first)
      end
    end

    it 'migrates pipelines email service only if it has none before' do
      Project.find_each do |project|
        pipeline_service_count =
          project.services.where(type: 'PipelinesEmailService').count

        expect(pipeline_service_count).to eq(1)

        verify_service_record(project.pipelines_email_service)
      end
    end

    def verify_service_record(service)
      expect(service.notify_only_broken_pipelines).to be(true)
      expect(service.build_events).to be(false)
      expect(service.pipeline_events).to be(true)
    end
  end
end
