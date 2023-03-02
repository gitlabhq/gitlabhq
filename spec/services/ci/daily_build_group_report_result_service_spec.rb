# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::DailyBuildGroupReportResultService, '#execute', feature_category: :continuous_integration do
  let_it_be(:group) { create(:group, :private) }
  let_it_be(:pipeline) { create(:ci_pipeline, project: create(:project, group: group), created_at: '2020-02-06 00:01:10') }
  let_it_be(:rspec_job) { create(:ci_build, pipeline: pipeline, name: 'rspec 3/3', coverage: 80) }
  let_it_be(:karma_job) { create(:ci_build, pipeline: pipeline, name: 'karma 2/2', coverage: 90) }
  let_it_be(:extra_job) { create(:ci_build, pipeline: pipeline, name: 'extra', coverage: nil) }

  let(:coverages) { Ci::DailyBuildGroupReportResult.all }

  it 'creates daily code coverage record for each job in the pipeline that has coverage value' do
    described_class.new.execute(pipeline)

    Ci::DailyBuildGroupReportResult.find_by(group_name: 'rspec').tap do |coverage|
      expect(coverage).to have_attributes(
        project_id: pipeline.project.id,
        last_pipeline_id: pipeline.id,
        ref_path: pipeline.source_ref_path,
        group_name: rspec_job.group_name,
        data: { 'coverage' => rspec_job.coverage },
        date: pipeline.created_at.to_date,
        group_id: group.id
      )
    end

    Ci::DailyBuildGroupReportResult.find_by(group_name: 'karma').tap do |coverage|
      expect(coverage).to have_attributes(
        project_id: pipeline.project.id,
        last_pipeline_id: pipeline.id,
        ref_path: pipeline.source_ref_path,
        group_name: karma_job.group_name,
        data: { 'coverage' => karma_job.coverage },
        date: pipeline.created_at.to_date,
        group_id: group.id
      )
    end

    expect(Ci::DailyBuildGroupReportResult.find_by(group_name: 'extra')).to be_nil
  end

  it 'creates a project_ci_feature_usage record for the pipeline project' do
    described_class.new.execute(pipeline)

    expect(Projects::CiFeatureUsage.count).to eq(1)
    expect(Projects::CiFeatureUsage.first).to have_attributes(
      project_id: pipeline.project.id,
      feature: 'code_coverage',
      default_branch: false
    )
  end

  context 'when there are multiple builds with the same group name that report coverage' do
    let!(:test_job_1) { create(:ci_build, pipeline: pipeline, name: 'test 1/2', coverage: 70) }
    let!(:test_job_2) { create(:ci_build, pipeline: pipeline, name: 'test 2/2', coverage: 80) }

    it 'creates daily code coverage record with the average as the value' do
      described_class.new.execute(pipeline)

      Ci::DailyBuildGroupReportResult.find_by(group_name: 'test').tap do |coverage|
        expect(coverage).to have_attributes(
          project_id: pipeline.project.id,
          last_pipeline_id: pipeline.id,
          ref_path: pipeline.source_ref_path,
          group_name: test_job_2.group_name,
          data: { 'coverage' => 75.0 },
          date: pipeline.created_at.to_date
        )
      end
    end
  end

  context 'when there is an existing daily code coverage for the matching date, project, ref_path, and group name' do
    let!(:new_pipeline) do
      create(
        :ci_pipeline,
        project: pipeline.project,
        ref: pipeline.ref,
        created_at: '2020-02-06 00:02:20'
      )
    end

    let!(:new_rspec_job) { create(:ci_build, pipeline: new_pipeline, name: 'rspec 4/4', coverage: 84) }
    let!(:new_karma_job) { create(:ci_build, pipeline: new_pipeline, name: 'karma 3/3', coverage: 92) }

    before do
      # Create the existing daily code coverage records
      described_class.new.execute(pipeline)
    end

    it "updates the existing record's coverage value and last_pipeline_id" do
      rspec_coverage = Ci::DailyBuildGroupReportResult.find_by(group_name: 'rspec')
      karma_coverage = Ci::DailyBuildGroupReportResult.find_by(group_name: 'karma')

      # Bump up the coverage values
      described_class.new.execute(new_pipeline)

      rspec_coverage.reload
      karma_coverage.reload

      expect(rspec_coverage).to have_attributes(
        last_pipeline_id: new_pipeline.id,
        data: { 'coverage' => new_rspec_job.coverage }
      )

      expect(karma_coverage).to have_attributes(
        last_pipeline_id: new_pipeline.id,
        data: { 'coverage' => new_karma_job.coverage }
      )
    end

    it 'does not create a new project_ci_feature_usage record for the pipeline project' do
      expect { described_class.new.execute(pipeline) }.not_to change { Projects::CiFeatureUsage.count }

      expect(Projects::CiFeatureUsage.first).to have_attributes(
        project_id: pipeline.project.id,
        feature: 'code_coverage',
        default_branch: false
      )
    end
  end

  context 'when the ID of the pipeline is older than the last_pipeline_id' do
    let!(:new_pipeline) do
      create(
        :ci_pipeline,
        project: pipeline.project,
        ref: pipeline.ref,
        created_at: '2020-02-06 00:02:20'
      )
    end

    let!(:new_rspec_job) { create(:ci_build, pipeline: new_pipeline, name: 'rspec 4/4', coverage: 84) }
    let!(:new_karma_job) { create(:ci_build, pipeline: new_pipeline, name: 'karma 3/3', coverage: 92) }

    before do
      # Create the existing daily code coverage records
      # but in this case, for the newer pipeline first.
      described_class.new.execute(new_pipeline)
    end

    it 'updates the existing daily code coverage records' do
      rspec_coverage = Ci::DailyBuildGroupReportResult.find_by(group_name: 'rspec')
      karma_coverage = Ci::DailyBuildGroupReportResult.find_by(group_name: 'karma')

      # Run another one but for the older pipeline.
      # This simulates the scenario wherein the success worker
      # of an older pipeline, for some network hiccup, was delayed
      # and only got executed right after the newer pipeline's success worker.
      # Ideally, we don't want to bump the coverage value with an older one
      # but given this can be a rare edge case and can be remedied by re-running
      # the pipeline we'll just let it be for now. In return, we are able to use
      # Rails 6 shiny new method, upsert_all, and simplify the code a lot.
      described_class.new.execute(pipeline)

      rspec_coverage.reload
      karma_coverage.reload

      expect(rspec_coverage).to have_attributes(
        last_pipeline_id: pipeline.id,
        data: { 'coverage' => rspec_job.coverage }
      )

      expect(karma_coverage).to have_attributes(
        last_pipeline_id: pipeline.id,
        data: { 'coverage' => karma_job.coverage }
      )
    end
  end

  context 'when pipeline has no builds with coverage' do
    let!(:new_pipeline) do
      create(
        :ci_pipeline,
        created_at: '2020-02-06 00:02:20'
      )
    end

    let!(:some_job) { create(:ci_build, pipeline: new_pipeline, name: 'foo') }

    it 'does nothing' do
      expect { described_class.new.execute(new_pipeline) }.not_to raise_error
      expect(Ci::DailyBuildGroupReportResult.count).to eq(0)
      expect(Projects::CiFeatureUsage.count).to eq(0)
    end
  end

  context 'when pipeline ref_path is the project default branch' do
    let(:default_branch) { 'master' }

    before do
      allow(pipeline.project).to receive(:default_branch).and_return(default_branch)
    end

    it 'sets default branch to true' do
      described_class.new.execute(pipeline)

      coverages.each do |coverage|
        expect(coverage.default_branch).to be_truthy
      end
    end

    it 'creates a project_ci_feature_usage record for the pipeline project for default branch' do
      described_class.new.execute(pipeline)

      expect(Projects::CiFeatureUsage.count).to eq(1)
      expect(Projects::CiFeatureUsage.first).to have_attributes(
        project_id: pipeline.project.id,
        feature: 'code_coverage',
        default_branch: true
      )
    end
  end

  context 'when pipeline ref_path is not the project default branch' do
    it 'sets default branch to false' do
      described_class.new.execute(pipeline)

      coverages.each do |coverage|
        expect(coverage.default_branch).to be_falsey
      end
    end
  end
end
