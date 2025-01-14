# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::JobArtifact, feature_category: :job_artifacts do
  let(:artifact) { create(:ci_job_artifact, :archive) }

  describe "Associations" do
    it { is_expected.to belong_to(:project) }
    it { is_expected.to belong_to(:job).class_name('Ci::Build').with_foreign_key(:job_id).inverse_of(:job_artifacts) }
    it { is_expected.to validate_presence_of(:job) }
    it { is_expected.to validate_presence_of(:partition_id) }
  end

  it { is_expected.to respond_to(:file) }
  it { is_expected.to respond_to(:created_at) }
  it { is_expected.to respond_to(:updated_at) }

  it { is_expected.to delegate_method(:open).to(:file) }
  it { is_expected.to delegate_method(:exists?).to(:file) }

  it_behaves_like 'having unique enum values'

  it_behaves_like 'UpdateProjectStatistics', :with_counter_attribute do
    let_it_be(:job, reload: true) { create(:ci_build) }

    subject { build(:ci_job_artifact, :archive, job: job, size: ci_artifact_fixture_size) }
  end

  describe 'after_create_commit callback' do
    it 'logs the job artifact create' do
      artifact = build(:ci_job_artifact, file_type: 3, size: 8888, file_format: 2, locked: 1)

      expect(Gitlab::Ci::Artifacts::Logger).to receive(:log_created) do |record|
        expect(record.size).to eq(artifact.size)
        expect(record.file_type).to eq(artifact.file_type)
        expect(record.file_format).to eq(artifact.file_format)
        expect(record.locked).to eq(artifact.locked)
      end

      artifact.save!
    end
  end

  describe 'after_destroy_commit callback' do
    it 'logs the job artifact destroy' do
      expect(Gitlab::Ci::Artifacts::Logger).to receive(:log_deleted).with(artifact, :log_destroy)

      artifact.destroy!
    end
  end

  describe '.not_expired' do
    it 'returns artifacts that have not expired' do
      _expired_artifact = create(:ci_job_artifact, :expired)

      expect(described_class.not_expired).to contain_exactly(artifact)
    end
  end

  describe '.all_reports' do
    let!(:artifact) { create(:ci_job_artifact, :archive) }

    subject { described_class.all_reports }

    it { is_expected.to be_empty }

    context 'when there are reports' do
      let!(:metrics_report) { create(:ci_job_artifact, :junit) }
      let!(:codequality_report) { create(:ci_job_artifact, :codequality) }

      it { is_expected.to match_array([metrics_report, codequality_report]) }
    end
  end

  describe '.of_report_type' do
    subject { described_class.of_report_type(report_type) }

    describe 'test_reports' do
      let(:report_type) { :test }

      context 'when there is a test report' do
        let!(:artifact) { create(:ci_job_artifact, :junit) }

        it { is_expected.to eq([artifact]) }
      end

      context 'when there are no test reports' do
        let!(:artifact) { create(:ci_job_artifact, :archive) }

        it { is_expected.to be_empty }
      end
    end

    describe 'accessibility_reports' do
      let(:report_type) { :accessibility }

      context 'when there is an accessibility report' do
        let(:artifact) { create(:ci_job_artifact, :accessibility) }

        it { is_expected.to eq([artifact]) }
      end

      context 'when there are no accessibility report' do
        let(:artifact) { create(:ci_job_artifact, :archive) }

        it { is_expected.to be_empty }
      end
    end

    describe 'coverage_reports' do
      let(:report_type) { :coverage }

      context 'when there is a cobertura report' do
        let!(:artifact) { create(:ci_job_artifact, :cobertura) }

        it { is_expected.to eq([artifact]) }
      end

      context 'when there is a jacoco report' do
        let!(:artifact) { create(:ci_job_artifact, :jacoco) }

        it { is_expected.to eq([artifact]) }
      end

      context 'when there are no coverage reports' do
        let!(:artifact) { create(:ci_job_artifact, :archive) }

        it { is_expected.to be_empty }
      end
    end

    describe 'codequality_reports' do
      let(:report_type) { :codequality }

      context 'when there is a codequality report' do
        let!(:artifact) { create(:ci_job_artifact, :codequality) }

        it { is_expected.to eq([artifact]) }
      end

      context 'when there are no codequality reports' do
        let!(:artifact) { create(:ci_job_artifact, :archive) }

        it { is_expected.to be_empty }
      end
    end

    describe 'terraform_reports' do
      let(:report_type) { :terraform }

      context 'when there is a terraform report' do
        let!(:artifact) { create(:ci_job_artifact, :terraform) }

        it { is_expected.to eq([artifact]) }
      end

      context 'when there are no terraform reports' do
        let!(:artifact) { create(:ci_job_artifact, :archive) }

        it { is_expected.to be_empty }
      end
    end
  end

  describe 'artifacts_public?' do
    subject { artifact.public_access? }

    context 'when job artifact created by default' do
      let!(:artifact) { create(:ci_job_artifact) }

      it { is_expected.to be_truthy }
    end

    context 'when job artifact created as public' do
      let!(:artifact) { create(:ci_job_artifact, :public) }

      it { is_expected.to be_truthy }
    end

    context 'when job artifact created as private' do
      let!(:artifact) { build(:ci_job_artifact, :private) }

      it { is_expected.to be_falsey }
    end
  end

  describe 'none_access?' do
    subject { artifact.none_access? }

    context 'when job artifact created by default' do
      let!(:artifact) { create(:ci_job_artifact) }

      it { is_expected.to be_falsey }
    end

    context 'when job artifact created as none access' do
      let!(:artifact) { create(:ci_job_artifact, :none) }

      it { is_expected.to be_truthy }
    end
  end

  describe '.file_types_for_report' do
    it 'returns the report file types for the report type' do
      expect(described_class.file_types_for_report(:test)).to match_array(%w[junit])
    end

    context 'when given an unrecognized report type' do
      it 'raises error' do
        expect { described_class.file_types_for_report(:blah) }.to raise_error(ArgumentError, "Unrecognized report type: blah")
      end
    end
  end

  describe '.associated_file_types_for' do
    using RSpec::Parameterized::TableSyntax

    subject { described_class.associated_file_types_for(file_type) }

    where(:file_type, :result) do
      'codequality' | %w[codequality]
      'quality' | nil
    end

    with_them do
      it { is_expected.to eq result }
    end
  end

  describe '.erasable_file_types' do
    subject { described_class.erasable_file_types }

    it 'returns a list of erasable file types' do
      all_types = described_class.file_types.keys
      erasable_types = all_types - Enums::Ci::JobArtifact.non_erasable_file_types

      expect(subject).to contain_exactly(*erasable_types)
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

  describe '.non_trace' do
    subject { described_class.non_trace }

    context 'when there is only a trace job artifact' do
      let!(:trace) { create(:ci_job_artifact, :trace) }

      it { is_expected.to be_empty }
    end

    context 'when there is only a non-trace job artifact' do
      let!(:junit) { create(:ci_job_artifact, :junit) }

      it { is_expected.to eq([junit]) }
    end

    context 'when there are both trace and non-trace job artifacts' do
      let!(:trace) { create(:ci_job_artifact, :trace) }
      let!(:junit) { create(:ci_job_artifact, :junit) }

      it { is_expected.to eq([junit]) }
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
        let!(:artifact) {}

        it { is_expected.to be_falsy }
      end
    end

    context 'when the specified job_id does not exist' do
      let(:job_id) { 10000 }

      it { is_expected.to be_falsy }
    end
  end

  describe '#stored?' do
    subject { artifact.stored? }

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

  describe '.order_expired_asc' do
    let_it_be(:first_artifact) { create(:ci_job_artifact, expire_at: 2.days.ago) }
    let_it_be(:second_artifact) { create(:ci_job_artifact, expire_at: 1.day.ago) }

    it 'returns ordered artifacts' do
      expect(described_class.order_expired_asc).to eq([first_artifact, second_artifact])
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

  describe '.created_at_before' do
    it 'returns artifacts' do
      artifact1 = create(:ci_job_artifact, created_at: 1.day.ago)
      _artifact2 = create(:ci_job_artifact, created_at: 1.day.from_now)

      expect(described_class.created_at_before(Time.current)).to match_array([artifact1])
    end
  end

  describe '.id_before' do
    it 'returns artifacts' do
      artifact1 = create(:ci_job_artifact)
      artifact2 = create(:ci_job_artifact)

      expect(described_class.id_before(artifact2.id)).to match_array([artifact1, artifact2])
    end
  end

  describe '.id_after' do
    it 'returns artifacts' do
      artifact1 = create(:ci_job_artifact)
      artifact2 = create(:ci_job_artifact)

      expect(described_class.id_after(artifact1.id)).to match_array([artifact2])
    end
  end

  describe '.ordered_by_id' do
    it 'returns artifacts in asc order' do
      artifact1 = create(:ci_job_artifact)
      artifact2 = create(:ci_job_artifact)

      expect(described_class.ordered_by_id).to eq([artifact1, artifact2])
    end
  end

  context 'creating the artifact' do
    let(:project) { create(:project) }
    let(:artifact) { create(:ci_job_artifact, :archive, project: project) }

    it 'sets the size from the file size' do
      expect(artifact.size).to eq(ci_artifact_fixture_size)
    end
  end

  context 'updating the artifact file' do
    it 'updates the artifact size' do
      artifact.update!(file: fixture_file_upload('spec/fixtures/dk.png'))
      expect(artifact.size).to eq(1062)
    end
  end

  context 'when updating any field except the file' do
    let(:artifact) { create(:ci_job_artifact, :unarchived_trace_artifact, file_store: 2) }

    before do
      stub_artifacts_object_storage(direct_upload: true)
      artifact.file.object_store = 1
    end

    it 'the `after_commit` hook does not update `file_store`' do
      artifact.update!(expire_at: Time.current)

      expect(artifact.file_store).to be(2)
    end
  end

  describe 'validates file format' do
    subject { artifact }

    Enums::Ci::JobArtifact.type_and_format_pairs.except(:trace).each do |file_type, file_format|
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
          context "with #{other_format}" do
            let(:artifact) { build(:ci_job_artifact, file_type: file_type, file_format: other_format) }

            it { is_expected.not_to be_valid }
          end
        end
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

  describe '#store_after_commit?' do
    let(:file_type) { :archive }
    let(:artifact) { build(:ci_job_artifact, file_type) }

    context 'when direct upload is enabled' do
      before do
        stub_artifacts_object_storage(direct_upload: true)
      end

      context 'when the artifact is a trace' do
        let(:file_type) { :trace }

        it 'returns true' do
          expect(artifact.store_after_commit?).to be_truthy
        end
      end

      context 'when the artifact is not a trace' do
        it 'returns false' do
          expect(artifact.store_after_commit?).to be_falsey
        end
      end
    end

    context 'when direct upload is disabled' do
      before do
        stub_artifacts_object_storage(direct_upload: false)
      end

      it 'returns false' do
        expect(artifact.store_after_commit?).to be_falsey
      end
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
        expect(ProjectStatistics).to receive(:bulk_increment_statistic).once
          .with(project, :build_artifacts_size, [have_attributes(amount: -job_artifact.file.size)])

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

  context 'loose foreign key on ci_job_artifacts.project_id' do
    it_behaves_like 'cleanup by a loose foreign key' do
      let!(:parent) { create(:project) }
      let!(:model) { create(:ci_job_artifact, project: parent) }
    end
  end

  describe 'partitioning' do
    let(:job) { build(:ci_build, partition_id: 123) }
    let(:artifact) { build(:ci_job_artifact, job: job, partition_id: nil) }

    it 'copies the partition_id from job' do
      expect { artifact.valid? }.to change(artifact, :partition_id).from(nil).to(123)
    end

    context 'when the job is missing' do
      let(:artifact) do
        build(:ci_job_artifact,
          project: build_stubbed(:project),
          job: nil,
          partition_id: nil)
      end

      it 'does not change the partition_id value' do
        expect { artifact.valid? }.not_to change(artifact, :partition_id)
      end
    end
  end

  describe '#filename' do
    subject { artifact.filename }

    it { is_expected.to eq(artifact.file.filename) }
  end

  describe '#to_deleted_object_attrs' do
    let(:pick_up_at) { nil }
    let(:expire_at) { nil }
    let(:file_final_path) { nil }

    let(:artifact) do
      create(
        :ci_job_artifact,
        :archive,
        :remote_store,
        file_final_path: file_final_path,
        expire_at: expire_at
      )
    end

    subject(:attributes) { artifact.to_deleted_object_attrs(pick_up_at) }

    before do
      stub_artifacts_object_storage
    end

    shared_examples_for 'returning attributes for object deletion' do
      it 'returns the file store' do
        expect(attributes[:file_store]).to eq(artifact.file_store)
      end

      it 'returns the project_id' do
        expect(attributes[:project_id]).to eq(artifact.project_id)
      end

      context 'when pick_up_at is present' do
        let(:pick_up_at) { 2.hours.ago }

        it 'returns the pick_up_at value' do
          expect(attributes[:pick_up_at]).to eq(pick_up_at)
        end
      end

      context 'when pick_up_at is not present' do
        context 'and expire_at is present' do
          let(:expire_at) { 4.hours.ago }

          it 'sets expire_at as pick_up_at' do
            expect(attributes[:pick_up_at]).to eq(expire_at)
          end
        end

        context 'and expire_at is not present' do
          it 'sets current time as pick_up_at' do
            freeze_time do
              expect(attributes[:pick_up_at]).to eq(Time.current)
            end
          end
        end

        context 'when expire_at is far away in the future' do
          let(:expire_at) { 1.year.from_now }

          it 'sets pick_up_at to 1 hour in the future' do
            freeze_time do
              expect(attributes[:pick_up_at]).to eq(1.hour.from_now)
            end
          end
        end
      end
    end

    context 'when file_final_path is present' do
      let(:file_final_path) { 'some/hash/path/to/randomfile' }

      it 'returns the store_dir and file based on the file_final_path' do
        expect(attributes).to include(
          store_dir: 'some/hash/path/to',
          file: 'randomfile'
        )
      end

      it_behaves_like 'returning attributes for object deletion'
    end

    context 'when file_final_path is not present' do
      it 'returns the uploader default store_dir and file_identifier' do
        expect(attributes).to include(
          store_dir: artifact.file.store_dir.to_s,
          file: artifact.file_identifier
        )
      end

      it_behaves_like 'returning attributes for object deletion'
    end
  end

  describe '#each_blob' do
    let(:job_artifact) { create(:ci_job_artifact, :junit) }

    it 'creates a report artifact for junit reports' do
      expect { job_artifact.each_blob { |b| } }.to change { Ci::JobArtifactReport.count }.by(1)
      expect(job_artifact.artifact_report.status).to eq("validated")
    end

    context 'when job artifact is not junit' do
      let(:job_artifact) { create(:ci_job_artifact, :codequality) }

      it 'does not create an artifact report' do
        expect { job_artifact.each_blob { |b| } }.not_to change { Ci::JobArtifactReport.count }
      end
    end

    context 'when parsing the junit fails from size error' do
      before do
        allow_next_instance_of(Gitlab::Ci::Artifacts::DecompressedArtifactSizeValidator) do |instance|
          allow(instance).to receive(:validate!)
            .and_raise(Gitlab::Ci::Artifacts::DecompressedArtifactSizeValidator::FileDecompressionError)
        end
      end

      it 'updates the artifact report to failed state' do
        expect { job_artifact.each_blob { |b| } }
          .to raise_error(Gitlab::Ci::Artifacts::DecompressedArtifactSizeValidator::FileDecompressionError)
        expect(job_artifact.artifact_report.status).to eq("faulty")
      end
    end

    context 'when the job artifact is not saved' do
      let(:job_artifact) { build(:ci_job_artifact, :junit) }

      it 'creates a report artifact for junit reports and saves when job artifact saves' do
        job_artifact.each_blob { |b| }
        expect { job_artifact.save! }.to change { Ci::JobArtifactReport.count }.by(1)
        expect(job_artifact.artifact_report.status).to eq("validated")
      end

      context 'and parsing the junit fails from size error' do
        before do
          allow_next_instance_of(Gitlab::Ci::Artifacts::DecompressedArtifactSizeValidator) do |instance|
            allow(instance).to receive(:validate!)
              .and_raise(Gitlab::Ci::Artifacts::DecompressedArtifactSizeValidator::FileDecompressionError)
          end
        end

        it 'updates the artifact report to failed state and saves when job artifact saves' do
          expect { job_artifact.each_blob { |b| } }.to raise_error(StandardError)
          expect { job_artifact.save! }.to change { Ci::JobArtifactReport.count }.by(1)
          expect(job_artifact.artifact_report.status).to eq("faulty")
        end
      end

      context 'and parsing the junit fails from unknown error' do
        before do
          allow_next_instance_of(Gitlab::Ci::Artifacts::DecompressedArtifactSizeValidator) do |instance|
            allow(instance).to receive(:validate!).and_raise(StandardError)
          end
        end

        it 'updates the artifact report to validated and saves when job artifact saves' do
          expect { job_artifact.each_blob { |b| } }.to raise_error(StandardError)
          expect { job_artifact.save! }.to change { Ci::JobArtifactReport.count }.by(1)
          expect(job_artifact.artifact_report.status).to eq("validated")
        end
      end
    end
  end
end
