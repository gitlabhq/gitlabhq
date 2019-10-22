require 'spec_helper'
require Rails.root.join('db', 'post_migrate', '20191017045817_schedule_fix_gitlab_com_pages_access_level.rb')

describe ScheduleFixGitlabComPagesAccessLevel, :migration, :sidekiq, schema: 2019_10_16_072826 do
  using RSpec::Parameterized::TableSyntax

  let(:migration_name) { 'FixGitlabComPagesAccessLevel' }

  ProjectClass = ::Gitlab::BackgroundMigration::FixGitlabComPagesAccessLevel::Project
  FeatureClass = ::Gitlab::BackgroundMigration::FixGitlabComPagesAccessLevel::ProjectFeature

  let(:namespaces_table) { table(:namespaces) }
  let(:projects_table) { table(:projects) }
  let(:features_table) { table(:project_features) }
  let(:pages_metadata_table) { table(:project_pages_metadata) }

  let(:subgroup) do
    root_group = namespaces_table.create(path: "group", name: "group")
    namespaces_table.create!(path: "subgroup", name: "group", parent_id: root_group.id)
  end

  before do
    allow(::Gitlab).to receive(:com?).and_return true
  end

  describe 'scheduling migration' do
    let!(:first_project) { create_project(ProjectClass::PRIVATE, FeatureClass::PRIVATE, false, false, 'first' ) }
    let!(:last_project) { create_project(ProjectClass::PRIVATE, FeatureClass::PRIVATE, false, false, 'second' ) }

    subject do
      Sidekiq::Testing.fake! do
        migrate!
      end
    end

    it 'schedules background migrations' do
      Timecop.freeze do
        subject

        expect(migration_name).to be_scheduled_delayed_migration(2.minutes, first_project.id, last_project.id)
        expect(BackgroundMigrationWorker.jobs.size).to eq(1)
      end
    end

    context 'not on gitlab.com' do
      before do
        allow(::Gitlab).to receive(:com?).and_return false
      end

      it 'does not schedule background migrations' do
        Timecop.freeze do
          subject

          expect(BackgroundMigrationWorker.jobs.size).to eq(0)
        end
      end
    end
  end

  where(:visibility_level, :pages_access_level,
        :pages_deployed, :ac_is_enabled_in_config,
        :result_pages_access_level) do
    # Does not change anything if pages are not deployed
    ProjectClass::PRIVATE  | FeatureClass::DISABLED | false | false | FeatureClass::DISABLED
    ProjectClass::PRIVATE  | FeatureClass::PRIVATE  | false | false | FeatureClass::PRIVATE
    ProjectClass::PRIVATE  | FeatureClass::ENABLED  | false | false | FeatureClass::ENABLED
    ProjectClass::PRIVATE  | FeatureClass::PUBLIC   | false | false | FeatureClass::PUBLIC
    ProjectClass::INTERNAL | FeatureClass::DISABLED | false | false | FeatureClass::DISABLED
    ProjectClass::INTERNAL | FeatureClass::PRIVATE  | false | false | FeatureClass::PRIVATE
    ProjectClass::INTERNAL | FeatureClass::ENABLED  | false | false | FeatureClass::ENABLED
    ProjectClass::INTERNAL | FeatureClass::PUBLIC   | false | false | FeatureClass::PUBLIC
    ProjectClass::PUBLIC   | FeatureClass::DISABLED | false | false | FeatureClass::DISABLED
    ProjectClass::PUBLIC   | FeatureClass::PRIVATE  | false | false | FeatureClass::PRIVATE
    ProjectClass::PUBLIC   | FeatureClass::ENABLED  | false | false | FeatureClass::ENABLED
    ProjectClass::PUBLIC   | FeatureClass::PUBLIC   | false | false | FeatureClass::PUBLIC

    # Does not change anything if pages are already private in config.json
    # many of these cases are invalid and will not occur in production
    ProjectClass::PRIVATE  | FeatureClass::DISABLED | true | true | FeatureClass::DISABLED
    ProjectClass::PRIVATE  | FeatureClass::PRIVATE  | true | true | FeatureClass::PRIVATE
    ProjectClass::PRIVATE  | FeatureClass::ENABLED  | true | true | FeatureClass::ENABLED
    ProjectClass::PRIVATE  | FeatureClass::PUBLIC   | true | true | FeatureClass::PUBLIC
    ProjectClass::INTERNAL | FeatureClass::DISABLED | true | true | FeatureClass::DISABLED
    ProjectClass::INTERNAL | FeatureClass::PRIVATE  | true | true | FeatureClass::PRIVATE
    ProjectClass::INTERNAL | FeatureClass::ENABLED  | true | true | FeatureClass::ENABLED
    ProjectClass::INTERNAL | FeatureClass::PUBLIC   | true | true | FeatureClass::PUBLIC
    ProjectClass::PUBLIC   | FeatureClass::DISABLED | true | true | FeatureClass::DISABLED
    ProjectClass::PUBLIC   | FeatureClass::PRIVATE  | true | true | FeatureClass::PRIVATE
    ProjectClass::PUBLIC   | FeatureClass::ENABLED  | true | true | FeatureClass::ENABLED
    ProjectClass::PUBLIC   | FeatureClass::PUBLIC   | true | true | FeatureClass::PUBLIC

    # when pages are deployed and ac is disabled in config
    ProjectClass::PRIVATE  | FeatureClass::DISABLED | true | false | FeatureClass::DISABLED
    ProjectClass::PRIVATE  | FeatureClass::PRIVATE  | true | false | FeatureClass::PUBLIC   # need to update
    ProjectClass::PRIVATE  | FeatureClass::ENABLED  | true | false | FeatureClass::PUBLIC   # invalid state, need to update
    ProjectClass::PRIVATE  | FeatureClass::PUBLIC   | true | false | FeatureClass::PUBLIC
    ProjectClass::INTERNAL | FeatureClass::DISABLED | true | false | FeatureClass::DISABLED
    ProjectClass::INTERNAL | FeatureClass::PRIVATE  | true | false | FeatureClass::PUBLIC   # need to update
    ProjectClass::INTERNAL | FeatureClass::ENABLED  | true | false | FeatureClass::PUBLIC   # invalid state, need to update
    ProjectClass::INTERNAL | FeatureClass::PUBLIC   | true | false | FeatureClass::PUBLIC
    ProjectClass::PUBLIC   | FeatureClass::DISABLED | true | false | FeatureClass::DISABLED
    ProjectClass::PUBLIC   | FeatureClass::PRIVATE  | true | false | FeatureClass::ENABLED  # need to update
    ProjectClass::PUBLIC   | FeatureClass::ENABLED  | true | false | FeatureClass::ENABLED
    ProjectClass::PUBLIC   | FeatureClass::PUBLIC   | true | false | FeatureClass::ENABLED  # invalid state, need to update
  end

  with_them do
    it 'fixes settings' do
      perform_enqueued_jobs do
        project = create_project(visibility_level, pages_access_level, pages_deployed, ac_is_enabled_in_config)

        expect(features_table.find_by(project_id: project.id).pages_access_level).to eq(pages_access_level)

        migrate!

        expect(features_table.find_by(project_id: project.id).pages_access_level).to eq(result_pages_access_level)
      end
    end
  end

  def create_project(visibility_level, pages_access_level, pages_deployed, ac_is_enabled_in_config, path = 'project')
    project = projects_table.create!(path: path, visibility_level: visibility_level,
                                     namespace_id: subgroup.id)

    pages_metadata_table.create!(project_id: project.id, deployed: pages_deployed)

    if pages_deployed
      FileUtils.mkdir_p(ProjectClass.find(project.id).public_pages_path)

      # write config.json
      allow(project).to receive(:public_pages?).and_return(!ac_is_enabled_in_config)
      allow(project).to receive(:pages_domains).and_return([])
      allow(project).to receive(:project_id).and_return(project.id)
      allow(project).to receive(:pages_path).and_return(ProjectClass.find(project.id).pages_path)
      Projects::UpdatePagesConfigurationService.new(project).execute
    end

    project.update!(visibility_level: visibility_level)
    features_table.create!(project_id: project.id, pages_access_level: pages_access_level)

    project
  end
end
