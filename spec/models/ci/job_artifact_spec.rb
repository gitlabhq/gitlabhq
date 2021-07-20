# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::JobArtifact do
  let(:artifact) { create(:ci_job_artifact, :archive) }

  describe "Associations" do
    it { is_expected.to belong_to(:project) }
    it { is_expected.to belong_to(:job) }
  end

  it { is_expected.to respond_to(:file) }
  it { is_expected.to respond_to(:created_at) }
  it { is_expected.to respond_to(:updated_at) }

  it { is_expected.to delegate_method(:open).to(:file) }
  it { is_expected.to delegate_method(:exists?).to(:file) }

  it_behaves_like 'having unique enum values'

  it_behaves_like 'UpdateProjectStatistics', :with_counter_attribute do
    let_it_be(:job, reload: true) { create(:ci_build) }

    subject { build(:ci_job_artifact, :archive, job: job, size: 107464) }
  end

  describe '.not_expired' do
    it 'returns artifacts that have not expired' do
      _expired_artifact = create(:ci_job_artifact, :expired)

      expect(described_class.not_expired).to contain_exactly(artifact)
    end
  end

  describe '.with_reports' do
    let!(:artifact) { create(:ci_job_artifact, :archive) }

    subject { described_class.with_reports }

    it { is_expected.to be_empty }

    context 'when there are reports' do
      let!(:metrics_report) { create(:ci_job_artifact, :junit) }
      let!(:codequality_report) { create(:ci_job_artifact, :codequality) }

      it { is_expected.to match_array([metrics_report, codequality_report]) }
    end
  end

  describe '.test_reports' do
    subject { described_class.test_reports }

    context 'when there is a test report' do
      let!(:artifact) { create(:ci_job_artifact, :junit) }

      it { is_expected.to eq([artifact]) }
    end

    context 'when there are no test reports' do
      let!(:artifact) { create(:ci_job_artifact, :archive) }

      it { is_expected.to be_empty }
    end
  end

  describe '.accessibility_reports' do
    subject { described_class.accessibility_reports }

    context 'when there is an accessibility report' do
      let(:artifact) { create(:ci_job_artifact, :accessibility) }

      it { is_expected.to eq([artifact]) }
    end

    context 'when there are no accessibility report' do
      let(:artifact) { create(:ci_job_artifact, :archive) }

      it { is_expected.to be_empty }
    end
  end

  describe '.coverage_reports' do
    subject { described_class.coverage_reports }

    context 'when there is a coverage report' do
      let!(:artifact) { create(:ci_job_artifact, :cobertura) }

      it { is_expected.to eq([artifact]) }
    end

    context 'when there are no coverage reports' do
      let!(:artifact) { create(:ci_job_artifact, :archive) }

      it { is_expected.to be_empty }
    end
  end

  describe '.codequality_reports' do
    subject { described_class.codequality_reports }

    context 'when there is a codequality report' do
      let!(:artifact) { create(:ci_job_artifact, :codequality) }

      it { is_expected.to eq([artifact]) }
    end

    context 'when there are no codequality reports' do
      let!(:artifact) { create(:ci_job_artifact, :archive) }

      it { is_expected.to be_empty }
    end
  end

  describe '.terraform_reports' do
    context 'when there is a terraform report' do
      it 'return the job artifact' do
        artifact = create(:ci_job_artifact, :terraform)

        expect(described_class.terraform_reports).to eq([artifact])
      end
    end

    context 'when there are no terraform reports' do
      it 'return the an empty array' do
        expect(described_class.terraform_reports).to eq([])
      end
    end
  end

  describe '.associated_file_types_for' do
    using RSpec::Parameterized::TableSyntax

    subject { Ci::JobArtifact.associated_file_types_for(file_type) }

    where(:file_type, :result) do
      'codequality'         | %w(codequality)
      'quality'             | nil
    end

    with_them do
      it { is_expected.to eq result }
    end
  end

  describe '.erasable' do
    subject { described_class.erasable }

    context 'when there is an erasable artifact' do
      let!(:artifact) { create(:ci_job_artifact, :junit) }

      it { is_expected.to eq([artifact]) }
    end

    context 'when there are no erasable artifacts' do
      let!(:artifact) { create(:ci_job_artifact, :trace) }

      it { is_expected.to be_empty }
    end
  end

  describe '.downloadable' do
    subject { described_class.downloadable }

    it 'filters for downloadable artifacts' do
      downloadable_artifact = create(:ci_job_artifact, :codequality)
      _not_downloadable_artifact = create(:ci_job_artifact, :trace)

      expect(subject).to contain_exactly(downloadable_artifact)
    end
  end

  describe '.archived_trace_exists_for?' do
    subject { described_class.archived_trace_exists_for?(job_id) }

    let!(:artifact) { create(:ci_job_artifact, :trace, job: job) }
    let(:job) { create(:ci_build) }

    context 'when the specified job_id exists' do
      let(:job_id) { job.id }

      it { is_expected.to be_truthy }

      context 'when the job does have archived trace' do
        let!(:artifact) { }

        it { is_expected.to be_falsy }
      end
    end

    context 'when the specified job_id does not exist' do
      let(:job_id) { 10000 }

      it { is_expected.to be_falsy }
    end
  end

  describe '#archived_trace_exists?' do
    subject { artifact.archived_trace_exists? }

    context 'when the file exists' do
      it { is_expected.to be_truthy }
    end

    context 'when the file does not exist' do
      before do
        artifact.file.remove!
      end

      it { is_expected.to be_falsy }
    end
  end

  describe '.for_sha' do
    let(:first_pipeline) { create(:ci_pipeline) }
    let(:second_pipeline) { create(:ci_pipeline, project: first_pipeline.project, sha: Digest::SHA1.hexdigest(SecureRandom.hex)) }
    let!(:first_artifact) { create(:ci_job_artifact, job: create(:ci_build, pipeline: first_pipeline)) }
    let!(:second_artifact) { create(:ci_job_artifact, job: create(:ci_build, pipeline: second_pipeline)) }

    it 'returns job artifacts for a given pipeline sha' do
      expect(described_class.for_sha(first_pipeline.sha, first_pipeline.project.id)).to eq([first_artifact])
      expect(described_class.for_sha(second_pipeline.sha, first_pipeline.project.id)).to eq([second_artifact])
    end
  end

  describe '.for_job_name' do
    it 'returns job artifacts for a given job name' do
      first_job = create(:ci_build, name: 'first')
      second_job = create(:ci_build, name: 'second')
      first_artifact = create(:ci_job_artifact, job: first_job)
      second_artifact = create(:ci_job_artifact, job: second_job)

      expect(described_class.for_job_name(first_job.name)).to eq([first_artifact])
      expect(described_class.for_job_name(second_job.name)).to eq([second_artifact])
    end
  end

  describe '.unlocked' do
    let_it_be(:job_artifact) { create(:ci_job_artifact) }

    context 'with locked pipelines' do
      before do
        job_artifact.job.pipeline.artifacts_locked!
      end

      it 'returns an empty array' do
        expect(described_class.unlocked).to be_empty
      end
    end

    context 'with unlocked pipelines' do
      before do
        job_artifact.job.pipeline.unlocked!
      end

      it 'returns the artifact' do
        expect(described_class.unlocked).to eq([job_artifact])
      end
    end
  end

  describe '.order_expired_desc' do
    let_it_be(:first_artifact) { create(:ci_job_artifact, expire_at: 2.days.ago) }
    let_it_be(:second_artifact) { create(:ci_job_artifact, expire_at: 1.day.ago) }

    it 'returns ordered artifacts' do
      expect(described_class.order_expired_desc).to eq([second_artifact, first_artifact])
    end
  end

  describe '.for_project' do
    it 'returns artifacts only for given project(s)', :aggregate_failures do
      artifact1 = create(:ci_job_artifact)
      artifact2 = create(:ci_job_artifact)
      create(:ci_job_artifact)

      expect(described_class.for_project(artifact1.project)).to match_array([artifact1])
      expect(described_class.for_project([artifact1.project, artifact2.project])).to match_array([artifact1, artifact2])
    end
  end

  describe 'created_in_time_range' do
    it 'returns artifacts created in given time range', :aggregate_failures do
      artifact1 = create(:ci_job_artifact, created_at: 1.day.ago)
      artifact2 = create(:ci_job_artifact, created_at: 1.month.ago)
      artifact3 = create(:ci_job_artifact, created_at: 1.year.ago)

      expect(described_class.created_in_time_range(from: 1.week.ago)).to match_array([artifact1])
      expect(described_class.created_in_time_range(to: 1.week.ago)).to match_array([artifact2, artifact3])
      expect(described_class.created_in_time_range(from: 2.months.ago, to: 1.week.ago)).to match_array([artifact2])
    end
  end

  describe 'callbacks' do
    describe '#schedule_background_upload' do
      subject { create(:ci_job_artifact, :archive) }

      context 'when object storage is disabled' do
        before do
          stub_artifacts_object_storage(enabled: false)
        end

        it 'does not schedule the migration' do
          expect(ObjectStorage::BackgroundMoveWorker).not_to receive(:perform_async)

          subject
        end
      end

      context 'when object storage is enabled' do
        context 'when background upload is enabled' do
          before do
            stub_artifacts_object_storage(background_upload: true)
          end

          it 'schedules the model for migration' do
            expect(ObjectStorage::BackgroundMoveWorker).to receive(:perform_async).with('JobArtifactUploader', described_class.name, :file, kind_of(Numeric))

            subject
          end
        end

        context 'when background upload is disabled' do
          before do
            stub_artifacts_object_storage(background_upload: false)
          end

          it 'schedules the model for migration' do
            expect(ObjectStorage::BackgroundMoveWorker).not_to receive(:perform_async)

            subject
          end
        end
      end
    end
  end

  context 'creating the artifact' do
    let(:project) { create(:project) }
    let(:artifact) { create(:ci_job_artifact, :archive, project: project) }

    it 'sets the size from the file size' do
      expect(artifact.size).to eq(107464)
    end
  end

  context 'updating the artifact file' do
    it 'updates the artifact size' do
      artifact.update!(file: fixture_file_upload('spec/fixtures/dk.png'))
      expect(artifact.size).to eq(1062)
    end
  end

  describe 'validates file format' do
    subject { artifact }

    described_class::TYPE_AND_FORMAT_PAIRS.except(:trace).each do |file_type, file_format|
      context "when #{file_type} type with #{file_format} format" do
        let(:artifact) { build(:ci_job_artifact, file_type: file_type, file_format: file_format) }

        it { is_expected.to be_valid }
      end

      context "when #{file_type} type without format specification" do
        let(:artifact) { build(:ci_job_artifact, file_type: file_type, file_format: nil) }

        it { is_expected.not_to be_valid }
      end

      context "when #{file_type} type with other formats" do
        described_class.file_formats.except(file_format).values.each do |other_format|
          let(:artifact) { build(:ci_job_artifact, file_type: file_type, file_format: other_format) }

          it { is_expected.not_to be_valid }
        end
      end
    end
  end

  describe 'validates DEFAULT_FILE_NAMES' do
    subject { described_class::DEFAULT_FILE_NAMES }

    described_class.file_types.each do |file_type, _|
      it "expects #{file_type} to be included" do
        is_expected.to include(file_type.to_sym)
      end
    end
  end

  describe 'validates TYPE_AND_FORMAT_PAIRS' do
    subject { described_class::TYPE_AND_FORMAT_PAIRS }

    described_class.file_types.each do |file_type, _|
      it "expects #{file_type} to be included" do
        expect(described_class.file_formats).to include(subject[file_type.to_sym])
      end
    end
  end

  describe '#file' do
    subject { artifact.file }

    context 'the uploader api' do
      it { is_expected.to respond_to(:store_dir) }
      it { is_expected.to respond_to(:cache_dir) }
      it { is_expected.to respond_to(:work_dir) }
    end
  end

  describe 'expired?' do
    subject { artifact.expired? }

    context 'when expire_at is nil' do
      let(:artifact) { build(:ci_job_artifact, expire_at: nil) }

      it 'returns false' do
        is_expected.to be_falsy
      end
    end

    context 'when expire_at is in the past' do
      let(:artifact) { build(:ci_job_artifact, expire_at: Date.yesterday) }

      it 'returns true' do
        is_expected.to be_truthy
      end
    end

    context 'when expire_at is in the future' do
      let(:artifact) { build(:ci_job_artifact, expire_at: Date.tomorrow) }

      it 'returns false' do
        is_expected.to be_falsey
      end
    end
  end

  describe '#expiring?' do
    subject { artifact.expiring? }

    context 'when expire_at is nil' do
      let(:artifact) { build(:ci_job_artifact, expire_at: nil) }

      it 'returns false' do
        is_expected.to be_falsy
      end
    end

    context 'when expire_at is in the past' do
      let(:artifact) { build(:ci_job_artifact, expire_at: Date.yesterday) }

      it 'returns false' do
        is_expected.to be_falsy
      end
    end

    context 'when expire_at is in the future' do
      let(:artifact) { build(:ci_job_artifact, expire_at: Date.tomorrow) }

      it 'returns true' do
        is_expected.to be_truthy
      end
    end
  end

  describe '#expire_in' do
    subject { artifact.expire_in }

    it { is_expected.to be_nil }

    context 'when expire_at is specified' do
      let(:expire_at) { Time.current + 7.days }

      before do
        artifact.expire_at = expire_at
      end

      it { is_expected.to be_within(5).of(expire_at - Time.current) }
    end
  end

  describe '#expire_in=' do
    subject { artifact.expire_in }

    it 'when assigning valid duration' do
      artifact.expire_in = '7 days'

      is_expected.to be_within(10).of(7.days.to_i)
    end

    it 'when assigning invalid duration' do
      expect { artifact.expire_in = '7 elephants' }.to raise_error(ChronicDuration::DurationParseError)

      is_expected.to be_nil
    end

    it 'when resetting value' do
      artifact.expire_in = nil

      is_expected.to be_nil
    end

    it 'when setting to 0' do
      artifact.expire_in = '0'

      is_expected.to be_nil
    end
  end

  describe 'file is being stored' do
    subject { create(:ci_job_artifact, :archive) }

    context 'when existing object has local store' do
      it_behaves_like 'mounted file in local store'
    end

    context 'when direct upload is enabled' do
      before do
        stub_artifacts_object_storage(direct_upload: true)
      end

      context 'when file is stored' do
        it_behaves_like 'mounted file in object store'
      end
    end
  end

  describe '.file_types' do
    context 'all file types have corresponding limit' do
      let_it_be(:plan_limits) { create(:plan_limits) }

      where(:file_type) do
        described_class.file_types.keys
      end

      with_them do
        let(:limit_name) { "#{described_class::PLAN_LIMIT_PREFIX}#{file_type}" }

        it { expect(plan_limits.attributes).to include(limit_name), file_type_limit_failure_message(file_type, limit_name) }
      end
    end
  end

  describe '.max_artifact_size' do
    let(:build) { create(:ci_build) }

    subject(:max_size) { described_class.max_artifact_size(type: artifact_type, project: build.project) }

    context 'when file type is supported' do
      let(:project_closest_setting) { 1024 }
      let(:artifact_type) { 'junit' }
      let(:limit_name) { "#{described_class::PLAN_LIMIT_PREFIX}#{artifact_type}" }

      let!(:plan_limits) { create(:plan_limits, :default_plan) }

      shared_examples_for 'basing off the project closest setting' do
        it { is_expected.to eq(project_closest_setting.megabytes.to_i) }
      end

      shared_examples_for 'basing off the plan limit' do
        it { is_expected.to eq(max_size_for_type.megabytes.to_i) }
      end

      before do
        allow(build.project).to receive(:closest_setting).with(:max_artifacts_size).and_return(project_closest_setting)
      end

      context 'and plan limit is disabled for the given artifact type' do
        before do
          plan_limits.update!(limit_name => 0)
        end

        it_behaves_like 'basing off the project closest setting'

        context 'and project closest setting results to zero' do
          let(:project_closest_setting) { 0 }

          it { is_expected.to eq(0) }
        end
      end

      context 'and plan limit is enabled for the given artifact type' do
        before do
          plan_limits.update!(limit_name => max_size_for_type)
        end

        context 'and plan limit is smaller than project setting' do
          let(:max_size_for_type) { project_closest_setting - 1 }

          it_behaves_like 'basing off the plan limit'
        end

        context 'and plan limit is larger than project setting' do
          let(:max_size_for_type) { project_closest_setting + 1 }

          it_behaves_like 'basing off the project closest setting'
        end
      end
    end
  end

  context 'FastDestroyAll' do
    let_it_be(:project) { create(:project) }
    let_it_be(:pipeline) { create(:ci_pipeline, project: project) }
    let_it_be(:job) { create(:ci_build, pipeline: pipeline, project: project) }

    let!(:job_artifact) { create(:ci_job_artifact, :archive, job: job) }
    let(:subjects) { pipeline.job_artifacts }

    describe '.use_fast_destroy' do
      it 'performs cascading delete with fast_destroy_all' do
        expect(Ci::DeletedObject.count).to eq(0)
        expect(subjects.count).to be > 0

        expect { pipeline.destroy! }.not_to raise_error

        expect(subjects.count).to eq(0)
        expect(Ci::DeletedObject.count).to be > 0
      end

      it 'updates project statistics' do
        expect(ProjectStatistics).to receive(:increment_statistic).once
              .with(project, :build_artifacts_size, -job_artifact.file.size)

        pipeline.destroy!
      end
    end
  end

  def file_type_limit_failure_message(type, limit_name)
    <<~MSG
      The artifact type `#{type}` is missing its counterpart plan limit which is expected to be named `#{limit_name}`.

      Please refer to https://docs.gitlab.com/ee/development/application_limits.html on how to add new plan limit columns.

      Take note that while existing max size plan limits default to 0, succeeding new limits are recommended to have
      non-zero default values. Also, remember to update the plan limits documentation (doc/administration/instance_limits.md)
      when changes or new entries are made.
    MSG
  end
end
