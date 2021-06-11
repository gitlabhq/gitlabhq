# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe FixWrongPagesAccessLevel, :sidekiq_might_not_need_inline, schema: 20190628185004 do
  using RSpec::Parameterized::TableSyntax

  let(:migration_class) { described_class::MIGRATION }
  let(:migration_name)  { migration_class.to_s.demodulize }

  project_class = ::Gitlab::BackgroundMigration::FixPagesAccessLevel::Project
  feature_class = ::Gitlab::BackgroundMigration::FixPagesAccessLevel::ProjectFeature

  let(:namespaces_table) { table(:namespaces) }
  let(:projects_table) { table(:projects) }
  let(:features_table) { table(:project_features) }

  let(:subgroup) do
    root_group = namespaces_table.create!(path: "group", name: "group")
    namespaces_table.create!(path: "subgroup", name: "group", parent_id: root_group.id)
  end

  def create_project_feature(path, project_visibility, pages_access_level)
    project = projects_table.create!(path: path, visibility_level: project_visibility,
                                     namespace_id: subgroup.id)
    features_table.create!(project_id: project.id, pages_access_level: pages_access_level)
  end

  it 'correctly schedules background migrations' do
    Sidekiq::Testing.fake! do
      freeze_time do
        first_id = create_project_feature("project1", project_class::PRIVATE, feature_class::PRIVATE).id
        last_id = create_project_feature("project2", project_class::PRIVATE, feature_class::PUBLIC).id

        migrate!

        expect(migration_name).to be_scheduled_delayed_migration(2.minutes, first_id, last_id)
        expect(BackgroundMigrationWorker.jobs.size).to eq(1)
      end
    end
  end

  def expect_migration
    expect do
      perform_enqueued_jobs do
        migrate!
      end
    end
  end

  where(:project_visibility, :pages_access_level, :access_control_is_enabled,
        :pages_deployed, :resulting_pages_access_level) do
    # update settings for public projects regardless of access_control being enabled
    project_class::PUBLIC | feature_class::PUBLIC | true | true  | feature_class::ENABLED
    project_class::PUBLIC | feature_class::PUBLIC | false | true | feature_class::ENABLED
    # don't update public level for private and internal projects
    project_class::PRIVATE | feature_class::PUBLIC  | true | true | feature_class::PUBLIC
    project_class::INTERNAL | feature_class::PUBLIC | true | true | feature_class::PUBLIC

    # if access control is disabled but pages are deployed we make them public
    project_class::INTERNAL | feature_class::ENABLED | false | true  | feature_class::PUBLIC
    # don't change anything if one of the conditions is not satisfied
    project_class::INTERNAL | feature_class::ENABLED | true  | true  | feature_class::ENABLED
    project_class::INTERNAL | feature_class::ENABLED | true  | false | feature_class::ENABLED

    # private projects
    # if access control is enabled update pages_access_level to private regardless of deployment
    project_class::PRIVATE | feature_class::ENABLED | true  | true  | feature_class::PRIVATE
    project_class::PRIVATE | feature_class::ENABLED | true  | false | feature_class::PRIVATE
    # if access control is disabled and pages are deployed update pages_access_level to public
    project_class::PRIVATE | feature_class::ENABLED | false | true  | feature_class::PUBLIC
    # if access control is disabled but pages aren't deployed update pages_access_level to private
    project_class::PRIVATE | feature_class::ENABLED | false | false | feature_class::PRIVATE
  end

  with_them do
    let!(:project_feature) do
      create_project_feature("projectpath", project_visibility, pages_access_level)
    end

    before do
      tested_path = File.join(Settings.pages.path, "group/subgroup/projectpath", "public")
      allow(Dir).to receive(:exist?).with(tested_path).and_return(pages_deployed)

      stub_pages_setting(access_control: access_control_is_enabled)
    end

    it "sets proper pages_access_level" do
      expect(project_feature.reload.pages_access_level).to eq(pages_access_level)

      perform_enqueued_jobs do
        migrate!
      end

      expect(project_feature.reload.pages_access_level).to eq(resulting_pages_access_level)
    end
  end
end
