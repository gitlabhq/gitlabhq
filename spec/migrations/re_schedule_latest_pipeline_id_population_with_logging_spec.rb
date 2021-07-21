# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe ReScheduleLatestPipelineIdPopulationWithLogging do
  let(:namespaces) { table(:namespaces) }
  let(:pipelines) { table(:ci_pipelines) }
  let(:projects) { table(:projects) }
  let(:project_settings) { table(:project_settings) }
  let(:vulnerability_statistics) { table(:vulnerability_statistics) }

  let(:letter_grade_a) { 0 }

  let(:namespace) { namespaces.create!(name: 'gitlab', path: 'gitlab-org') }
  let(:project_1) { projects.create!(namespace_id: namespace.id, name: 'Foo 1') }
  let(:project_2) { projects.create!(namespace_id: namespace.id, name: 'Foo 2') }
  let(:project_3) { projects.create!(namespace_id: namespace.id, name: 'Foo 3') }
  let(:project_4) { projects.create!(namespace_id: namespace.id, name: 'Foo 4') }

  before do
    project_settings.create!(project_id: project_1.id, has_vulnerabilities: true)
    project_settings.create!(project_id: project_2.id, has_vulnerabilities: true)
    project_settings.create!(project_id: project_3.id)
    project_settings.create!(project_id: project_4.id, has_vulnerabilities: true)

    pipeline = pipelines.create!(project_id: project_2.id, ref: 'master', sha: 'adf43c3a')

    vulnerability_statistics.create!(project_id: project_2.id, letter_grade: letter_grade_a, latest_pipeline_id: pipeline.id)
    vulnerability_statistics.create!(project_id: project_4.id, letter_grade: letter_grade_a)

    allow(Gitlab).to receive(:ee?).and_return(is_ee?)
    stub_const("#{described_class.name}::BATCH_SIZE", 1)
  end

  around do |example|
    freeze_time { example.run }
  end

  context 'when the installation is FOSS' do
    let(:is_ee?) { false }

    it 'does not schedule any background job' do
      migrate!

      expect(BackgroundMigrationWorker.jobs.size).to be(0)
    end
  end

  context 'when the installation is EE' do
    let(:is_ee?) { true }

    it 'schedules the background jobs' do
      migrate!

      expect(BackgroundMigrationWorker.jobs.size).to be(2)
      expect(described_class::MIGRATION).to be_scheduled_delayed_migration(described_class::DELAY_INTERVAL, project_1.id, project_1.id)
      expect(described_class::MIGRATION).to be_scheduled_delayed_migration(2 * described_class::DELAY_INTERVAL, project_4.id, project_4.id)
    end
  end
end
