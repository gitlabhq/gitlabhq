# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillProjectsWithCoverage,
               :suppress_gitlab_schemas_validate_connection, schema: 20210818185845 do
  let(:projects) { table(:projects) }
  let(:project_ci_feature_usages) { table(:project_ci_feature_usages) }
  let(:ci_pipelines) { table(:ci_pipelines) }
  let(:ci_daily_build_group_report_results) { table(:ci_daily_build_group_report_results) }
  let(:group) { table(:namespaces).create!(name: 'user', path: 'user') }
  let(:project_1) { projects.create!(namespace_id: group.id) }
  let(:project_2) { projects.create!(namespace_id: group.id) }
  let(:pipeline_1) { ci_pipelines.create!(project_id: project_1.id, source: 13) }
  let(:pipeline_2) { ci_pipelines.create!(project_id: project_1.id, source: 13) }
  let(:pipeline_3) { ci_pipelines.create!(project_id: project_2.id, source: 13) }
  let(:pipeline_4) { ci_pipelines.create!(project_id: project_2.id, source: 13) }

  subject { described_class.new }

  describe '#perform' do
    before do
      ci_daily_build_group_report_results.create!(
        id: 1,
        project_id: project_1.id,
        date: 4.days.ago,
        last_pipeline_id: pipeline_1.id,
        ref_path: 'main',
        group_name: 'rspec',
        data: { coverage: 95.0 },
        default_branch: true,
        group_id: group.id
      )

      ci_daily_build_group_report_results.create!(
        id: 2,
        project_id: project_1.id,
        date: 3.days.ago,
        last_pipeline_id: pipeline_2.id,
        ref_path: 'main',
        group_name: 'rspec',
        data: { coverage: 95.0 },
        default_branch: true,
        group_id: group.id
      )

      ci_daily_build_group_report_results.create!(
        id: 3,
        project_id: project_2.id,
        date: 2.days.ago,
        last_pipeline_id: pipeline_3.id,
        ref_path: 'main',
        group_name: 'rspec',
        data: { coverage: 95.0 },
        default_branch: true,
        group_id: group.id
      )

      ci_daily_build_group_report_results.create!(
        id: 4,
        project_id: project_2.id,
        date: 1.day.ago,
        last_pipeline_id: pipeline_4.id,
        ref_path: 'test_branch',
        group_name: 'rspec',
        data: { coverage: 95.0 },
        default_branch: false,
        group_id: group.id
      )

      stub_const("#{described_class}::INSERT_DELAY_SECONDS", 0)
    end

    it 'creates entries per project and default_branch combination in the given range', :aggregate_failures do
      subject.perform(1, 4, 2)

      entries = project_ci_feature_usages.order('project_id ASC, default_branch DESC')

      expect(entries.count).to eq(3)
      expect(entries[0]).to have_attributes(project_id: project_1.id, feature: 1, default_branch: true)
      expect(entries[1]).to have_attributes(project_id: project_2.id, feature: 1, default_branch: true)
      expect(entries[2]).to have_attributes(project_id: project_2.id, feature: 1, default_branch: false)
    end

    context 'when an entry for the project and default branch combination already exists' do
      before do
        subject.perform(1, 4, 2)
      end

      it 'does not create a new entry' do
        expect { subject.perform(1, 4, 2) }.not_to change { project_ci_feature_usages.count }
      end
    end
  end
end
