# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::Pipeline, :mailer, factory_default: :keep do
  include ProjectForksHelper
  include StubRequests
  include Ci::SourcePipelineHelpers

  let_it_be(:user) { create(:user) }
  let_it_be(:namespace) { create_default(:namespace).freeze }
  let_it_be(:project) { create_default(:project, :repository).freeze }

  it 'paginates 15 pipeleines per page' do
    expect(described_class.default_per_page).to eq(15)
  end

  it_behaves_like 'having unique enum values'

  it { is_expected.to belong_to(:project) }
  it { is_expected.to belong_to(:user) }
  it { is_expected.to belong_to(:auto_canceled_by) }
  it { is_expected.to belong_to(:pipeline_schedule) }
  it { is_expected.to belong_to(:merge_request) }
  it { is_expected.to belong_to(:external_pull_request) }

  it { is_expected.to have_many(:statuses) }
  it { is_expected.to have_many(:trigger_requests) }
  it { is_expected.to have_many(:variables) }
  it { is_expected.to have_many(:builds) }
  it { is_expected.to have_many(:bridges) }
  it { is_expected.to have_many(:job_artifacts).through(:builds) }
  it { is_expected.to have_many(:auto_canceled_pipelines) }
  it { is_expected.to have_many(:auto_canceled_jobs) }
  it { is_expected.to have_many(:sourced_pipelines) }
  it { is_expected.to have_many(:triggered_pipelines) }
  it { is_expected.to have_many(:pipeline_artifacts) }

  it { is_expected.to have_one(:chat_data) }
  it { is_expected.to have_one(:source_pipeline) }
  it { is_expected.to have_one(:triggered_by_pipeline) }
  it { is_expected.to have_one(:source_job) }
  it { is_expected.to have_one(:pipeline_config) }

  it { is_expected.to respond_to :git_author_name }
  it { is_expected.to respond_to :git_author_email }
  it { is_expected.to respond_to :git_author_full_text }
  it { is_expected.to respond_to :short_sha }
  it { is_expected.to delegate_method(:full_path).to(:project).with_prefix }

  describe 'validations' do
    it { is_expected.to validate_presence_of(:sha) }
    it { is_expected.to validate_presence_of(:status) }
  end

  describe 'associations' do
    let_it_be(:pipeline) { create(:ci_empty_pipeline, :created) }

    it 'has a bidirectional relationship with projects' do
      expect(described_class.reflect_on_association(:project).has_inverse?).to eq(:all_pipelines)
      expect(Project.reflect_on_association(:all_pipelines).has_inverse?).to eq(:project)
      expect(Project.reflect_on_association(:ci_pipelines).has_inverse?).to eq(:project)
    end

    describe '#latest_builds' do
      it 'has a one to many relationship with its latest builds' do
        _old_build = create(:ci_build, :retried, pipeline: pipeline)
        latest_build = create(:ci_build, :expired, pipeline: pipeline)

        expect(pipeline.latest_builds).to contain_exactly(latest_build)
      end
    end

    describe '#downloadable_artifacts' do
      let_it_be(:build) { create(:ci_build, pipeline: pipeline) }
      let_it_be(:downloadable_artifact) { create(:ci_job_artifact, :codequality, job: build) }
      let_it_be(:expired_artifact) { create(:ci_job_artifact, :junit, :expired, job: build) }
      let_it_be(:undownloadable_artifact) { create(:ci_job_artifact, :trace, job: build) }

      context 'when artifacts are locked' do
        it 'returns downloadable artifacts including locked artifacts' do
          expect(pipeline.downloadable_artifacts).to contain_exactly(downloadable_artifact, expired_artifact)
        end
      end

      context 'when artifacts are unlocked' do
        it 'returns only downloadable artifacts not expired' do
          expired_artifact.job.pipeline.unlocked!

          expect(pipeline.reload.downloadable_artifacts).to contain_exactly(downloadable_artifact)
        end
      end
    end
  end

  describe '#set_status' do
    let(:pipeline) { build(:ci_empty_pipeline, :created) }

    where(:from_status, :to_status) do
      from_status_names = described_class.state_machines[:status].states.map(&:name)
      to_status_names = from_status_names - [:created] # we never want to transition into created

      from_status_names.product(to_status_names)
    end

    with_them do
      it do
        pipeline.status = from_status.to_s

        if from_status != to_status
          expect(pipeline.set_status(to_status.to_s))
            .to eq(true)
        else
          expect(pipeline.set_status(to_status.to_s))
            .to eq(false), "loopback transitions are not allowed"
        end
      end
    end
  end

  describe '.processables' do
    let_it_be(:pipeline) { create(:ci_empty_pipeline, :created) }

    before do
      create(:ci_build, name: 'build', pipeline: pipeline)
      create(:ci_bridge, name: 'bridge', pipeline: pipeline)
      create(:commit_status, name: 'commit status', pipeline: pipeline)
      create(:generic_commit_status, name: 'generic status', pipeline: pipeline)
    end

    it 'has an association with processable CI/CD entities' do
      pipeline.processables.pluck('name').yield_self do |processables|
        expect(processables).to match_array %w[build bridge]
      end
    end

    it 'makes it possible to append a new processable' do
      pipeline.processables << build(:ci_bridge)

      pipeline.save!

      expect(pipeline.processables.reload.count).to eq 3
    end
  end

  describe '.for_iid' do
    subject { described_class.for_iid(iid) }

    let(:iid) { '1234' }
    let!(:pipeline) { create(:ci_pipeline, iid: '1234') }

    it 'returns the pipeline' do
      is_expected.to contain_exactly(pipeline)
    end
  end

  describe '.for_sha' do
    subject { described_class.for_sha(sha) }

    let(:sha) { 'abc' }

    let_it_be(:pipeline) { create(:ci_pipeline, sha: 'abc') }

    it 'returns the pipeline' do
      is_expected.to contain_exactly(pipeline)
    end

    context 'when argument is array' do
      let(:sha) { %w[abc def] }
      let!(:pipeline_2) { create(:ci_pipeline, sha: 'def') }

      it 'returns the pipelines' do
        is_expected.to contain_exactly(pipeline, pipeline_2)
      end
    end

    context 'when sha is empty' do
      let(:sha) { nil }

      it 'does not return anything' do
        is_expected.to be_empty
      end
    end
  end

  describe '.for_source_sha' do
    subject { described_class.for_source_sha(source_sha) }

    let(:source_sha) { 'abc' }

    let_it_be(:pipeline) { create(:ci_pipeline, source_sha: 'abc') }

    it 'returns the pipeline' do
      is_expected.to contain_exactly(pipeline)
    end

    context 'when argument is array' do
      let(:source_sha) { %w[abc def] }
      let!(:pipeline_2) { create(:ci_pipeline, source_sha: 'def') }

      it 'returns the pipelines' do
        is_expected.to contain_exactly(pipeline, pipeline_2)
      end
    end

    context 'when source_sha is empty' do
      let(:source_sha) { nil }

      it 'does not return anything' do
        is_expected.to be_empty
      end
    end
  end

  describe '.for_sha_or_source_sha' do
    subject { described_class.for_sha_or_source_sha(sha) }

    let(:sha) { 'abc' }

    context 'when sha is matched' do
      let!(:pipeline) { create(:ci_pipeline, sha: sha) }

      it 'returns the pipeline' do
        is_expected.to contain_exactly(pipeline)
      end
    end

    context 'when source sha is matched' do
      let!(:pipeline) { create(:ci_pipeline, source_sha: sha) }

      it 'returns the pipeline' do
        is_expected.to contain_exactly(pipeline)
      end
    end

    context 'when both sha and source sha are not matched' do
      let!(:pipeline) { create(:ci_pipeline, sha: 'bcd', source_sha: 'bcd') }

      it 'does not return anything' do
        is_expected.to be_empty
      end
    end
  end

  describe '.for_branch' do
    subject { described_class.for_branch(branch) }

    let(:branch) { 'master' }

    let_it_be(:pipeline) { create(:ci_pipeline, ref: 'master') }

    it 'returns the pipeline' do
      is_expected.to contain_exactly(pipeline)
    end

    context 'with tag pipeline' do
      let(:branch) { 'v1.0' }
      let!(:pipeline) { create(:ci_pipeline, ref: 'v1.0', tag: true) }

      it 'returns nothing' do
        is_expected.to be_empty
      end
    end
  end

  describe '.ci_sources' do
    subject { described_class.ci_sources }

    let(:push_pipeline)   { build(:ci_pipeline, source: :push) }
    let(:web_pipeline)    { build(:ci_pipeline, source: :web) }
    let(:api_pipeline)    { build(:ci_pipeline, source: :api) }
    let(:webide_pipeline) { build(:ci_pipeline, source: :webide) }
    let(:child_pipeline)  { build(:ci_pipeline, source: :parent_pipeline) }
    let(:pipelines) { [push_pipeline, web_pipeline, api_pipeline, webide_pipeline, child_pipeline] }

    it 'contains pipelines having CI only sources' do
      pipelines.map(&:save!)

      expect(subject).to contain_exactly(push_pipeline, web_pipeline, api_pipeline)
    end

    it 'filters on expected sources' do
      expect(::Enums::Ci::Pipeline.ci_sources.keys).to contain_exactly(
        *%i[unknown push web trigger schedule api external pipeline chat
            merge_request_event external_pull_request_event])
    end
  end

  describe '.ci_branch_sources' do
    subject { described_class.ci_branch_sources }

    let_it_be(:push_pipeline)   { create(:ci_pipeline, source: :push) }
    let_it_be(:web_pipeline)    { create(:ci_pipeline, source: :web) }
    let_it_be(:api_pipeline)    { create(:ci_pipeline, source: :api) }
    let_it_be(:webide_pipeline) { create(:ci_pipeline, source: :webide) }
    let_it_be(:child_pipeline)  { create(:ci_pipeline, source: :parent_pipeline) }
    let_it_be(:merge_request_pipeline) { create(:ci_pipeline, :detached_merge_request_pipeline) }

    it 'contains pipelines having CI only sources' do
      expect(subject).to contain_exactly(push_pipeline, web_pipeline, api_pipeline)
    end

    it 'filters on expected sources' do
      expect(::Enums::Ci::Pipeline.ci_branch_sources.keys).to contain_exactly(
        *%i[unknown push web trigger schedule api external pipeline chat
            external_pull_request_event])
    end
  end

  describe '.outside_pipeline_family' do
    subject(:outside_pipeline_family) { described_class.outside_pipeline_family(upstream_pipeline) }

    let(:upstream_pipeline) { create(:ci_pipeline, project: project) }
    let(:child_pipeline) { create(:ci_pipeline, project: project) }

    let!(:other_pipeline) { create(:ci_pipeline, project: project) }

    before do
      create(:ci_sources_pipeline,
             source_job: create(:ci_build, pipeline: upstream_pipeline),
             source_project: project,
             pipeline: child_pipeline,
             project: project)
    end

    it 'only returns pipelines outside pipeline family' do
      expect(outside_pipeline_family).to contain_exactly(other_pipeline)
    end
  end

  describe '.before_pipeline' do
    subject(:before_pipeline) { described_class.before_pipeline(child_pipeline) }

    let!(:older_other_pipeline) { create(:ci_pipeline, project: project) }

    let!(:upstream_pipeline) { create(:ci_pipeline, project: project) }
    let!(:child_pipeline) { create(:ci_pipeline, child_of: upstream_pipeline) }

    let!(:other_pipeline) { create(:ci_pipeline, project: project) }

    before do
      create(:ci_sources_pipeline,
             source_job: create(:ci_build, pipeline: upstream_pipeline),
             source_project: project,
             pipeline: child_pipeline,
             project: project)
    end

    it 'only returns older pipelines outside pipeline family' do
      expect(before_pipeline).to contain_exactly(older_other_pipeline)
    end
  end

  describe '#merge_request?' do
    let(:pipeline) { create(:ci_pipeline, merge_request: merge_request) }
    let(:merge_request) { create(:merge_request) }

    it 'returns true' do
      expect(pipeline).to be_merge_request
    end

    context 'when merge request is nil' do
      let(:merge_request) { nil }

      it 'returns false' do
        expect(pipeline).not_to be_merge_request
      end
    end
  end

  describe '#detached_merge_request_pipeline?' do
    subject { pipeline.detached_merge_request_pipeline? }

    let!(:pipeline) do
      create(:ci_pipeline, source: :merge_request_event, merge_request: merge_request, target_sha: target_sha)
    end

    let(:merge_request) { create(:merge_request) }
    let(:target_sha) { nil }

    it { is_expected.to be_truthy }

    context 'when target sha exists' do
      let(:target_sha) { merge_request.target_branch_sha }

      it { is_expected.to be_falsy }
    end
  end

  describe '#merged_result_pipeline?' do
    subject { pipeline.merged_result_pipeline? }

    let!(:pipeline) do
      create(:ci_pipeline, source: :merge_request_event, merge_request: merge_request, target_sha: target_sha)
    end

    let(:merge_request) { create(:merge_request) }
    let(:target_sha) { merge_request.target_branch_sha }

    it { is_expected.to be_truthy }

    context 'when target sha is empty' do
      let(:target_sha) { nil }

      it { is_expected.to be_falsy }
    end
  end

  describe '#merge_request_ref?' do
    subject { pipeline.merge_request_ref? }

    let(:pipeline) { build(:ci_empty_pipeline, :created) }

    it 'calls MergeRequest#merge_request_ref?' do
      expect(MergeRequest).to receive(:merge_request_ref?).with(pipeline.ref)

      subject
    end
  end

  describe '#merge_request_event_type' do
    subject { pipeline.merge_request_event_type }

    let(:pipeline) { merge_request.all_pipelines.last }

    context 'when pipeline is merge request pipeline' do
      let(:merge_request) { create(:merge_request, :with_merge_request_pipeline) }

      it { is_expected.to eq(:merged_result) }
    end

    context 'when pipeline is detached merge request pipeline' do
      let(:merge_request) { create(:merge_request, :with_detached_merge_request_pipeline) }

      it { is_expected.to eq(:detached) }
    end
  end

  describe '#legacy_detached_merge_request_pipeline?' do
    subject { pipeline.legacy_detached_merge_request_pipeline? }

    let_it_be(:merge_request) { create(:merge_request) }

    let(:ref) { 'feature' }
    let(:target_sha) { nil }

    let(:pipeline) do
      build(:ci_pipeline, source: :merge_request_event, merge_request: merge_request, ref: ref, target_sha: target_sha)
    end

    it { is_expected.to be_truthy }

    context 'when pipeline ref is a merge request ref' do
      let(:ref) { 'refs/merge-requests/1/head' }

      it { is_expected.to be_falsy }
    end

    context 'when target sha is set' do
      let(:target_sha) { 'target-sha' }

      it { is_expected.to be_falsy }
    end
  end

  describe '#matches_sha_or_source_sha?' do
    subject { pipeline.matches_sha_or_source_sha?(sample_sha) }

    let(:sample_sha) { Digest::SHA1.hexdigest(SecureRandom.hex) }

    context 'when sha matches' do
      let(:pipeline) { build(:ci_pipeline, sha: sample_sha) }

      it { is_expected.to be_truthy }
    end

    context 'when source_sha matches' do
      let(:pipeline) { build(:ci_pipeline, source_sha: sample_sha) }

      it { is_expected.to be_truthy }
    end

    context 'when both sha and source_sha do not matche' do
      let(:pipeline) { build(:ci_pipeline, sha: 'test', source_sha: 'test') }

      it { is_expected.to be_falsy }
    end
  end

  describe '#source_ref' do
    subject { pipeline.source_ref }

    let(:pipeline) { create(:ci_pipeline, ref: 'feature') }

    it 'returns source ref' do
      is_expected.to eq('feature')
    end

    context 'when the pipeline is a detached merge request pipeline' do
      let(:merge_request) { create(:merge_request) }

      let(:pipeline) do
        create(:ci_pipeline, source: :merge_request_event, merge_request: merge_request, ref: merge_request.ref_path)
      end

      it 'returns source ref' do
        is_expected.to eq(merge_request.source_branch)
      end
    end
  end

  describe '#source_ref_slug' do
    subject { pipeline.source_ref_slug }

    let(:pipeline) { create(:ci_pipeline, ref: 'feature') }

    it 'slugifies with the source ref' do
      expect(Gitlab::Utils).to receive(:slugify).with('feature')

      subject
    end

    context 'when the pipeline is a detached merge request pipeline' do
      let(:merge_request) { create(:merge_request) }

      let(:pipeline) do
        create(:ci_pipeline, source: :merge_request_event, merge_request: merge_request, ref: merge_request.ref_path)
      end

      it 'slugifies with the source ref of the merge request' do
        expect(Gitlab::Utils).to receive(:slugify).with(merge_request.source_branch)

        subject
      end
    end
  end

  describe '.with_reports' do
    context 'when pipeline has a test report' do
      subject { described_class.with_reports(Ci::JobArtifact.test_reports) }

      let!(:pipeline_with_report) { create(:ci_pipeline, :with_test_reports) }

      it 'selects the pipeline' do
        is_expected.to eq([pipeline_with_report])
      end
    end

    context 'when pipeline has a coverage report' do
      subject { described_class.with_reports(Ci::JobArtifact.coverage_reports) }

      let!(:pipeline_with_report) { create(:ci_pipeline, :with_coverage_reports) }

      it 'selects the pipeline' do
        is_expected.to eq([pipeline_with_report])
      end
    end

    context 'when pipeline has an accessibility report' do
      subject { described_class.with_reports(Ci::JobArtifact.accessibility_reports) }

      let(:pipeline_with_report) { create(:ci_pipeline, :with_accessibility_reports) }

      it 'selects the pipeline' do
        is_expected.to eq([pipeline_with_report])
      end
    end

    context 'when pipeline has a codequality report' do
      subject { described_class.with_reports(Ci::JobArtifact.codequality_reports) }

      let(:pipeline_with_report) { create(:ci_pipeline, :with_codequality_reports) }

      it 'selects the pipeline' do
        is_expected.to eq([pipeline_with_report])
      end
    end

    context 'when pipeline has a terraform report' do
      it 'selects the pipeline' do
        pipeline_with_report = create(:ci_pipeline, :with_terraform_reports)

        expect(described_class.with_reports(Ci::JobArtifact.terraform_reports)).to eq(
          [pipeline_with_report]
        )
      end
    end

    context 'when pipeline does not have metrics reports' do
      subject { described_class.with_reports(Ci::JobArtifact.test_reports) }

      let!(:pipeline_without_report) { create(:ci_empty_pipeline) }

      it 'does not select the pipeline' do
        is_expected.to be_empty
      end
    end
  end

  describe '.merge_request_event' do
    subject { described_class.merge_request_event }

    context 'when there is a merge request pipeline' do
      let!(:pipeline) { create(:ci_pipeline, source: :merge_request_event, merge_request: merge_request) }
      let(:merge_request) { create(:merge_request) }

      it 'returns merge request pipeline first' do
        expect(subject).to eq([pipeline])
      end
    end

    context 'when there are no merge request pipelines' do
      let!(:pipeline) { create(:ci_pipeline, source: :push) }

      it 'returns empty array' do
        expect(subject).to be_empty
      end
    end
  end

  describe 'modules' do
    it_behaves_like 'AtomicInternalId', validate_presence: false do
      let(:internal_id_attribute) { :iid }
      let(:instance) { build(:ci_pipeline) }
      let(:scope) { :project }
      let(:scope_attrs) { { project: instance.project } }
      let(:usage) { :ci_pipelines }
    end
  end

  describe '#source' do
    context 'when creating new pipeline' do
      let(:pipeline) do
        build(:ci_empty_pipeline, :created, project: project, source: nil)
      end

      it "prevents from creating an object" do
        expect(pipeline).not_to be_valid
      end
    end

    context 'when updating existing pipeline' do
      let(:pipeline) { create(:ci_empty_pipeline, :created) }

      before do
        pipeline.update_attribute(:source, nil)
      end

      it 'object is valid' do
        expect(pipeline).to be_valid
      end
    end
  end

  describe '#block' do
    let(:pipeline) { create(:ci_empty_pipeline, :created) }

    it 'changes pipeline status to manual' do
      expect(pipeline.block).to be true
      expect(pipeline.reload).to be_manual
      expect(pipeline.reload).to be_blocked
    end
  end

  describe '#delay' do
    subject { pipeline.delay }

    let(:pipeline) { build(:ci_pipeline, :created) }

    it 'changes pipeline status to schedule' do
      subject

      expect(pipeline).to be_scheduled
    end
  end

  describe '#valid_commit_sha' do
    let(:pipeline) { build_stubbed(:ci_empty_pipeline, :created, project: project) }

    context 'commit.sha can not start with 00000000' do
      before do
        pipeline.sha = '0' * 40
        pipeline.valid_commit_sha
      end

      it('commit errors should not be empty') { expect(pipeline.errors).not_to be_empty }
    end
  end

  describe '#short_sha' do
    subject { pipeline.short_sha }

    let(:pipeline) { build_stubbed(:ci_empty_pipeline, :created) }

    it 'has 8 items' do
      expect(subject.size).to eq(8)
    end
    it { expect(pipeline.sha).to start_with(subject) }
  end

  describe '#retried' do
    subject { pipeline.retried }

    let(:pipeline) { create(:ci_empty_pipeline, :created, project: project) }
    let!(:build1) { create(:ci_build, pipeline: pipeline, name: 'deploy', retried: true) }

    before do
      create(:ci_build, pipeline: pipeline, name: 'deploy')
    end

    it 'returns old builds' do
      is_expected.to contain_exactly(build1)
    end
  end

  describe '#coverage' do
    let_it_be_with_reload(:pipeline) { create(:ci_empty_pipeline) }

    context 'with multiple pipelines' do
      before_all do
        create(:ci_build, name: "rspec", coverage: 30, pipeline: pipeline)
        create(:ci_build, name: "rubocop", coverage: 40, pipeline: pipeline)
      end

      it "calculates average when there are two builds with coverage" do
        expect(pipeline.coverage).to eq("35.00")
      end

      it "calculates average when there are two builds with coverage and one with nil" do
        create(:ci_build, pipeline: pipeline)

        expect(pipeline.coverage).to eq("35.00")
      end

      it "calculates average when there are two builds with coverage and one is retried" do
        create(:ci_build, name: "rubocop", coverage: 30, pipeline: pipeline, retried: true)

        expect(pipeline.coverage).to eq("35.00")
      end
    end

    context 'when there is one build without coverage' do
      it "calculates average to nil" do
        create(:ci_build, pipeline: pipeline)

        expect(pipeline.coverage).to be_nil
      end
    end
  end

  describe '#update_builds_coverage' do
    let_it_be(:pipeline) { create(:ci_empty_pipeline) }

    context 'builds with coverage_regex defined' do
      let!(:build_1) { create(:ci_build, :success, :trace_with_coverage, trace_coverage: 60.0, pipeline: pipeline) }
      let!(:build_2) { create(:ci_build, :success, :trace_with_coverage, trace_coverage: 80.0, pipeline: pipeline) }

      it 'updates the coverage value of each build from the trace' do
        pipeline.update_builds_coverage

        expect(build_1.reload.coverage).to eq(60.0)
        expect(build_2.reload.coverage).to eq(80.0)
      end
    end

    context 'builds without coverage_regex defined' do
      let!(:build) { create(:ci_build, :success, :trace_with_coverage, coverage_regex: nil, trace_coverage: 60.0, pipeline: pipeline) }

      it 'does not update the coverage value of each build from the trace' do
        pipeline.update_builds_coverage

        expect(build.reload.coverage).to eq(nil)
      end
    end

    context 'builds with coverage values already present' do
      let!(:build) { create(:ci_build, :success, :trace_with_coverage, trace_coverage: 60.0, coverage: 10.0, pipeline: pipeline) }

      it 'does not update the coverage value of each build from the trace' do
        pipeline.update_builds_coverage

        expect(build.reload.coverage).to eq(10.0)
      end
    end
  end

  describe '#retryable?' do
    subject { pipeline.retryable? }

    let_it_be(:pipeline) { create(:ci_empty_pipeline, :created, project: project) }

    context 'no failed builds' do
      before do
        create_build('rspec', 'success')
      end

      it 'is not retryable' do
        is_expected.to be_falsey
      end

      context 'one canceled job' do
        before do
          create_build('rubocop', 'canceled')
        end

        it 'is retryable' do
          is_expected.to be_truthy
        end
      end
    end

    context 'with failed builds' do
      before do
        create_build('rspec', 'running')
        create_build('rubocop', 'failed')
      end

      it 'is retryable' do
        is_expected.to be_truthy
      end
    end

    def create_build(name, status)
      create(:ci_build, name: name, status: status, pipeline: pipeline)
    end
  end

  describe '#persisted_variables' do
    context 'when pipeline is not persisted yet' do
      subject { build(:ci_pipeline).persisted_variables }

      it 'does not contain some variables' do
        keys = subject.map { |variable| variable[:key] }

        expect(keys).not_to include 'CI_PIPELINE_ID'
      end
    end

    context 'when pipeline is persisted' do
      subject { build_stubbed(:ci_pipeline).persisted_variables }

      it 'does contains persisted variables' do
        keys = subject.map { |variable| variable[:key] }

        expect(keys).to eq %w[CI_PIPELINE_ID CI_PIPELINE_URL]
      end
    end
  end

  describe '#predefined_variables' do
    subject { pipeline.predefined_variables }

    let(:pipeline) { build(:ci_empty_pipeline, :created) }

    it 'includes all predefined variables in a valid order' do
      keys = subject.map { |variable| variable[:key] }

      expect(keys).to eq %w[
        CI_PIPELINE_IID
        CI_PIPELINE_SOURCE
        CI_PIPELINE_CREATED_AT
        CI_COMMIT_SHA
        CI_COMMIT_SHORT_SHA
        CI_COMMIT_BEFORE_SHA
        CI_COMMIT_REF_NAME
        CI_COMMIT_REF_SLUG
        CI_COMMIT_BRANCH
        CI_COMMIT_MESSAGE
        CI_COMMIT_TITLE
        CI_COMMIT_DESCRIPTION
        CI_COMMIT_REF_PROTECTED
        CI_COMMIT_TIMESTAMP
        CI_COMMIT_AUTHOR
        CI_BUILD_REF
        CI_BUILD_BEFORE_SHA
        CI_BUILD_REF_NAME
        CI_BUILD_REF_SLUG
      ]
    end

    context 'when merge request is present' do
      let_it_be(:assignees) { create_list(:user, 2) }
      let_it_be(:milestone) { create(:milestone, project: project) }
      let_it_be(:labels) { create_list(:label, 2) }

      let(:merge_request) do
        create(:merge_request, :simple,
               source_project: project,
               target_project: project,
               assignees: assignees,
               milestone: milestone,
               labels: labels)
      end

      context 'when pipeline for merge request is created' do
        let(:pipeline) do
          create(:ci_pipeline, :detached_merge_request_pipeline,
            ci_ref_presence: false,
            user: user,
            merge_request: merge_request)
        end

        before do
          project.add_developer(user)
        end

        it 'exposes merge request pipeline variables' do
          expect(subject.to_hash)
            .to include(
              'CI_MERGE_REQUEST_ID' => merge_request.id.to_s,
              'CI_MERGE_REQUEST_IID' => merge_request.iid.to_s,
              'CI_MERGE_REQUEST_REF_PATH' => merge_request.ref_path.to_s,
              'CI_MERGE_REQUEST_PROJECT_ID' => merge_request.project.id.to_s,
              'CI_MERGE_REQUEST_PROJECT_PATH' => merge_request.project.full_path,
              'CI_MERGE_REQUEST_PROJECT_URL' => merge_request.project.web_url,
              'CI_MERGE_REQUEST_TARGET_BRANCH_NAME' => merge_request.target_branch.to_s,
              'CI_MERGE_REQUEST_TARGET_BRANCH_SHA' => '',
              'CI_MERGE_REQUEST_SOURCE_PROJECT_ID' => merge_request.source_project.id.to_s,
              'CI_MERGE_REQUEST_SOURCE_PROJECT_PATH' => merge_request.source_project.full_path,
              'CI_MERGE_REQUEST_SOURCE_PROJECT_URL' => merge_request.source_project.web_url,
              'CI_MERGE_REQUEST_SOURCE_BRANCH_NAME' => merge_request.source_branch.to_s,
              'CI_MERGE_REQUEST_SOURCE_BRANCH_SHA' => '',
              'CI_MERGE_REQUEST_TITLE' => merge_request.title,
              'CI_MERGE_REQUEST_ASSIGNEES' => merge_request.assignee_username_list,
              'CI_MERGE_REQUEST_MILESTONE' => milestone.title,
              'CI_MERGE_REQUEST_LABELS' => labels.map(&:title).sort.join(','),
              'CI_MERGE_REQUEST_EVENT_TYPE' => 'detached',
              'CI_OPEN_MERGE_REQUESTS' => merge_request.to_reference(full: true))
        end

        it 'exposes diff variables' do
          expect(subject.to_hash)
            .to include(
              'CI_MERGE_REQUEST_DIFF_ID' => merge_request.merge_request_diff.id.to_s,
              'CI_MERGE_REQUEST_DIFF_BASE_SHA' => merge_request.merge_request_diff.base_commit_sha)
        end

        context 'without assignee' do
          let(:assignees) { [] }

          it 'does not expose assignee variable' do
            expect(subject.to_hash.keys).not_to include('CI_MERGE_REQUEST_ASSIGNEES')
          end
        end

        context 'without milestone' do
          let(:milestone) { nil }

          it 'does not expose milestone variable' do
            expect(subject.to_hash.keys).not_to include('CI_MERGE_REQUEST_MILESTONE')
          end
        end

        context 'without labels' do
          let(:labels) { [] }

          it 'does not expose labels variable' do
            expect(subject.to_hash.keys).not_to include('CI_MERGE_REQUEST_LABELS')
          end
        end
      end

      context 'when pipeline on branch is created' do
        let(:pipeline) do
          create(:ci_pipeline, project: project, user: user, ref: 'feature')
        end

        context 'when a merge request is created' do
          before do
            merge_request
          end

          context 'when user has access to project' do
            before do
              project.add_developer(user)
            end

            it 'merge request references are returned matching the pipeline' do
              expect(subject.to_hash).to include(
                'CI_OPEN_MERGE_REQUESTS' => merge_request.to_reference(full: true))
            end
          end

          context 'when user does not have access to project' do
            it 'CI_OPEN_MERGE_REQUESTS is not returned' do
              expect(subject.to_hash).not_to have_key('CI_OPEN_MERGE_REQUESTS')
            end
          end
        end

        context 'when no a merge request is created' do
          it 'CI_OPEN_MERGE_REQUESTS is not returned' do
            expect(subject.to_hash).not_to have_key('CI_OPEN_MERGE_REQUESTS')
          end
        end
      end

      context 'with merged results' do
        let(:pipeline) do
          create(:ci_pipeline, :merged_result_pipeline, merge_request: merge_request)
        end

        it 'exposes merge request pipeline variables' do
          expect(subject.to_hash)
            .to include(
              'CI_MERGE_REQUEST_ID' => merge_request.id.to_s,
              'CI_MERGE_REQUEST_IID' => merge_request.iid.to_s,
              'CI_MERGE_REQUEST_REF_PATH' => merge_request.ref_path.to_s,
              'CI_MERGE_REQUEST_PROJECT_ID' => merge_request.project.id.to_s,
              'CI_MERGE_REQUEST_PROJECT_PATH' => merge_request.project.full_path,
              'CI_MERGE_REQUEST_PROJECT_URL' => merge_request.project.web_url,
              'CI_MERGE_REQUEST_TARGET_BRANCH_NAME' => merge_request.target_branch.to_s,
              'CI_MERGE_REQUEST_TARGET_BRANCH_SHA' => merge_request.target_branch_sha,
              'CI_MERGE_REQUEST_SOURCE_PROJECT_ID' => merge_request.source_project.id.to_s,
              'CI_MERGE_REQUEST_SOURCE_PROJECT_PATH' => merge_request.source_project.full_path,
              'CI_MERGE_REQUEST_SOURCE_PROJECT_URL' => merge_request.source_project.web_url,
              'CI_MERGE_REQUEST_SOURCE_BRANCH_NAME' => merge_request.source_branch.to_s,
              'CI_MERGE_REQUEST_SOURCE_BRANCH_SHA' => merge_request.source_branch_sha,
              'CI_MERGE_REQUEST_TITLE' => merge_request.title,
              'CI_MERGE_REQUEST_ASSIGNEES' => merge_request.assignee_username_list,
              'CI_MERGE_REQUEST_MILESTONE' => milestone.title,
              'CI_MERGE_REQUEST_LABELS' => labels.map(&:title).sort.join(','),
              'CI_MERGE_REQUEST_EVENT_TYPE' => 'merged_result')
        end

        it 'exposes diff variables' do
          expect(subject.to_hash)
            .to include(
              'CI_MERGE_REQUEST_DIFF_ID' => merge_request.merge_request_diff.id.to_s,
              'CI_MERGE_REQUEST_DIFF_BASE_SHA' => merge_request.merge_request_diff.base_commit_sha)
        end
      end
    end

    context 'when source is external pull request' do
      let(:pipeline) do
        create(:ci_pipeline, source: :external_pull_request_event, external_pull_request: pull_request)
      end

      let(:pull_request) { create(:external_pull_request, project: project) }

      it 'exposes external pull request pipeline variables' do
        expect(subject.to_hash)
          .to include(
            'CI_EXTERNAL_PULL_REQUEST_IID' => pull_request.pull_request_iid.to_s,
            'CI_EXTERNAL_PULL_REQUEST_SOURCE_REPOSITORY' => pull_request.source_repository,
            'CI_EXTERNAL_PULL_REQUEST_TARGET_REPOSITORY' => pull_request.target_repository,
            'CI_EXTERNAL_PULL_REQUEST_SOURCE_BRANCH_SHA' => pull_request.source_sha,
            'CI_EXTERNAL_PULL_REQUEST_TARGET_BRANCH_SHA' => pull_request.target_sha,
            'CI_EXTERNAL_PULL_REQUEST_SOURCE_BRANCH_NAME' => pull_request.source_branch,
            'CI_EXTERNAL_PULL_REQUEST_TARGET_BRANCH_NAME' => pull_request.target_branch
          )
      end
    end

    describe 'variable CI_KUBERNETES_ACTIVE' do
      context 'when pipeline.has_kubernetes_active? is true' do
        before do
          allow(pipeline).to receive(:has_kubernetes_active?).and_return(true)
        end

        it "is included with value 'true'" do
          expect(subject.to_hash).to include('CI_KUBERNETES_ACTIVE' => 'true')
        end
      end

      context 'when pipeline.has_kubernetes_active? is false' do
        before do
          allow(pipeline).to receive(:has_kubernetes_active?).and_return(false)
        end

        it 'is not included' do
          expect(subject.to_hash).not_to have_key('CI_KUBERNETES_ACTIVE')
        end
      end
    end
  end

  describe '#protected_ref?' do
    let(:pipeline) { build(:ci_empty_pipeline, :created) }

    it 'delegates method to project' do
      expect(pipeline).not_to be_protected_ref
    end
  end

  describe '#legacy_trigger' do
    let(:trigger_request) { build(:ci_trigger_request) }
    let(:pipeline) { build(:ci_empty_pipeline, :created, trigger_requests: [trigger_request]) }

    it 'returns first trigger request' do
      expect(pipeline.legacy_trigger).to eq trigger_request
    end
  end

  describe '#auto_canceled?' do
    subject { pipeline.auto_canceled? }

    let(:pipeline) { build(:ci_empty_pipeline, :created) }

    context 'when it is canceled' do
      before do
        pipeline.cancel
      end

      context 'when there is auto_canceled_by' do
        before do
          pipeline.auto_canceled_by = create(:ci_empty_pipeline)
        end

        it 'is auto canceled' do
          is_expected.to be_truthy
        end
      end

      context 'when there is no auto_canceled_by' do
        it 'is not auto canceled' do
          is_expected.to be_falsey
        end
      end

      context 'when it is retried and canceled manually' do
        before do
          pipeline.enqueue
          pipeline.cancel
        end

        it 'is not auto canceled' do
          is_expected.to be_falsey
        end
      end
    end
  end

  describe 'pipeline stages' do
    let(:pipeline) { build(:ci_empty_pipeline, :created) }

    describe 'legacy stages' do
      before do
        create(:commit_status, pipeline: pipeline,
                               stage: 'build',
                               name: 'linux',
                               stage_idx: 0,
                               status: 'success')

        create(:commit_status, pipeline: pipeline,
                               stage: 'build',
                               name: 'mac',
                               stage_idx: 0,
                               status: 'failed')

        create(:commit_status, pipeline: pipeline,
                               stage: 'deploy',
                               name: 'staging',
                               stage_idx: 2,
                               status: 'running')

        create(:commit_status, pipeline: pipeline,
                               stage: 'test',
                               name: 'rspec',
                               stage_idx: 1,
                               status: 'success')
      end

      describe '#legacy_stages' do
        using RSpec::Parameterized::TableSyntax

        subject { pipeline.legacy_stages }

        context 'stages list' do
          it 'returns ordered list of stages' do
            expect(subject.map(&:name)).to eq(%w[build test deploy])
          end
        end

        context 'stages with statuses' do
          let(:statuses) do
            subject.map { |stage| [stage.name, stage.status] }
          end

          it 'returns list of stages with correct statuses' do
            expect(statuses).to eq([%w(build failed),
                                    %w(test success),
                                    %w(deploy running)])
          end

          context 'when commit status is retried' do
            let!(:old_commit_status) do
              create(:commit_status, pipeline: pipeline,
                                     stage: 'build',
                                     name: 'mac',
                                     stage_idx: 0,
                                     status: 'success')
            end

            context 'when FF ci_remove_update_retried_from_process_pipeline is disabled' do
              before do
                stub_feature_flags(ci_remove_update_retried_from_process_pipeline: false)

                Ci::ProcessPipelineService
                  .new(pipeline)
                  .execute
              end

              it 'ignores the previous state' do
                expect(statuses).to eq([%w(build success),
                                        %w(test success),
                                        %w(deploy running)])
              end
            end
          end
        end

        context 'when there is a stage with warnings' do
          before do
            create(:commit_status, pipeline: pipeline,
                                  stage: 'deploy',
                                  name: 'prod:2',
                                  stage_idx: 2,
                                  status: 'failed',
                                  allow_failure: true)
          end

          it 'populates stage with correct number of warnings' do
            deploy_stage = pipeline.legacy_stages.third

            expect(deploy_stage).not_to receive(:statuses)
            expect(deploy_stage).to have_warnings
          end
        end
      end

      describe '#stages_count' do
        it 'returns a valid number of stages' do
          expect(pipeline.stages_count).to eq(3)
        end
      end

      describe '#stages_names' do
        it 'returns a valid names of stages' do
          expect(pipeline.stages_names).to eq(%w(build test deploy))
        end
      end
    end

    describe '#legacy_stage' do
      subject { pipeline.legacy_stage('test') }

      let(:pipeline) { build(:ci_empty_pipeline, :created) }

      context 'with status in stage' do
        before do
          create(:commit_status, pipeline: pipeline, stage: 'test')
        end

        it { expect(subject).to be_a Ci::LegacyStage }
        it { expect(subject.name).to eq 'test' }
        it { expect(subject.statuses).not_to be_empty }
      end

      context 'without status in stage' do
        before do
          create(:commit_status, pipeline: pipeline, stage: 'build')
        end

        it 'return stage object' do
          is_expected.to be_nil
        end
      end
    end

    describe '#stages' do
      let(:pipeline) { build(:ci_empty_pipeline, :created) }

      before do
        create(:ci_stage_entity, project: project,
                                 pipeline: pipeline,
                                 position: 4,
                                 name: 'deploy')

        create(:ci_build, project: project,
                          pipeline: pipeline,
                          stage: 'test',
                          stage_idx: 3,
                          name: 'test')

        create(:ci_build, project: project,
                          pipeline: pipeline,
                          stage: 'build',
                          stage_idx: 2,
                          name: 'build')

        create(:ci_stage_entity, project: project,
                                 pipeline: pipeline,
                                 position: 1,
                                 name: 'sanity')

        create(:ci_stage_entity, project: project,
                                 pipeline: pipeline,
                                 position: 5,
                                 name: 'cleanup')
      end

      subject { pipeline.stages }

      context 'when pipelines is not complete' do
        it 'returns stages in valid order' do
          expect(subject).to all(be_a Ci::Stage)
          expect(subject.map(&:name))
            .to eq %w[sanity build test deploy cleanup]
        end
      end

      context 'when pipeline is complete' do
        before do
          pipeline.succeed!
        end

        it 'returns stages in valid order' do
          expect(subject).to all(be_a Ci::Stage)
          expect(subject.map(&:name))
            .to eq %w[sanity build test deploy cleanup]
        end
      end
    end
  end

  describe 'state machine' do
    let_it_be_with_reload(:pipeline) { create(:ci_empty_pipeline, :created) }

    let(:current) { Time.current.change(usec: 0) }
    let(:build) { create_build('build1', queued_at: 0) }
    let(:build_b) { create_build('build2', queued_at: 0) }
    let(:build_c) { create_build('build3', queued_at: 0) }

    %w[succeed! drop! cancel! skip!].each do |action|
      context "when the pipeline recieved #{action} event" do
        it 'deletes a persistent ref' do
          expect(pipeline.persistent_ref).to receive(:delete).once

          pipeline.public_send(action)
        end
      end
    end

    describe 'synching status to Jira' do
      let(:worker) { ::JiraConnect::SyncBuildsWorker }

      %i[prepare! run! skip! drop! succeed! cancel! block! delay!].each do |event|
        context "when we call pipeline.#{event}" do
          it 'triggers a Jira synch worker' do
            expect(worker).to receive(:perform_async).with(pipeline.id, Integer)

            pipeline.send(event)
          end
        end
      end
    end

    describe '#duration', :sidekiq_inline do
      context 'when multiple builds are finished' do
        before do
          travel_to(current + 30) do
            build.run!
            build.reload.success!
            build_b.run!
            build_c.run!
          end

          travel_to(current + 40) do
            build_b.reload.drop!
          end

          travel_to(current + 70) do
            build_c.reload.success!
          end
        end

        it 'matches sum of builds duration' do
          pipeline.reload

          expect(pipeline.duration).to eq(40)
        end
      end

      context 'when pipeline becomes blocked' do
        let!(:build) { create_build('build:1') }
        let!(:action) { create_build('manual:action', :manual) }

        before do
          travel_to(current + 1.minute) do
            build.run!
          end

          travel_to(current + 5.minutes) do
            build.reload.success!
          end
        end

        it 'recalculates pipeline duration' do
          pipeline.reload

          expect(pipeline).to be_manual
          expect(pipeline.duration).to eq 4.minutes
        end
      end
    end

    describe '#started_at' do
      let(:pipeline) { create(:ci_empty_pipeline, status: from_status) }

      %i[created preparing pending].each do |status|
        context "from #{status}" do
          let(:from_status) { status }

          it 'updates on transitioning to running' do
            pipeline.run

            expect(pipeline.started_at).not_to be_nil
          end
        end
      end

      context 'from created' do
        let(:from_status) { :created }

        it 'does not update on transitioning to success' do
          pipeline.succeed

          expect(pipeline.started_at).to be_nil
        end
      end
    end

    describe '#finished_at' do
      it 'updates on transitioning to success', :sidekiq_might_not_need_inline do
        build.success

        expect(pipeline.reload.finished_at).not_to be_nil
      end

      it 'does not update on transitioning to running' do
        build.run

        expect(pipeline.reload.finished_at).to be_nil
      end
    end

    describe 'merge request metrics' do
      let(:pipeline) { create(:ci_empty_pipeline, status: from_status) }

      before do
        expect(PipelineMetricsWorker).to receive(:perform_async).with(pipeline.id)
      end

      context 'when transitioning to running' do
        %i[created preparing pending].each do |status|
          context "from #{status}" do
            let(:from_status) { status }

            it 'schedules metrics workers' do
              pipeline.run
            end
          end
        end
      end

      context 'when transitioning to success' do
        let(:from_status) { 'created' }

        it 'schedules metrics workers' do
          pipeline.succeed
        end
      end
    end

    describe 'merge on success' do
      let(:pipeline) { create(:ci_empty_pipeline, status: from_status) }

      %i[created preparing pending running].each do |status|
        context "from #{status}" do
          let(:from_status) { status }

          it 'schedules daily build group report results worker' do
            expect(Ci::DailyBuildGroupReportResultsWorker).to receive(:perform_in).with(10.minutes, pipeline.id)

            pipeline.succeed
          end
        end
      end
    end

    describe 'pipeline caching' do
      it 'performs ExpirePipelinesCacheWorker' do
        expect(ExpirePipelineCacheWorker).to receive(:perform_async).with(pipeline.id)

        pipeline.cancel
      end
    end

    describe '#dangling?' do
      it 'returns true if pipeline comes from any dangling sources' do
        pipeline.source = Enums::Ci::Pipeline.dangling_sources.each_key.first

        expect(pipeline).to be_dangling
      end

      it 'returns true if pipeline comes from any CI sources' do
        pipeline.source = Enums::Ci::Pipeline.ci_sources.each_key.first

        expect(pipeline).not_to be_dangling
      end
    end

    describe 'auto merge' do
      context 'when auto merge is enabled' do
        let_it_be_with_reload(:merge_request) { create(:merge_request, :merge_when_pipeline_succeeds) }
        let_it_be_with_reload(:pipeline) do
          create(:ci_pipeline, :running, project: merge_request.source_project,
                                        ref: merge_request.source_branch,
                                        sha: merge_request.diff_head_sha)
        end

        before_all do
          merge_request.update_head_pipeline
        end

        %w[succeed! drop! cancel! skip!].each do |action|
          context "when the pipeline recieved #{action} event" do
            it 'performs AutoMergeProcessWorker' do
              expect(AutoMergeProcessWorker).to receive(:perform_async).with(merge_request.id)

              pipeline.public_send(action)
            end
          end
        end
      end

      context 'when auto merge is not enabled in the merge request' do
        let(:merge_request) { create(:merge_request) }

        it 'performs AutoMergeProcessWorker' do
          expect(AutoMergeProcessWorker).not_to receive(:perform_async)

          pipeline.succeed!
        end
      end
    end

    describe 'auto devops pipeline metrics' do
      using RSpec::Parameterized::TableSyntax

      let(:pipeline) { create(:ci_empty_pipeline, config_source: config_source) }
      let(:config_source) { :auto_devops_source }

      where(:action, :status) do
        :succeed | 'success'
        :drop    | 'failed'
        :skip    | 'skipped'
        :cancel  | 'canceled'
      end

      with_them do
        context "when pipeline receives action '#{params[:action]}'" do
          subject { pipeline.public_send(action) }

          it { expect { subject }.to change { auto_devops_pipelines_completed_total(status) }.by(1) }

          context 'when not auto_devops_source?' do
            let(:config_source) { :repository_source }

            it { expect { subject }.not_to change { auto_devops_pipelines_completed_total(status) } }
          end
        end
      end

      def auto_devops_pipelines_completed_total(status)
        Gitlab::Metrics.counter(:auto_devops_pipelines_completed_total, 'Number of completed auto devops pipelines').get(status: status)
      end
    end

    describe 'bridge triggered pipeline' do
      shared_examples 'upstream downstream pipeline' do
        let!(:source_pipeline) { create(:ci_sources_pipeline, pipeline: downstream_pipeline, source_job: bridge) }
        let!(:job) { downstream_pipeline.builds.first }

        context 'when source bridge is dependent on pipeline status' do
          let!(:bridge) { create(:ci_bridge, :strategy_depend, pipeline: upstream_pipeline) }

          it 'schedules the pipeline bridge worker' do
            expect(::Ci::PipelineBridgeStatusWorker).to receive(:perform_async).with(downstream_pipeline.id)

            downstream_pipeline.succeed!
          end

          context 'when the downstream pipeline first fails then retries and succeeds' do
            it 'makes the upstream pipeline successful' do
              Sidekiq::Testing.inline! { job.drop! }

              expect(downstream_pipeline.reload).to be_failed
              expect(upstream_pipeline.reload).to be_failed

              Sidekiq::Testing.inline! do
                new_job = Ci::Build.retry(job, project.users.first)

                expect(downstream_pipeline.reload).to be_running
                expect(upstream_pipeline.reload).to be_running

                new_job.success!
              end

              expect(downstream_pipeline.reload).to be_success
              expect(upstream_pipeline.reload).to be_success
            end
          end

          context 'when the downstream pipeline first succeeds then retries and fails' do
            it 'makes the upstream pipeline failed' do
              Sidekiq::Testing.inline! { job.success! }

              expect(downstream_pipeline.reload).to be_success
              expect(upstream_pipeline.reload).to be_success

              Sidekiq::Testing.inline! do
                new_job = Ci::Build.retry(job, project.users.first)

                expect(downstream_pipeline.reload).to be_running
                expect(upstream_pipeline.reload).to be_running

                new_job.drop!
              end

              expect(downstream_pipeline.reload).to be_failed
              expect(upstream_pipeline.reload).to be_failed
            end
          end

          context 'when the upstream pipeline has another dependent upstream pipeline' do
            let!(:upstream_of_upstream_pipeline) { create(:ci_pipeline) }

            before do
              upstream_bridge = create(:ci_bridge, :strategy_depend, pipeline: upstream_of_upstream_pipeline)
              create(:ci_sources_pipeline, pipeline: upstream_pipeline,
                                           source_job: upstream_bridge)
            end

            context 'when the downstream pipeline first fails then retries and succeeds' do
              it 'makes upstream pipelines successful' do
                Sidekiq::Testing.inline! { job.drop! }

                expect(downstream_pipeline.reload).to be_failed
                expect(upstream_pipeline.reload).to be_failed
                expect(upstream_of_upstream_pipeline.reload).to be_failed

                Sidekiq::Testing.inline! do
                  new_job = Ci::Build.retry(job, project.users.first)

                  expect(downstream_pipeline.reload).to be_running
                  expect(upstream_pipeline.reload).to be_running
                  expect(upstream_of_upstream_pipeline.reload).to be_running

                  new_job.success!
                end

                expect(downstream_pipeline.reload).to be_success
                expect(upstream_pipeline.reload).to be_success
                expect(upstream_of_upstream_pipeline.reload).to be_success
              end
            end
          end
        end

        context 'when source bridge is not dependent on pipeline status' do
          let!(:bridge) { create(:ci_bridge, pipeline: upstream_pipeline) }

          it 'does not schedule the pipeline bridge worker' do
            expect(::Ci::PipelineBridgeStatusWorker).not_to receive(:perform_async)

            downstream_pipeline.succeed!
          end
        end
      end

      context 'multi-project pipelines' do
        let!(:downstream_project) { create(:project, :repository) }
        let!(:upstream_pipeline) { create(:ci_pipeline) }
        let!(:downstream_pipeline) { create(:ci_pipeline, :with_job, project: downstream_project) }

        it_behaves_like 'upstream downstream pipeline'
      end

      context 'parent-child pipelines' do
        let!(:upstream_pipeline) { create(:ci_pipeline) }
        let!(:downstream_pipeline) { create(:ci_pipeline, :with_job) }

        it_behaves_like 'upstream downstream pipeline'
      end
    end

    def create_build(name, *traits, queued_at: current, started_from: 0, **opts)
      create(:ci_build, *traits,
             name: name,
             pipeline: pipeline,
             queued_at: queued_at,
             started_at: queued_at + started_from,
             **opts)
    end
  end

  describe '#branch?' do
    subject { pipeline.branch? }

    let(:pipeline) { build(:ci_empty_pipeline, :created) }

    context 'when ref is not a tag' do
      before do
        pipeline.tag = false
      end

      it 'return true' do
        is_expected.to be_truthy
      end

      context 'when pipeline is merge request' do
        let(:pipeline) { build(:ci_pipeline, merge_request: merge_request) }

        let(:merge_request) do
          create(:merge_request, :simple,
                 source_project: project,
                 target_project: project)
        end

        it 'returns false' do
          is_expected.to be_falsey
        end
      end
    end

    context 'when ref is a tag' do
      before do
        pipeline.tag = true
      end

      it 'return false' do
        is_expected.to be_falsey
      end
    end
  end

  describe '#git_ref' do
    subject { pipeline.send(:git_ref) }

    context 'when ref is branch' do
      let(:pipeline) { create(:ci_pipeline, tag: false) }

      it 'returns branch ref' do
        is_expected.to eq(Gitlab::Git::BRANCH_REF_PREFIX + pipeline.ref.to_s)
      end
    end

    context 'when ref is tag' do
      let(:pipeline) { create(:ci_pipeline, tag: true) }

      it 'returns branch ref' do
        is_expected.to eq(Gitlab::Git::TAG_REF_PREFIX + pipeline.ref.to_s)
      end
    end

    context 'when ref is merge request' do
      let(:pipeline) do
        create(:ci_pipeline,
               source: :merge_request_event,
               merge_request: merge_request)
      end

      let(:merge_request) do
        create(:merge_request,
               source_project: project,
               source_branch: 'feature',
               target_project: project,
               target_branch: 'master')
      end

      it 'returns branch ref' do
        is_expected.to eq(Gitlab::Git::BRANCH_REF_PREFIX + pipeline.ref.to_s)
      end
    end
  end

  describe 'ref_exists?' do
    context 'when repository exists' do
      using RSpec::Parameterized::TableSyntax

      let_it_be(:pipeline, refind: true) { create(:ci_empty_pipeline) }

      where(:tag, :ref, :result) do
        false | 'master'              | true
        false | 'non-existent-branch' | false
        true  | 'v1.1.0'              | true
        true  | 'non-existent-tag'    | false
      end

      with_them do
        before do
          pipeline.update!(tag: tag, ref: ref)
        end

        it "correctly detects ref" do
          expect(pipeline.ref_exists?).to be result
        end
      end
    end

    context 'when repository does not exist' do
      let(:pipeline) { build(:ci_empty_pipeline, ref: 'master', project: build(:project)) }

      it 'always returns false' do
        expect(pipeline.ref_exists?).to eq false
      end
    end
  end

  context 'with non-empty project' do
    let(:pipeline) do
      create(:ci_pipeline,
             ref: project.default_branch,
             sha: project.commit.sha)
    end

    describe '#lazy_ref_commit' do
      let(:another) do
        create(:ci_pipeline,
               ref: 'feature',
               sha: project.commit('feature').sha)
      end

      let(:unicode) do
        create(:ci_pipeline,
               ref: 'ü/unicode/multi-byte')
      end

      it 'returns the latest commit for a ref lazily' do
        expect(project.repository)
          .to receive(:list_commits_by_ref_name).once
          .and_call_original

        pipeline.lazy_ref_commit
        another.lazy_ref_commit
        unicode.lazy_ref_commit

        expect(pipeline.lazy_ref_commit.id).to eq pipeline.sha
        expect(another.lazy_ref_commit.id).to eq another.sha
        expect(unicode.lazy_ref_commit).to be_nil
      end
    end

    describe '#latest?' do
      context 'with latest sha' do
        it 'returns true' do
          expect(pipeline).to be_latest
        end
      end

      context 'with a branch name as the ref' do
        it 'looks up a commit for a branch' do
          expect(pipeline.ref).to eq 'master'
          expect(pipeline).to be_latest
        end
      end

      context 'with a tag name as a ref' do
        it 'looks up a commit for a tag' do
          expect(project.repository.branch_names).not_to include 'v1.0.0'

          pipeline.update!(sha: project.commit('v1.0.0').sha, ref: 'v1.0.0', tag: true)

          expect(pipeline).to be_tag
          expect(pipeline).to be_latest
        end
      end

      context 'with not latest sha' do
        before do
          pipeline.update!(sha: project.commit("#{project.default_branch}~1").sha)
        end

        it 'returns false' do
          expect(pipeline).not_to be_latest
        end
      end
    end
  end

  describe '#manual_actions' do
    subject { pipeline.manual_actions }

    let(:pipeline) { create(:ci_empty_pipeline, :created) }

    it 'when none defined' do
      is_expected.to be_empty
    end

    context 'when action defined' do
      let!(:manual) { create(:ci_build, :manual, pipeline: pipeline, name: 'deploy') }

      it 'returns one action' do
        is_expected.to contain_exactly(manual)
      end

      context 'there are multiple of the same name' do
        let!(:manual2) { create(:ci_build, :manual, pipeline: pipeline, name: 'deploy') }

        before do
          manual.update!(retried: true)
        end

        it 'returns latest one' do
          is_expected.to contain_exactly(manual2)
        end
      end
    end
  end

  describe '#branch_updated?' do
    let(:pipeline) { create(:ci_empty_pipeline, :created) }

    context 'when pipeline has before SHA' do
      before do
        pipeline.update!(before_sha: 'a1b2c3d4')
      end

      it 'runs on a branch update push' do
        expect(pipeline.before_sha).not_to be Gitlab::Git::BLANK_SHA
        expect(pipeline.branch_updated?).to be true
      end
    end

    context 'when pipeline does not have before SHA' do
      before do
        pipeline.update!(before_sha: Gitlab::Git::BLANK_SHA)
      end

      it 'does not run on a branch updating push' do
        expect(pipeline.branch_updated?).to be false
      end
    end
  end

  describe '#modified_paths' do
    let(:pipeline) { create(:ci_empty_pipeline, :created) }

    context 'when old and new revisions are set' do
      before do
        pipeline.update!(before_sha: '1234abcd', sha: '2345bcde')
      end

      it 'fetches stats for changes between commits' do
        expect(project.repository)
          .to receive(:diff_stats).with('1234abcd', '2345bcde')
          .and_call_original

        pipeline.modified_paths
      end
    end

    context 'when either old or new revision is missing' do
      before do
        pipeline.update!(before_sha: Gitlab::Git::BLANK_SHA)
      end

      it 'returns nil' do
        expect(pipeline.modified_paths).to be_nil
      end
    end

    context 'when source is merge request' do
      let(:pipeline) do
        create(:ci_pipeline, source: :merge_request_event, merge_request: merge_request)
      end

      let(:merge_request) do
        create(:merge_request, :simple,
               source_project: project,
               target_project: project)
      end

      it 'returns merge request modified paths' do
        expect(pipeline.modified_paths).to match(merge_request.modified_paths)
      end
    end

    context 'when source is an external pull request' do
      let(:pipeline) do
        create(:ci_pipeline, source: :external_pull_request_event, external_pull_request: external_pull_request)
      end

      let(:external_pull_request) do
        create(:external_pull_request, project: project, target_sha: '281d3a7', source_sha: '498214d')
      end

      it 'returns external pull request modified paths' do
        expect(pipeline.modified_paths).to match(external_pull_request.modified_paths)
      end

      context 'when the FF ci_modified_paths_of_external_prs is disabled' do
        before do
          stub_feature_flags(ci_modified_paths_of_external_prs: false)
        end

        it 'returns nil' do
          expect(pipeline.modified_paths).to be_nil
        end
      end
    end
  end

  describe '#all_worktree_paths' do
    let(:files) { { 'main.go' => '', 'mocks/mocks.go' => '' } }
    let(:project) { create(:project, :custom_repo, files: files) }
    let(:pipeline) { build(:ci_pipeline, project: project, sha: project.repository.head_commit.sha) }

    it 'returns all file paths cached' do
      expect(project.repository).to receive(:ls_files).with(pipeline.sha).once.and_call_original
      expect(pipeline.all_worktree_paths).to eq(files.keys)
      expect(pipeline.all_worktree_paths).to eq(files.keys)
    end
  end

  describe '#top_level_worktree_paths' do
    let(:files) { { 'main.go' => '', 'mocks/mocks.go' => '' } }
    let(:project) { create(:project, :custom_repo, files: files) }
    let(:pipeline) { build(:ci_pipeline, project: project, sha: project.repository.head_commit.sha) }

    it 'returns top-level file paths cached' do
      expect(project.repository).to receive(:tree).with(pipeline.sha).once.and_call_original
      expect(pipeline.top_level_worktree_paths).to eq(['main.go'])
      expect(pipeline.top_level_worktree_paths).to eq(['main.go'])
    end
  end

  describe '#has_kubernetes_active?' do
    let(:pipeline) { create(:ci_empty_pipeline, :created, project: project) }

    context 'when kubernetes is active' do
      context 'when user configured kubernetes from CI/CD > Clusters' do
        let!(:cluster) { create(:cluster, :project, :provided_by_gcp) }
        let(:project) { cluster.project }

        it 'returns true' do
          expect(pipeline).to have_kubernetes_active
        end
      end
    end

    context 'when kubernetes is not active' do
      it 'returns false' do
        expect(pipeline).not_to have_kubernetes_active
      end
    end
  end

  describe '#has_warnings?' do
    subject { pipeline.has_warnings? }

    let_it_be(:pipeline) { create(:ci_empty_pipeline, :created) }

    context 'build which is allowed to fail fails' do
      before do
        create :ci_build, :success, pipeline: pipeline, name: 'rspec'
        create :ci_build, :allowed_to_fail, :failed, pipeline: pipeline, name: 'rubocop'
      end

      it 'returns true' do
        is_expected.to be_truthy
      end
    end

    context 'build which is allowed to fail succeeds' do
      before do
        create :ci_build, :success, pipeline: pipeline, name: 'rspec'
        create :ci_build, :allowed_to_fail, :success, pipeline: pipeline, name: 'rubocop'
      end

      it 'returns false' do
        is_expected.to be_falsey
      end
    end

    context 'build is retried and succeeds' do
      before do
        create :ci_build, :success, pipeline: pipeline, name: 'rubocop'
        create :ci_build, :failed, pipeline: pipeline, name: 'rspec'
        create :ci_build, :success, pipeline: pipeline, name: 'rspec'
      end

      it 'returns false' do
        is_expected.to be_falsey
      end
    end

    context 'bridge which is allowed to fail fails' do
      before do
        create :ci_bridge, :allowed_to_fail, :failed, pipeline: pipeline, name: 'rubocop'
      end

      it 'returns true' do
        is_expected.to be_truthy
      end
    end

    context 'bridge which is allowed to fail is successful' do
      before do
        create :ci_bridge, :allowed_to_fail, :success, pipeline: pipeline, name: 'rubocop'
      end

      it 'returns false' do
        is_expected.to be_falsey
      end
    end
  end

  describe '#number_of_warnings' do
    let_it_be(:pipeline) { create(:ci_empty_pipeline, :created) }

    it 'returns the number of warnings' do
      create(:ci_build, :allowed_to_fail, :failed, pipeline: pipeline, name: 'rubocop')
      create(:ci_bridge, :allowed_to_fail, :failed, pipeline: pipeline, name: 'rubocop')

      expect(pipeline.number_of_warnings).to eq(2)
    end

    it 'supports eager loading of the number of warnings' do
      pipeline2 = create(:ci_empty_pipeline, :created)

      create(:ci_build, :allowed_to_fail, :failed, pipeline: pipeline, name: 'rubocop')
      create(:ci_build, :allowed_to_fail, :failed, pipeline: pipeline2, name: 'rubocop')

      pipelines = project.ci_pipelines.to_a

      pipelines.each(&:number_of_warnings)

      # To run the queries we need to actually use the lazy objects, which we do
      # by just sending "to_i" to them.
      amount = ActiveRecord::QueryRecorder
        .new { pipelines.each { |p| p.number_of_warnings.to_i } }
        .count

      expect(amount).to eq(1)
    end
  end

  describe '#needs_processing?' do
    using RSpec::Parameterized::TableSyntax

    subject { pipeline.needs_processing? }

    let_it_be(:pipeline) { create(:ci_empty_pipeline, :created) }

    where(:processed, :result) do
      nil   | true
      false | true
      true  | false
    end

    with_them do
      let(:build) do
        create(:ci_build, :success, pipeline: pipeline, name: 'rubocop')
      end

      before do
        build.update_column(:processed, processed)
      end

      it { is_expected.to eq(result) }
    end
  end

  context 'with outdated pipelines' do
    before_all do
      create_pipeline(:canceled, 'ref', 'A')
      create_pipeline(:success, 'ref', 'A')
      create_pipeline(:failed, 'ref', 'B')
      create_pipeline(:skipped, 'feature', 'C')
    end

    def create_pipeline(status, ref, sha)
      create(
        :ci_empty_pipeline,
        status: status,
        ref: ref,
        sha: sha
      )
    end

    describe '.newest_first' do
      it 'returns the pipelines from new to old' do
        expect(described_class.newest_first.pluck(:status))
          .to eq(%w[skipped failed success canceled])
      end

      it 'searches limited backlog' do
        expect(described_class.newest_first(limit: 1).pluck(:status))
          .to eq(%w[skipped])
      end
    end

    describe '.latest_status' do
      context 'when no ref is specified' do
        it 'returns the status of the latest pipeline' do
          expect(described_class.latest_status).to eq('skipped')
        end
      end

      context 'when ref is specified' do
        it 'returns the status of the latest pipeline for the given ref' do
          expect(described_class.latest_status('ref')).to eq('failed')
        end
      end
    end

    describe '.latest_successful_for_ref' do
      let!(:latest_successful_pipeline) do
        create_pipeline(:success, 'ref', 'D')
      end

      it 'returns the latest successful pipeline' do
        expect(described_class.latest_successful_for_ref('ref'))
          .to eq(latest_successful_pipeline)
      end
    end

    describe '.latest_running_for_ref' do
      let!(:latest_running_pipeline) do
        create_pipeline(:running, 'ref', 'D')
      end

      it 'returns the latest running pipeline' do
        expect(described_class.latest_running_for_ref('ref'))
          .to eq(latest_running_pipeline)
      end
    end

    describe '.latest_failed_for_ref' do
      let!(:latest_failed_pipeline) do
        create_pipeline(:failed, 'ref', 'D')
      end

      it 'returns the latest failed pipeline' do
        expect(described_class.latest_failed_for_ref('ref'))
          .to eq(latest_failed_pipeline)
      end
    end

    describe '.latest_successful_for_sha' do
      let!(:latest_successful_pipeline) do
        create_pipeline(:success, 'ref', 'awesomesha')
      end

      it 'returns the latest successful pipeline' do
        expect(described_class.latest_successful_for_sha('awesomesha'))
          .to eq(latest_successful_pipeline)
      end
    end

    describe '.latest_successful_for_refs' do
      let!(:latest_successful_pipeline1) do
        create_pipeline(:success, 'ref1', 'D')
      end

      let!(:latest_successful_pipeline2) do
        create_pipeline(:success, 'ref2', 'D')
      end

      it 'returns the latest successful pipeline for both refs' do
        refs = %w(ref1 ref2 ref3)

        expect(described_class.latest_successful_for_refs(refs)).to eq({ 'ref1' => latest_successful_pipeline1, 'ref2' => latest_successful_pipeline2 })
      end
    end
  end

  describe '.latest_pipeline_per_commit' do
    let!(:commit_123_ref_master) do
      create(
        :ci_empty_pipeline,
        status: 'success',
        ref: 'master',
        sha: '123'
      )
    end

    let!(:commit_123_ref_develop) do
      create(
        :ci_empty_pipeline,
        status: 'success',
        ref: 'develop',
        sha: '123'
      )
    end

    let!(:commit_456_ref_test) do
      create(
        :ci_empty_pipeline,
        status: 'success',
        ref: 'test',
        sha: '456'
      )
    end

    context 'without a ref' do
      it 'returns a Hash containing the latest pipeline per commit for all refs' do
        result = described_class.latest_pipeline_per_commit(%w[123 456])

        expect(result).to match(
          '123' => commit_123_ref_develop,
          '456' => commit_456_ref_test
        )
      end

      it 'only includes the latest pipeline of the given commit SHAs' do
        result = described_class.latest_pipeline_per_commit(%w[123])

        expect(result).to match(
          '123' => commit_123_ref_develop
        )
      end

      context 'when there are two pipelines for a ref and SHA' do
        let!(:commit_123_ref_master_latest) do
          create(
            :ci_empty_pipeline,
            status: 'failed',
            ref: 'master',
            sha: '123',
            project: project
          )
        end

        it 'returns the latest pipeline' do
          result = described_class.latest_pipeline_per_commit(%w[123])

          expect(result).to match(
            '123' => commit_123_ref_master_latest
          )
        end
      end
    end

    context 'with a ref' do
      it 'only includes the pipelines for the given ref' do
        result = described_class.latest_pipeline_per_commit(%w[123 456], 'master')

        expect(result).to match(
          '123' => commit_123_ref_master
        )
      end
    end

    context 'when method is scoped' do
      let!(:commit_123_ref_master_parent_pipeline) do
        create(
          :ci_pipeline,
          sha: '123',
          ref: 'master',
          project: project
        )
      end

      let!(:commit_123_ref_master_child_pipeline) do
        create(
          :ci_pipeline,
          sha: '123',
          ref: 'master',
          project: project,
          child_of: commit_123_ref_master_parent_pipeline
        )
      end

      it 'returns the latest pipeline after applying the scope' do
        result = described_class.ci_sources.latest_pipeline_per_commit(%w[123], 'master')

        expect(result).to match(
          '123' => commit_123_ref_master_parent_pipeline
        )
      end
    end
  end

  describe '.latest_successful_ids_per_project' do
    let(:projects) { create_list(:project, 2) }
    let!(:pipeline1) { create(:ci_pipeline, :success, project: projects[0]) }
    let!(:pipeline2) { create(:ci_pipeline, :success, project: projects[0]) }
    let!(:pipeline3) { create(:ci_pipeline, :failed, project: projects[0]) }
    let!(:pipeline4) { create(:ci_pipeline, :success, project: projects[1]) }

    it 'returns expected pipeline ids' do
      expect(described_class.latest_successful_ids_per_project)
        .to contain_exactly(pipeline2, pipeline4)
    end
  end

  describe '.last_finished_for_ref_id' do
    let(:branch) { project.default_branch }
    let(:ref) { project.ci_refs.take }
    let(:dangling_source) { Enums::Ci::Pipeline.sources[:ondemand_dast_scan] }
    let!(:pipeline1) { create(:ci_pipeline, :success, project: project, ref: branch) }
    let!(:pipeline2) { create(:ci_pipeline, :success, project: project, ref: branch) }
    let!(:pipeline3) { create(:ci_pipeline, :failed, project: project, ref: branch) }
    let!(:pipeline4) { create(:ci_pipeline, :success, project: project, ref: branch) }
    let!(:pipeline5) { create(:ci_pipeline, :success, project: project, ref: branch, source: dangling_source) }

    it 'returns the expected pipeline' do
      result = described_class.last_finished_for_ref_id(ref.id)
      expect(result).to eq(pipeline4)
    end
  end

  describe '.internal_sources' do
    subject { described_class.internal_sources }

    it { is_expected.to be_an(Array) }
  end

  describe '.bridgeable_statuses' do
    subject { described_class.bridgeable_statuses }

    it { is_expected.to be_an(Array) }
    it { is_expected.not_to include('created', 'waiting_for_resource', 'preparing', 'pending') }
  end

  describe '#status', :sidekiq_inline do
    subject { pipeline.reload.status }

    let_it_be(:pipeline) { create(:ci_empty_pipeline, :created) }

    let(:build) { create(:ci_build, :created, pipeline: pipeline, name: 'test') }

    context 'on waiting for resource' do
      before do
        allow(build).to receive(:with_resource_group?) { true }
        allow(Ci::ResourceGroups::AssignResourceFromResourceGroupWorker).to receive(:perform_async)

        build.enqueue
      end

      it { is_expected.to eq('waiting_for_resource') }
    end

    context 'on prepare' do
      before do
        # Prevent skipping directly to 'pending'
        allow(build).to receive(:prerequisites).and_return([double])
        allow(Ci::BuildPrepareWorker).to receive(:perform_async)

        build.enqueue
      end

      it { is_expected.to eq('preparing') }
    end

    context 'on queuing' do
      before do
        build.enqueue
      end

      it { is_expected.to eq('pending') }
    end

    context 'on run' do
      before do
        build.enqueue
        build.reload.run
      end

      it { is_expected.to eq('running') }
    end

    context 'on drop' do
      before do
        build.drop
      end

      it { is_expected.to eq('failed') }
    end

    context 'on success' do
      before do
        build.success
      end

      it { is_expected.to eq('success') }
    end

    context 'on cancel' do
      before do
        build.cancel
      end

      context 'when build is pending' do
        let(:build) do
          create(:ci_build, :pending, pipeline: pipeline)
        end

        it { is_expected.to eq('canceled') }
      end
    end

    context 'on failure and build retry' do
      before do
        stub_not_protect_default_branch

        build.drop
        project.add_developer(user)

        Ci::Build.retry(build, user)
      end

      # We are changing a state: created > failed > running
      # Instead of: created > failed > pending
      # Since the pipeline already run, so it should not be pending anymore

      it { is_expected.to eq('running') }
    end
  end

  describe '#detailed_status' do
    subject { pipeline.detailed_status(user) }

    let_it_be(:pipeline) { create(:ci_empty_pipeline, :created) }

    context 'when pipeline is created' do
      let(:pipeline) { create(:ci_pipeline, :created) }

      it 'returns detailed status for created pipeline' do
        expect(subject.text).to eq s_('CiStatusText|created')
      end
    end

    context 'when pipeline is pending' do
      let(:pipeline) { create(:ci_pipeline, status: :pending) }

      it 'returns detailed status for pending pipeline' do
        expect(subject.text).to eq s_('CiStatusText|pending')
      end
    end

    context 'when pipeline is running' do
      let(:pipeline) { create(:ci_pipeline, status: :running) }

      it 'returns detailed status for running pipeline' do
        expect(subject.text).to eq s_('CiStatus|running')
      end
    end

    context 'when pipeline is successful' do
      let(:pipeline) { create(:ci_pipeline, status: :success) }

      it 'returns detailed status for successful pipeline' do
        expect(subject.text).to eq s_('CiStatusText|passed')
      end
    end

    context 'when pipeline is failed' do
      let(:pipeline) { create(:ci_pipeline, status: :failed) }

      it 'returns detailed status for failed pipeline' do
        expect(subject.text).to eq s_('CiStatusText|failed')
      end
    end

    context 'when pipeline is canceled' do
      let(:pipeline) { create(:ci_pipeline, status: :canceled) }

      it 'returns detailed status for canceled pipeline' do
        expect(subject.text).to eq s_('CiStatusText|canceled')
      end
    end

    context 'when pipeline is skipped' do
      let(:pipeline) { create(:ci_pipeline, status: :skipped) }

      it 'returns detailed status for skipped pipeline' do
        expect(subject.text).to eq s_('CiStatusText|skipped')
      end
    end

    context 'when pipeline is blocked' do
      let(:pipeline) { create(:ci_pipeline, status: :manual) }

      it 'returns detailed status for blocked pipeline' do
        expect(subject.text).to eq s_('CiStatusText|blocked')
      end
    end

    context 'when pipeline is successful but with warnings' do
      let(:pipeline) { create(:ci_pipeline, status: :success) }

      before do
        create(:ci_build, :allowed_to_fail, :failed, pipeline: pipeline)
      end

      it 'retruns detailed status for successful pipeline with warnings' do
        expect(subject.label).to eq(s_('CiStatusLabel|passed with warnings'))
      end
    end
  end

  describe '#cancelable?' do
    let_it_be(:pipeline) { create(:ci_empty_pipeline, :created) }

    %i[created running pending].each do |status0|
      context "when there is a build #{status0}" do
        before do
          create(:ci_build, status0, pipeline: pipeline)
        end

        it 'is cancelable' do
          expect(pipeline.cancelable?).to be_truthy
        end
      end

      context "when there is an external job #{status0}" do
        before do
          create(:generic_commit_status, status0, pipeline: pipeline)
        end

        it 'is cancelable' do
          expect(pipeline.cancelable?).to be_truthy
        end
      end

      %i[success failed canceled].each do |status1|
        context "when there are generic_commit_status jobs for #{status0} and #{status1}" do
          before do
            create(:generic_commit_status, status0, pipeline: pipeline)
            create(:generic_commit_status, status1, pipeline: pipeline)
          end

          it 'is cancelable' do
            expect(pipeline.cancelable?).to be_truthy
          end
        end

        context "when there are generic_commit_status and ci_build jobs for #{status0} and #{status1}" do
          before do
            create(:generic_commit_status, status0, pipeline: pipeline)
            create(:ci_build, status1, pipeline: pipeline)
          end

          it 'is cancelable' do
            expect(pipeline.cancelable?).to be_truthy
          end
        end

        context "when there are ci_build jobs for #{status0} and #{status1}" do
          before do
            create(:ci_build, status0, pipeline: pipeline)
            create(:ci_build, status1, pipeline: pipeline)
          end

          it 'is cancelable' do
            expect(pipeline.cancelable?).to be_truthy
          end
        end
      end
    end

    %i[success failed canceled].each do |status|
      context "when there is a build #{status}" do
        before do
          create(:ci_build, status, pipeline: pipeline)
        end

        it 'is not cancelable' do
          expect(pipeline.cancelable?).to be_falsey
        end
      end

      context "when there is an external job #{status}" do
        before do
          create(:generic_commit_status, status, pipeline: pipeline)
        end

        it 'is not cancelable' do
          expect(pipeline.cancelable?).to be_falsey
        end
      end
    end

    context 'when there is a manual action present in the pipeline' do
      before do
        create(:ci_build, :manual, pipeline: pipeline)
      end

      it 'is not cancelable' do
        expect(pipeline).not_to be_cancelable
      end
    end
  end

  describe '#cancel_running' do
    subject(:latest_status) { pipeline.statuses.pluck(:status) }

    let_it_be(:pipeline) { create(:ci_empty_pipeline, :created) }

    context 'when there is a running external job and a regular job' do
      before do
        create(:ci_build, :running, pipeline: pipeline)
        create(:generic_commit_status, :running, pipeline: pipeline)

        pipeline.cancel_running
      end

      it 'cancels both jobs' do
        expect(latest_status).to contain_exactly('canceled', 'canceled')
      end
    end

    context 'when jobs are in different stages' do
      before do
        create(:ci_build, :running, stage_idx: 0, pipeline: pipeline)
        create(:ci_build, :running, stage_idx: 1, pipeline: pipeline)

        pipeline.cancel_running
      end

      it 'cancels both jobs' do
        expect(latest_status).to contain_exactly('canceled', 'canceled')
      end
    end

    context 'when there are created builds present in the pipeline' do
      before do
        create(:ci_build, :running, stage_idx: 0, pipeline: pipeline)
        create(:ci_build, :created, stage_idx: 1, pipeline: pipeline)

        pipeline.cancel_running
      end

      it 'cancels created builds' do
        expect(latest_status).to eq %w(canceled canceled)
      end
    end

    context 'preloading relations' do
      let(:pipeline1) { create(:ci_empty_pipeline, :created) }
      let(:pipeline2) { create(:ci_empty_pipeline, :created) }

      before do
        create(:ci_build, :pending, pipeline: pipeline1)
        create(:generic_commit_status, :pending, pipeline: pipeline1)

        create(:ci_build, :pending, pipeline: pipeline2)
        create(:ci_build, :pending, pipeline: pipeline2)
        create(:generic_commit_status, :pending, pipeline: pipeline2)
        create(:generic_commit_status, :pending, pipeline: pipeline2)
        create(:generic_commit_status, :pending, pipeline: pipeline2)
      end

      it 'preloads relations for each build to avoid N+1 queries' do
        control1 = ActiveRecord::QueryRecorder.new do
          pipeline1.cancel_running
        end

        control2 = ActiveRecord::QueryRecorder.new do
          pipeline2.cancel_running
        end

        extra_update_queries = 4 # transition ... => :canceled, queue pop
        extra_generic_commit_status_validation_queries = 2 # name_uniqueness_across_types

        expect(control2.count).to eq(control1.count + extra_update_queries + extra_generic_commit_status_validation_queries)
      end
    end

    context 'when the first try cannot get an exclusive lock' do
      let(:retries) { 1 }

      subject(:cancel_running) { pipeline.cancel_running(retries: retries) }

      before do
        build = create(:ci_build, :running, pipeline: pipeline)

        allow(pipeline.cancelable_statuses).to receive(:find_in_batches).and_yield([build])

        call_count = 0
        allow(build).to receive(:cancel).and_wrap_original do |original, *args|
          call_count >= retries ? raise(ActiveRecord::StaleObjectError) : original.call(*args)

          call_count += 1
        end
      end

      it 'retries again and cancels the build' do
        cancel_running

        expect(latest_status).to contain_exactly('canceled')
      end

      context 'when the retries parameter is 0' do
        let(:retries) { 0 }

        it 'raises error' do
          expect do
            cancel_running
          end.to raise_error(ActiveRecord::StaleObjectError)
        end
      end
    end
  end

  describe '#retry_failed' do
    subject(:latest_status) { pipeline.latest_statuses.pluck(:status) }

    let_it_be(:pipeline) { create(:ci_empty_pipeline, :created) }

    before do
      stub_not_protect_default_branch

      project.add_developer(user)
    end

    context 'when there is a failed build and failed external status' do
      before do
        create(:ci_build, :failed, name: 'build', pipeline: pipeline)
        create(:generic_commit_status, :failed, name: 'jenkins', pipeline: pipeline)

        pipeline.retry_failed(user)
      end

      it 'retries only build' do
        expect(latest_status).to contain_exactly('pending', 'failed')
      end
    end

    context 'when builds are in different stages' do
      before do
        create(:ci_build, :failed, name: 'build', stage_idx: 0, pipeline: pipeline)
        create(:ci_build, :failed, name: 'jenkins', stage_idx: 1, pipeline: pipeline)

        pipeline.retry_failed(user)
      end

      it 'retries both builds' do
        expect(latest_status).to contain_exactly('pending', 'created')
      end
    end

    context 'when there are canceled and failed' do
      before do
        create(:ci_build, :failed, name: 'build', stage_idx: 0, pipeline: pipeline)
        create(:ci_build, :canceled, name: 'jenkins', stage_idx: 1, pipeline: pipeline)

        pipeline.retry_failed(user)
      end

      it 'retries both builds' do
        expect(latest_status).to contain_exactly('pending', 'created')
      end
    end
  end

  describe '#execute_hooks' do
    let_it_be(:pipeline) { create(:ci_empty_pipeline, :created) }

    let!(:build_a) { create_build('a', 0) }
    let!(:build_b) { create_build('b', 0) }

    let!(:hook) do
      create(:project_hook, pipeline_events: enabled)
    end

    before do
      WebHookWorker.drain
    end

    context 'with pipeline hooks enabled' do
      let(:enabled) { true }

      before do
        stub_full_request(hook.url, method: :post)
      end

      context 'with multiple builds', :sidekiq_inline do
        context 'when build is queued' do
          before do
            build_a.reload.enqueue
            build_b.reload.enqueue
          end

          it 'receives a pending event once' do
            expect(WebMock).to have_requested_pipeline_hook('pending').once
          end

          it 'builds hook data once' do
            create(:pipelines_email_integration)

            expect(Gitlab::DataBuilder::Pipeline).to receive(:build).once.and_call_original

            pipeline.execute_hooks
          end
        end

        context 'when build is run' do
          before do
            build_a.reload.enqueue
            build_a.reload.run!
            build_b.reload.enqueue
            build_b.reload.run!
          end

          it 'receives a running event once' do
            expect(WebMock).to have_requested_pipeline_hook('running').once
          end
        end

        context 'when all builds succeed' do
          before do
            build_a.success

            # We have to reload build_b as this is in next stage and it gets triggered by PipelineProcessWorker
            build_b.reload.success
          end

          it 'receives a success event once' do
            expect(WebMock).to have_requested_pipeline_hook('success').once
          end
        end

        context 'when stage one failed' do
          let!(:build_b) { create_build('b', 1) }

          before do
            build_a.drop
          end

          it 'receives a failed event once' do
            expect(WebMock).to have_requested_pipeline_hook('failed').once
          end
        end

        def have_requested_pipeline_hook(status)
          have_requested(:post, stubbed_hostname(hook.url)).with do |req|
            json_body = Gitlab::Json.parse(req.body)
            json_body['object_attributes']['status'] == status &&
              json_body['builds'].length == 2
          end
        end
      end
    end

    context 'with pipeline hooks disabled' do
      let(:enabled) { false }

      before do
        build_a.enqueue
        build_b.enqueue
      end

      it 'did not execute pipeline_hook after touched' do
        expect(WebMock).not_to have_requested(:post, hook.url)
      end

      it 'does not build hook data' do
        expect(Gitlab::DataBuilder::Pipeline).not_to receive(:build)

        pipeline.execute_hooks
      end
    end

    def create_build(name, stage_idx)
      create(:ci_build,
             :created,
             pipeline: pipeline,
             name: name,
             stage: "stage:#{stage_idx}",
             stage_idx: stage_idx)
    end
  end

  describe "#merge_requests_as_head_pipeline" do
    let_it_be_with_reload(:pipeline) { create(:ci_empty_pipeline, status: 'created', ref: 'master', sha: 'a288a022a53a5a944fae87bcec6efc87b7061808') }

    it "returns merge requests whose `diff_head_sha` matches the pipeline's SHA" do
      allow_next_instance_of(MergeRequest) do |instance|
        allow(instance).to receive(:diff_head_sha) { 'a288a022a53a5a944fae87bcec6efc87b7061808' }
      end
      merge_request = create(:merge_request, source_project: project, head_pipeline: pipeline, source_branch: pipeline.ref)

      expect(pipeline.merge_requests_as_head_pipeline).to eq([merge_request])
    end

    it "doesn't return merge requests whose source branch doesn't match the pipeline's ref" do
      create(:merge_request, :simple, source_project: project)

      expect(pipeline.merge_requests_as_head_pipeline).to be_empty
    end

    it "doesn't return merge requests whose `diff_head_sha` doesn't match the pipeline's SHA" do
      create(:merge_request, source_project: project, source_branch: pipeline.ref)
      allow_next_instance_of(MergeRequest) do |instance|
        allow(instance).to receive(:diff_head_sha) { '97de212e80737a608d939f648d959671fb0a0142b' }
      end

      expect(pipeline.merge_requests_as_head_pipeline).to be_empty
    end
  end

  describe '#all_merge_requests' do
    let_it_be_with_reload(:project) { create(:project) }
    let_it_be(:pipeline) { create(:ci_empty_pipeline, :created, project: project) }

    shared_examples 'a method that returns all merge requests for a given pipeline' do
      let(:pipeline) { create(:ci_empty_pipeline, status: 'created', project: pipeline_project, ref: 'master') }

      it 'returns all merge requests having the same source branch and the pipeline sha' do
        merge_request = create(:merge_request, source_project: pipeline_project, target_project: project, source_branch: pipeline.ref)

        create(:merge_request_diff, merge_request: merge_request).tap do |diff|
          create(:merge_request_diff_commit, merge_request_diff: diff, sha: pipeline.sha)
        end

        expect(pipeline.all_merge_requests).to eq([merge_request])
      end

      it "doesn't return merge requests having the same source branch without the pipeline sha" do
        merge_request = create(:merge_request, source_project: pipeline_project, target_project: project, source_branch: pipeline.ref)
        create(:merge_request_diff, merge_request: merge_request).tap do |diff|
          create(:merge_request_diff_commit, merge_request_diff: diff, sha: 'unrelated')
        end

        expect(pipeline.all_merge_requests).to be_empty
      end

      it "doesn't return merge requests having a different source branch" do
        create(:merge_request, source_project: pipeline_project, target_project: project, source_branch: 'feature', target_branch: 'master')

        expect(pipeline.all_merge_requests).to be_empty
      end

      context 'when there is a merge request pipeline' do
        let(:source_branch) { 'feature' }
        let(:target_branch) { 'master' }

        let!(:pipeline) do
          create(:ci_pipeline,
                 source: :merge_request_event,
                 project: pipeline_project,
                 ref: source_branch,
                 merge_request: merge_request)
        end

        let(:merge_request) do
          create(:merge_request,
                 source_project: pipeline_project,
                 source_branch: source_branch,
                 target_project: project,
                 target_branch: target_branch)
        end

        it 'returns an associated merge request' do
          expect(pipeline.all_merge_requests).to eq([merge_request])
        end

        context 'when there is another merge request pipeline that targets a different branch' do
          let(:target_branch_2) { 'merge-test' }

          let!(:pipeline_2) do
            create(:ci_pipeline,
                   source: :merge_request_event,
                   project: pipeline_project,
                   ref: source_branch,
                   merge_request: merge_request_2)
          end

          let(:merge_request_2) do
            create(:merge_request,
                   source_project: pipeline_project,
                   source_branch: source_branch,
                   target_project: project,
                   target_branch: target_branch_2)
          end

          it 'does not return an associated merge request' do
            expect(pipeline.all_merge_requests).not_to include(merge_request_2)
          end
        end
      end
    end

    it_behaves_like 'a method that returns all merge requests for a given pipeline' do
      let(:pipeline_project) { project }
    end

    context 'for a fork' do
      let(:fork) { fork_project(project) }

      it_behaves_like 'a method that returns all merge requests for a given pipeline' do
        let(:pipeline_project) { fork }
      end
    end
  end

  describe '#related_merge_requests' do
    let(:merge_request) { create(:merge_request, source_project: project, source_branch: 'feature', target_branch: 'master') }
    let(:other_merge_request) { create(:merge_request, source_project: project, source_branch: 'feature', target_branch: 'stable') }
    let(:branch_pipeline) { create(:ci_pipeline, ref: 'feature') }
    let(:merge_pipeline) { create(:ci_pipeline, :detached_merge_request_pipeline, merge_request: merge_request) }

    context 'for a branch pipeline' do
      subject { branch_pipeline.related_merge_requests }

      it 'when no merge request is created' do
        is_expected.to be_empty
      end

      it 'when another merge requests are created' do
        merge_request
        other_merge_request

        is_expected.to contain_exactly(merge_request, other_merge_request)
      end
    end

    context 'for a merge pipeline' do
      subject { merge_pipeline.related_merge_requests }

      it 'when only merge pipeline is created' do
        merge_pipeline

        is_expected.to contain_exactly(merge_request)
      end

      it 'when a merge request is created' do
        merge_pipeline
        other_merge_request

        is_expected.to contain_exactly(merge_request, other_merge_request)
      end
    end
  end

  describe '#open_merge_requests_refs' do
    let!(:pipeline) { create(:ci_pipeline, user: user, ref: 'feature') }
    let!(:merge_request) { create(:merge_request, source_project: project, source_branch: 'feature', target_branch: 'master') }

    subject { pipeline.open_merge_requests_refs }

    context 'when user is a developer' do
      before do
        project.add_developer(user)
      end

      it 'returns open merge requests' do
        is_expected.to eq([merge_request.to_reference(full: true)])
      end

      it 'does not return closed merge requests' do
        merge_request.close!

        is_expected.to be_empty
      end

      context 'limits amount of returned merge requests' do
        let!(:other_merge_requests) do
          Array.new(4) do |idx|
            create(:merge_request, source_project: project, source_branch: 'feature', target_branch: "master-#{idx}")
          end
        end

        let(:other_merge_requests_refs) do
          other_merge_requests.map { |mr| mr.to_reference(full: true) }
        end

        it 'returns only last 4 in a reverse order' do
          is_expected.to eq(other_merge_requests_refs.reverse)
        end
      end
    end

    context 'when user does not have permissions' do
      it 'does not return any merge requests' do
        is_expected.to be_empty
      end
    end
  end

  describe '#same_family_pipeline_ids' do
    subject { pipeline.same_family_pipeline_ids.map(&:id) }

    let_it_be(:pipeline) { create(:ci_empty_pipeline, :created) }

    context 'when pipeline is not child nor parent' do
      it 'returns just the pipeline id' do
        expect(subject).to contain_exactly(pipeline.id)
      end
    end

    context 'when pipeline is child' do
      let(:parent) { create(:ci_pipeline) }
      let!(:pipeline) { create(:ci_pipeline, child_of: parent) }
      let!(:sibling) { create(:ci_pipeline, child_of: parent) }

      it 'returns parent sibling and self ids' do
        expect(subject).to contain_exactly(parent.id, pipeline.id, sibling.id)
      end
    end

    context 'when pipeline is parent' do
      let!(:child) { create(:ci_pipeline, child_of: pipeline) }

      it 'returns self and child ids' do
        expect(subject).to contain_exactly(pipeline.id, child.id)
      end
    end

    context 'when pipeline is a child of a child pipeline' do
      let(:ancestor) { create(:ci_pipeline) }
      let!(:parent) { create(:ci_pipeline, child_of: ancestor) }
      let!(:pipeline) { create(:ci_pipeline, child_of: parent) }
      let!(:cousin_parent) { create(:ci_pipeline, child_of: ancestor) }
      let!(:cousin) { create(:ci_pipeline, child_of: cousin_parent) }

      it 'returns all family ids' do
        expect(subject).to contain_exactly(
          ancestor.id, parent.id, cousin_parent.id, cousin.id, pipeline.id
        )
      end
    end

    context 'when pipeline is a triggered pipeline' do
      let!(:upstream) { create(:ci_pipeline, project: create(:project), upstream_of: pipeline)}

      it 'returns self id' do
        expect(subject).to contain_exactly(pipeline.id)
      end
    end
  end

  describe '#environments_in_self_and_descendants' do
    subject { pipeline.environments_in_self_and_descendants }

    context 'when pipeline is not child nor parent' do
      let_it_be(:pipeline) { create(:ci_pipeline, :created) }
      let_it_be(:build) { create(:ci_build, :with_deployment, :deploy_to_production, pipeline: pipeline) }

      it 'returns just the pipeline environment' do
        expect(subject).to contain_exactly(build.deployment.environment)
      end
    end

    context 'when pipeline is in extended family' do
      let_it_be(:parent) { create(:ci_pipeline) }
      let_it_be(:parent_build) { create(:ci_build, :with_deployment, environment: 'staging', pipeline: parent) }

      let_it_be(:pipeline) { create(:ci_pipeline, child_of: parent) }
      let_it_be(:build) { create(:ci_build, :with_deployment, :deploy_to_production, pipeline: pipeline) }

      let_it_be(:child) { create(:ci_pipeline, child_of: pipeline) }
      let_it_be(:child_build) { create(:ci_build, :with_deployment, environment: 'canary', pipeline: child) }

      let_it_be(:grandchild) { create(:ci_pipeline, child_of: child) }
      let_it_be(:grandchild_build) { create(:ci_build, :with_deployment, environment: 'test', pipeline: grandchild) }

      let_it_be(:sibling) { create(:ci_pipeline, child_of: parent) }
      let_it_be(:sibling_build) { create(:ci_build, :with_deployment, environment: 'review', pipeline: sibling) }

      it 'returns its own environment and from all descendants' do
        expected_environments = [
          build.deployment.environment,
          child_build.deployment.environment,
          grandchild_build.deployment.environment
        ]
        expect(subject).to match_array(expected_environments)
      end

      it 'does not return parent environment' do
        expect(subject).not_to include(parent_build.deployment.environment)
      end

      it 'does not return sibling environment' do
        expect(subject).not_to include(sibling_build.deployment.environment)
      end
    end

    context 'when each pipeline has multiple environments' do
      let_it_be(:pipeline) { create(:ci_pipeline, :created) }
      let_it_be(:build1) { create(:ci_build, :with_deployment, :deploy_to_production, pipeline: pipeline) }
      let_it_be(:build2) { create(:ci_build, :with_deployment, environment: 'staging', pipeline: pipeline) }

      let_it_be(:child) { create(:ci_pipeline, child_of: pipeline) }
      let_it_be(:child_build1) { create(:ci_build, :with_deployment, environment: 'canary', pipeline: child) }
      let_it_be(:child_build2) { create(:ci_build, :with_deployment, environment: 'test', pipeline: child) }

      it 'returns all related environments' do
        expected_environments = [
          build1.deployment.environment,
          build2.deployment.environment,
          child_build1.deployment.environment,
          child_build2.deployment.environment
        ]
        expect(subject).to match_array(expected_environments)
      end
    end

    context 'when pipeline has no environment' do
      let_it_be(:pipeline) { create(:ci_pipeline, :created) }

      it 'returns empty' do
        expect(subject).to be_empty
      end
    end
  end

  describe '#root_ancestor' do
    subject { pipeline.root_ancestor }

    let_it_be(:pipeline) { create(:ci_pipeline) }

    context 'when pipeline is child of child pipeline' do
      let!(:root_ancestor) { create(:ci_pipeline) }
      let!(:parent_pipeline) { create(:ci_pipeline, child_of: root_ancestor) }
      let!(:pipeline) { create(:ci_pipeline, child_of: parent_pipeline) }

      it 'returns the root ancestor' do
        expect(subject).to eq(root_ancestor)
      end
    end

    context 'when pipeline is root ancestor' do
      let!(:child_pipeline) { create(:ci_pipeline, child_of: pipeline) }

      it 'returns itself' do
        expect(subject).to eq(pipeline)
      end
    end

    context 'when pipeline is standalone' do
      it 'returns itself' do
        expect(subject).to eq(pipeline)
      end
    end

    context 'when pipeline is multi-project downstream pipeline' do
      let!(:upstream_pipeline) do
        create(:ci_pipeline, project: create(:project), upstream_of: pipeline)
      end

      it 'ignores cross project ancestors' do
        expect(subject).to eq(pipeline)
      end
    end
  end

  describe '#stuck?' do
    let(:pipeline) { create(:ci_empty_pipeline, :created) }

    before do
      create(:ci_build, :pending, pipeline: pipeline)
    end

    context 'when pipeline is stuck' do
      it 'is stuck' do
        expect(pipeline).to be_stuck
      end
    end

    context 'when pipeline is not stuck' do
      before do
        create(:ci_runner, :instance, :online)
      end

      it 'is not stuck' do
        expect(pipeline).not_to be_stuck
      end
    end
  end

  describe '#add_error_message' do
    let(:pipeline) { build_stubbed(:ci_pipeline) }

    it 'adds a new pipeline error message' do
      pipeline.add_error_message('The error message')

      expect(pipeline.messages.map(&:content)).to contain_exactly('The error message')
    end
  end

  describe '#has_yaml_errors?' do
    let(:pipeline) { build_stubbed(:ci_pipeline) }

    context 'when yaml_errors is set' do
      before do
        pipeline.yaml_errors = 'File not found'
      end

      it 'returns true if yaml_errors is set' do
        expect(pipeline).to have_yaml_errors
        expect(pipeline.yaml_errors).to include('File not foun')
      end
    end

    it 'returns false if yaml_errors is not set' do
      expect(pipeline).not_to have_yaml_errors
    end
  end

  describe 'notifications when pipeline success or failed' do
    let(:namespace) { create(:namespace) }
    let(:project) { create(:project, :repository, namespace: namespace) }

    let(:pipeline) do
      create(:ci_pipeline,
             project: project,
             sha: project.commit('master').sha,
             user: project.owner)
    end

    before do
      project.add_developer(pipeline.user)

      pipeline.user.global_notification_setting
        .update!(level: 'custom', failed_pipeline: true, success_pipeline: true)

      perform_enqueued_jobs do
        pipeline.enqueue
        pipeline.run
      end
    end

    shared_examples 'sending a notification' do
      it 'sends an email', :sidekiq_might_not_need_inline do
        should_only_email(pipeline.user, kind: :bcc)
      end
    end

    shared_examples 'not sending any notification' do
      it 'does not send any email' do
        should_not_email_anyone
      end
    end

    context 'with success pipeline' do
      it_behaves_like 'sending a notification' do
        before do
          perform_enqueued_jobs do
            pipeline.succeed
          end
        end
      end

      it 'enqueues PipelineNotificationWorker' do
        expect(PipelineNotificationWorker)
          .to receive(:perform_async).with(pipeline.id, ref_status: :success)

        pipeline.succeed
      end

      context 'when pipeline is not the latest' do
        before do
          create(:ci_pipeline, :success, ci_ref: pipeline.ci_ref)
        end

        it 'does not pass ref_status' do
          expect(PipelineNotificationWorker)
            .to receive(:perform_async).with(pipeline.id, ref_status: nil)

          pipeline.succeed!
        end
      end
    end

    context 'with failed pipeline' do
      it_behaves_like 'sending a notification' do
        before do
          perform_enqueued_jobs do
            create(:ci_build, :failed, pipeline: pipeline)
            create(:generic_commit_status, :failed, pipeline: pipeline)

            pipeline.drop
          end
        end
      end

      it 'enqueues PipelineNotificationWorker' do
        expect(PipelineNotificationWorker)
          .to receive(:perform_async).with(pipeline.id, ref_status: :failed)

        pipeline.drop
      end
    end

    context 'with skipped pipeline' do
      before do
        perform_enqueued_jobs do
          pipeline.skip
        end
      end

      it_behaves_like 'not sending any notification'
    end

    context 'with cancelled pipeline' do
      before do
        perform_enqueued_jobs do
          pipeline.cancel
        end
      end

      it_behaves_like 'not sending any notification'
    end
  end

  describe 'updates ci_ref when pipeline finished' do
    context 'when ci_ref exists' do
      let!(:pipeline) { create(:ci_pipeline, :running) }

      it 'updates the ci_ref' do
        expect(pipeline.ci_ref)
          .to receive(:update_status_by!).with(pipeline).and_call_original

        pipeline.succeed!
      end
    end

    context 'when ci_ref does not exist' do
      let!(:pipeline) { create(:ci_pipeline, :running, ci_ref_presence: false) }

      it 'does not raise an exception' do
        expect { pipeline.succeed! }.not_to raise_error
      end
    end
  end

  describe '#ensure_ci_ref!' do
    subject { pipeline.ensure_ci_ref! }

    context 'when ci_ref does not exist yet' do
      let!(:pipeline) { create(:ci_pipeline, ci_ref_presence: false) }

      it 'creates a new ci_ref and assigns it' do
        expect { subject }.to change { Ci::Ref.count }.by(1)

        expect(pipeline.ci_ref).to be_present
      end
    end

    context 'when ci_ref already exists' do
      let!(:pipeline) { create(:ci_pipeline) }

      it 'fetches a new ci_ref and assigns it' do
        expect { subject }.not_to change { Ci::Ref.count }

        expect(pipeline.ci_ref).to be_present
      end
    end
  end

  describe '#builds_in_self_and_descendants' do
    subject(:builds) { pipeline.builds_in_self_and_descendants }

    let(:pipeline) { create(:ci_pipeline) }
    let!(:build) { create(:ci_build, pipeline: pipeline) }

    context 'when pipeline is standalone' do
      it 'returns the list of builds' do
        expect(builds).to contain_exactly(build)
      end
    end

    context 'when pipeline is parent of another pipeline' do
      let(:child_pipeline) { create(:ci_pipeline, child_of: pipeline) }
      let!(:child_build) { create(:ci_build, pipeline: child_pipeline) }

      it 'returns the list of builds' do
        expect(builds).to contain_exactly(build, child_build)
      end
    end

    context 'when pipeline is parent of another parent pipeline' do
      let(:child_pipeline) { create(:ci_pipeline, child_of: pipeline) }
      let!(:child_build) { create(:ci_build, pipeline: child_pipeline) }
      let(:child_of_child_pipeline) { create(:ci_pipeline, child_of: child_pipeline) }
      let!(:child_of_child_build) { create(:ci_build, pipeline: child_of_child_pipeline) }

      it 'returns the list of builds' do
        expect(builds).to contain_exactly(build, child_build, child_of_child_build)
      end
    end
  end

  describe '#build_with_artifacts_in_self_and_descendants' do
    let_it_be(:pipeline) { create(:ci_pipeline) }

    let!(:build) { create(:ci_build, name: 'test', pipeline: pipeline) }
    let(:child_pipeline) { create(:ci_pipeline, child_of: pipeline) }
    let!(:child_build) { create(:ci_build, :artifacts, name: 'test', pipeline: child_pipeline) }

    it 'returns the build with a given name, having artifacts' do
      expect(pipeline.build_with_artifacts_in_self_and_descendants('test')).to eq(child_build)
    end

    context 'when same job name is present in both parent and child pipeline' do
      let!(:build) { create(:ci_build, :artifacts, name: 'test', pipeline: pipeline) }

      it 'returns the job in the parent pipeline' do
        expect(pipeline.build_with_artifacts_in_self_and_descendants('test')).to eq(build)
      end
    end
  end

  describe '#find_job_with_archive_artifacts' do
    let(:pipeline) { create(:ci_pipeline) }
    let!(:old_job) { create(:ci_build, name: 'rspec', retried: true, pipeline: pipeline) }
    let!(:job_without_artifacts) { create(:ci_build, name: 'rspec', pipeline: pipeline) }
    let!(:expected_job) { create(:ci_build, :artifacts, name: 'rspec', pipeline: pipeline ) }
    let!(:different_job) { create(:ci_build, name: 'deploy', pipeline: pipeline) }

    subject { pipeline.find_job_with_archive_artifacts('rspec') }

    it 'finds the expected job' do
      expect(subject).to eq(expected_job)
    end
  end

  describe '#latest_builds_with_artifacts' do
    let(:pipeline) { create(:ci_pipeline) }
    let!(:fresh_build) { create(:ci_build, :success, :artifacts, pipeline: pipeline) }
    let!(:stale_build) { create(:ci_build, :success, :expired, :artifacts, pipeline: pipeline) }

    it 'returns an Array' do
      expect(pipeline.latest_builds_with_artifacts).to be_an_instance_of(Array)
    end

    it 'returns the latest builds with non-expired artifacts' do
      expect(pipeline.latest_builds_with_artifacts).to contain_exactly(fresh_build)
    end

    it 'does not return builds with expired artifacts' do
      expect(pipeline.latest_builds_with_artifacts).not_to include(stale_build)
    end

    it 'memoizes the returned relation' do
      query_count = ActiveRecord::QueryRecorder
        .new { 2.times { pipeline.latest_builds_with_artifacts.to_a } }
        .count

      expect(query_count).to eq(1)
    end
  end

  describe '#batch_lookup_report_artifact_for_file_type' do
    context 'with code quality report artifact' do
      let(:pipeline) { create(:ci_pipeline, :with_codequality_reports) }

      it "returns the code quality artifact" do
        expect(pipeline.batch_lookup_report_artifact_for_file_type(:codequality)).to eq(pipeline.job_artifacts.sample)
      end
    end
  end

  describe '#latest_report_builds' do
    let_it_be(:pipeline) { create(:ci_pipeline, project: project) }

    it 'returns build with test artifacts' do
      test_build = create(:ci_build, :test_reports, pipeline: pipeline)
      coverage_build = create(:ci_build, :coverage_reports, pipeline: pipeline)
      create(:ci_build, :artifacts, pipeline: pipeline, project: project)

      expect(pipeline.latest_report_builds).to contain_exactly(test_build, coverage_build)
    end

    it 'filters builds by scope' do
      test_build = create(:ci_build, :test_reports, pipeline: pipeline)
      create(:ci_build, :coverage_reports, pipeline: pipeline)

      expect(pipeline.latest_report_builds(Ci::JobArtifact.test_reports)).to contain_exactly(test_build)
    end

    it 'only returns not retried builds' do
      test_build = create(:ci_build, :test_reports, pipeline: pipeline)
      create(:ci_build, :test_reports, :retried, pipeline: pipeline)

      expect(pipeline.latest_report_builds).to contain_exactly(test_build)
    end
  end

  describe '#has_reports?' do
    subject { pipeline.has_reports?(Ci::JobArtifact.test_reports) }

    context 'when pipeline has builds with test reports' do
      before do
        create(:ci_build, :test_reports, pipeline: pipeline)
      end

      context 'when pipeline status is running' do
        let(:pipeline) { create(:ci_pipeline, :running) }

        it { is_expected.to be_falsey }
      end

      context 'when pipeline status is success' do
        let(:pipeline) { create(:ci_pipeline, :success) }

        it { is_expected.to be_truthy }
      end
    end

    context 'when pipeline does not have builds with test reports' do
      before do
        create(:ci_build, :artifacts, pipeline: pipeline)
      end

      let(:pipeline) { create(:ci_pipeline, :success) }

      it { is_expected.to be_falsey }
    end

    context 'when retried build has test reports' do
      before do
        create(:ci_build, :retried, :test_reports, pipeline: pipeline)
      end

      let(:pipeline) { create(:ci_pipeline, :success) }

      it { is_expected.to be_falsey }
    end
  end

  describe '#has_coverage_reports?' do
    subject { pipeline.has_coverage_reports? }

    context 'when pipeline has a code coverage artifact' do
      let(:pipeline) { create(:ci_pipeline, :with_coverage_report_artifact, :running) }

      it { expect(subject).to be_truthy }
    end

    context 'when pipeline does not have a code coverage artifact' do
      let(:pipeline) { create(:ci_pipeline, :success) }

      it { expect(subject).to be_falsey }
    end
  end

  describe '#can_generate_coverage_reports?' do
    subject { pipeline.can_generate_coverage_reports? }

    context 'when pipeline has builds with coverage reports' do
      before do
        create(:ci_build, :coverage_reports, pipeline: pipeline)
      end

      context 'when pipeline status is running' do
        let(:pipeline) { create(:ci_pipeline, :running) }

        it { expect(subject).to be_falsey }
      end

      context 'when pipeline status is success' do
        let(:pipeline) { create(:ci_pipeline, :success) }

        it { expect(subject).to be_truthy }
      end
    end

    context 'when pipeline does not have builds with coverage reports' do
      before do
        create(:ci_build, :artifacts, pipeline: pipeline)
      end

      let(:pipeline) { create(:ci_pipeline, :success) }

      it { expect(subject).to be_falsey }
    end
  end

  describe '#has_codequality_mr_diff_report?' do
    subject { pipeline.has_codequality_mr_diff_report? }

    context 'when pipeline has a codequality mr diff report' do
      let(:pipeline) { create(:ci_pipeline, :with_codequality_mr_diff_report, :running) }

      it { expect(subject).to be_truthy }
    end

    context 'when pipeline does not have a codequality mr diff report' do
      let(:pipeline) { create(:ci_pipeline, :success) }

      it { expect(subject).to be_falsey }
    end
  end

  describe '#can_generate_codequality_reports?' do
    subject { pipeline.can_generate_codequality_reports? }

    context 'when pipeline has builds with codequality reports' do
      before do
        create(:ci_build, :codequality_reports, pipeline: pipeline)
      end

      context 'when pipeline status is running' do
        let(:pipeline) { create(:ci_pipeline, :running) }

        it { expect(subject).to be_falsey }
      end

      context 'when pipeline status is success' do
        let(:pipeline) { create(:ci_pipeline, :success) }

        it 'can generate a codequality report' do
          expect(subject).to be_truthy
        end
      end
    end

    context 'when pipeline does not have builds with codequality reports' do
      before do
        create(:ci_build, :artifacts, pipeline: pipeline)
      end

      let(:pipeline) { create(:ci_pipeline, :success) }

      it { expect(subject).to be_falsey }
    end
  end

  describe '#test_report_summary' do
    subject { pipeline.test_report_summary }

    let(:pipeline) { create(:ci_pipeline, :success) }

    context 'when pipeline has multiple builds with report results' do
      before do
        create(:ci_build, :success, :report_results, name: 'rspec', pipeline: pipeline)
        create(:ci_build, :success, :report_results, name: 'java', pipeline: pipeline)
      end

      it 'returns test report summary with collected data' do
        expect(subject.total).to include(time: 0.84, count: 4, success: 0, failed: 0, skipped: 0, error: 4)
      end
    end

    context 'when pipeline does not have any builds with report results' do
      it 'returns empty test report summary' do
        expect(subject.total).to include(time: 0, count: 0, success: 0, failed: 0, skipped: 0, error: 0)
      end
    end
  end

  describe '#test_reports' do
    subject { pipeline.test_reports }

    let_it_be(:pipeline) { create(:ci_pipeline) }

    context 'when pipeline has multiple builds with test reports' do
      let!(:build_rspec) { create(:ci_build, :success, name: 'rspec', pipeline: pipeline) }
      let!(:build_java) { create(:ci_build, :success, name: 'java', pipeline: pipeline) }

      before do
        create(:ci_job_artifact, :junit, job: build_rspec)
        create(:ci_job_artifact, :junit_with_ant, job: build_java)
      end

      it 'returns test reports with collected data' do
        expect(subject.total_count).to be(7)
        expect(subject.success_count).to be(5)
        expect(subject.failed_count).to be(2)
      end

      context 'when builds are retried' do
        let!(:build_rspec) { create(:ci_build, :retried, :success, name: 'rspec', pipeline: pipeline) }
        let!(:build_java) { create(:ci_build, :retried, :success, name: 'java', pipeline: pipeline) }

        it 'does not take retried builds into account' do
          expect(subject.total_count).to be(0)
          expect(subject.success_count).to be(0)
          expect(subject.failed_count).to be(0)
        end
      end
    end

    context 'when pipeline does not have any builds with test reports' do
      it 'returns empty test reports' do
        expect(subject.total_count).to be(0)
      end
    end
  end

  describe '#accessibility_reports' do
    subject { pipeline.accessibility_reports }

    let_it_be(:pipeline) { create(:ci_pipeline) }

    context 'when pipeline has multiple builds with accessibility reports' do
      let(:build_rspec) { create(:ci_build, :success, name: 'rspec', pipeline: pipeline) }
      let(:build_golang) { create(:ci_build, :success, name: 'golang', pipeline: pipeline) }

      before do
        create(:ci_job_artifact, :accessibility, job: build_rspec)
        create(:ci_job_artifact, :accessibility_without_errors, job: build_golang)
      end

      it 'returns accessibility report with collected data' do
        expect(subject.urls.keys).to match_array([
          "https://pa11y.org/",
          "https://about.gitlab.com/"
        ])
      end

      context 'when builds are retried' do
        let(:build_rspec) { create(:ci_build, :retried, :success, name: 'rspec', pipeline: pipeline) }
        let(:build_golang) { create(:ci_build, :retried, :success, name: 'golang', pipeline: pipeline) }

        it 'returns empty urls for accessibility reports' do
          expect(subject.urls).to be_empty
        end
      end
    end

    context 'when pipeline does not have any builds with accessibility reports' do
      it 'returns empty urls for accessibility reports' do
        expect(subject.urls).to be_empty
      end
    end
  end

  describe '#coverage_reports' do
    subject { pipeline.coverage_reports }

    let_it_be(:pipeline) { create(:ci_pipeline) }

    context 'when pipeline has multiple builds with coverage reports' do
      let!(:build_rspec) { create(:ci_build, :success, name: 'rspec', pipeline: pipeline) }
      let!(:build_golang) { create(:ci_build, :success, name: 'golang', pipeline: pipeline) }

      before do
        create(:ci_job_artifact, :cobertura, job: build_rspec)
        create(:ci_job_artifact, :coverage_gocov_xml, job: build_golang)
      end

      it 'returns coverage reports with collected data' do
        expect(subject.files.keys).to match_array([
          "auth/token.go",
          "auth/rpccredentials.go",
          "app/controllers/abuse_reports_controller.rb"
        ])
      end

      it 'does not execute N+1 queries' do
        single_build_pipeline = create(:ci_empty_pipeline, :created)
        single_rspec = create(:ci_build, :success, name: 'rspec', pipeline: single_build_pipeline)
        create(:ci_job_artifact, :cobertura, job: single_rspec, project: project)

        control = ActiveRecord::QueryRecorder.new { single_build_pipeline.coverage_reports }

        expect { subject }.not_to exceed_query_limit(control)
      end

      context 'when builds are retried' do
        let!(:build_rspec) { create(:ci_build, :retried, :success, name: 'rspec', pipeline: pipeline) }
        let!(:build_golang) { create(:ci_build, :retried, :success, name: 'golang', pipeline: pipeline) }

        it 'does not take retried builds into account' do
          expect(subject.files).to eql({})
        end
      end
    end

    context 'when pipeline does not have any builds with coverage reports' do
      it 'returns empty coverage reports' do
        expect(subject.files).to eql({})
      end
    end
  end

  describe '#codequality_reports' do
    subject(:codequality_reports) { pipeline.codequality_reports }

    let_it_be(:pipeline) { create(:ci_pipeline) }

    context 'when pipeline has multiple builds with codequality reports' do
      let(:build_rspec) { create(:ci_build, :success, name: 'rspec', pipeline: pipeline) }
      let(:build_golang) { create(:ci_build, :success, name: 'golang', pipeline: pipeline) }

      before do
        create(:ci_job_artifact, :codequality, job: build_rspec)
        create(:ci_job_artifact, :codequality_without_errors, job: build_golang)
      end

      it 'returns codequality report with collected data' do
        expect(codequality_reports.degradations_count).to eq(3)
      end

      context 'when builds are retried' do
        let(:build_rspec) { create(:ci_build, :retried, :success, name: 'rspec', pipeline: pipeline) }
        let(:build_golang) { create(:ci_build, :retried, :success, name: 'golang', pipeline: pipeline) }

        it 'returns a codequality reports without degradations' do
          expect(codequality_reports.degradations).to be_empty
        end
      end
    end

    context 'when pipeline does not have any builds with codequality reports' do
      it 'returns codequality reports without degradations' do
        expect(codequality_reports.degradations).to be_empty
      end
    end
  end

  describe '#uses_needs?' do
    let_it_be(:pipeline) { create(:ci_pipeline) }

    context 'when the scheduling type is `dag`' do
      it 'returns true' do
        create(:ci_build, pipeline: pipeline, scheduling_type: :dag)

        expect(pipeline.uses_needs?).to eq(true)
      end
    end

    context 'when the scheduling type is nil or stage' do
      it 'returns false' do
        create(:ci_build, pipeline: pipeline, scheduling_type: :stage)

        expect(pipeline.uses_needs?).to eq(false)
      end
    end
  end

  describe '#total_size' do
    let(:pipeline) { create(:ci_pipeline) }
    let!(:build_job1) { create(:ci_build, pipeline: pipeline, stage_idx: 0) }
    let!(:build_job2) { create(:ci_build, pipeline: pipeline, stage_idx: 0) }
    let!(:test_job_failed_and_retried) { create(:ci_build, :failed, :retried, pipeline: pipeline, stage_idx: 1) }
    let!(:second_test_job) { create(:ci_build, pipeline: pipeline, stage_idx: 1) }
    let!(:deploy_job) { create(:ci_build, pipeline: pipeline, stage_idx: 2) }

    it 'returns all jobs (including failed and retried)' do
      expect(pipeline.total_size).to eq(5)
    end
  end

  describe '#status' do
    context 'when transitioning to failed' do
      context 'when pipeline has autodevops as source' do
        let(:pipeline) { create(:ci_pipeline, :running, :auto_devops_source) }

        it 'calls autodevops disable service' do
          expect(AutoDevops::DisableWorker).to receive(:perform_async).with(pipeline.id)

          pipeline.drop
        end
      end

      context 'when pipeline has other source' do
        let(:pipeline) { create(:ci_pipeline, :running, :repository_source) }

        it 'does not call auto devops disable service' do
          expect(AutoDevops::DisableWorker).not_to receive(:perform_async)

          pipeline.drop
        end
      end

      context 'with failure_reason' do
        let(:pipeline) { create(:ci_pipeline, :running) }
        let(:failure_reason) { 'config_error' }
        let(:counter) { Gitlab::Metrics.counter(:gitlab_ci_pipeline_failure_reasons, 'desc') }

        it 'increments the counter with the failure_reason' do
          expect { pipeline.drop!(failure_reason) }.to change { counter.get(reason: failure_reason) }.by(1)
        end
      end
    end
  end

  describe '#default_branch?' do
    subject { pipeline.default_branch? }

    context 'when pipeline ref is the default branch of the project' do
      let(:pipeline) do
        build(:ci_empty_pipeline, :created, project: project, ref: project.default_branch)
      end

      it "returns true" do
        expect(subject).to be_truthy
      end
    end

    context 'when pipeline ref is not the default branch of the project' do
      let(:pipeline) do
        build(:ci_empty_pipeline, :created, project: project, ref: 'another_branch')
      end

      it "returns false" do
        expect(subject).to be_falsey
      end
    end
  end

  describe '#find_stage_by_name' do
    let_it_be(:pipeline) { create(:ci_pipeline) }

    let(:stage_name) { 'test' }

    let(:stage) do
      create(:ci_stage_entity,
             pipeline: pipeline,
             project: pipeline.project,
             name: 'test')
    end

    before do
      create_list(:ci_build, 2, pipeline: pipeline, stage: stage.name)
    end

    subject { pipeline.find_stage_by_name!(stage_name) }

    context 'when stage exists' do
      it { is_expected.to eq(stage) }
    end

    context 'when stage does not exist' do
      let(:stage_name) { 'build' }

      it 'raises an ActiveRecord exception' do
        expect do
          subject
        end.to raise_exception(ActiveRecord::RecordNotFound)
      end
    end
  end

  describe '#full_error_messages' do
    subject { pipeline.full_error_messages }

    before do
      pipeline.valid?
    end

    context 'when pipeline has errors' do
      let(:pipeline) { build(:ci_pipeline, sha: nil, ref: nil) }

      it 'returns the full error messages' do
        is_expected.to eq("Sha can't be blank and Ref can't be blank")
      end
    end

    context 'when pipeline does not have errors' do
      let(:pipeline) { build(:ci_pipeline) }

      it 'returns empty string' do
        is_expected.to be_empty
      end
    end
  end

  describe '#created_successfully?' do
    subject { pipeline.created_successfully? }

    context 'when pipeline is not persisted' do
      let(:pipeline) { build(:ci_pipeline) }

      it { is_expected.to be_falsey }
    end

    context 'when pipeline is persisted' do
      context 'when pipeline has failure reasons' do
        let(:pipeline) { create(:ci_pipeline, failure_reason: :config_error) }

        it { is_expected.to be_falsey }
      end

      context 'when pipeline has no failure reasons' do
        let(:pipeline) { create(:ci_pipeline, failure_reason: nil) }

        it { is_expected.to be_truthy }
      end
    end
  end

  describe '#parent_pipeline' do
    let_it_be_with_reload(:pipeline) { create(:ci_pipeline) }

    context 'when pipeline is triggered by a pipeline from the same project' do
      let_it_be(:upstream_pipeline) { create(:ci_pipeline) }
      let_it_be(:pipeline) { create(:ci_pipeline, child_of: upstream_pipeline) }

      it 'returns the parent pipeline' do
        expect(pipeline.parent_pipeline).to eq(upstream_pipeline)
      end

      it 'is child' do
        expect(pipeline).to be_child
      end
    end

    context 'when pipeline is triggered by a pipeline from another project' do
      let(:pipeline) { create(:ci_pipeline) }
      let!(:upstream_pipeline) { create(:ci_pipeline, project: create(:project), upstream_of: pipeline) }

      it 'returns nil' do
        expect(pipeline.parent_pipeline).to be_nil
      end

      it 'is not child' do
        expect(pipeline).not_to be_child
      end
    end

    context 'when pipeline is not triggered by a pipeline' do
      let_it_be(:pipeline) { create(:ci_pipeline) }

      it 'returns nil' do
        expect(pipeline.parent_pipeline).to be_nil
      end

      it 'is not child' do
        expect(pipeline).not_to be_child
      end
    end
  end

  describe '#child_pipelines' do
    let_it_be(:project) { create(:project) }
    let_it_be_with_reload(:pipeline) { create(:ci_pipeline, project: project) }

    context 'when pipeline triggered other pipelines on same project' do
      let(:downstream_pipeline) { create(:ci_pipeline, project: pipeline.project) }

      before do
        create(:ci_sources_pipeline,
          source_pipeline: pipeline,
          source_project: pipeline.project,
          pipeline: downstream_pipeline,
          project: pipeline.project)
      end

      it 'returns the child pipelines' do
        expect(pipeline.child_pipelines).to eq [downstream_pipeline]
      end

      it 'is parent' do
        expect(pipeline).to be_parent
      end
    end

    context 'when pipeline triggered other pipelines on another project' do
      let(:downstream_pipeline) { create(:ci_pipeline) }

      before do
        create(:ci_sources_pipeline,
          source_pipeline: pipeline,
          source_project: pipeline.project,
          pipeline: downstream_pipeline,
          project: downstream_pipeline.project)
      end

      it 'returns empty array' do
        expect(pipeline.child_pipelines).to be_empty
      end

      it 'is not parent' do
        expect(pipeline).not_to be_parent
      end
    end

    context 'when pipeline did not trigger any pipelines' do
      it 'returns empty array' do
        expect(pipeline.child_pipelines).to be_empty
      end

      it 'is not parent' do
        expect(pipeline).not_to be_parent
      end
    end
  end

  describe 'upstream status interactions' do
    let_it_be_with_reload(:pipeline) { create(:ci_pipeline, :created) }

    context 'when a pipeline has an upstream status' do
      context 'when an upstream status is a bridge' do
        let(:bridge) { create(:ci_bridge, status: :pending) }

        before do
          create(:ci_sources_pipeline, pipeline: pipeline, source_job: bridge)
        end

        describe '#bridge_triggered?' do
          it 'is a pipeline triggered by a bridge' do
            expect(pipeline).to be_bridge_triggered
          end
        end

        describe '#source_job' do
          it 'has a correct source job' do
            expect(pipeline.source_job).to eq bridge
          end
        end

        describe '#source_bridge' do
          it 'has a correct bridge source' do
            expect(pipeline.source_bridge).to eq bridge
          end
        end
      end

      context 'when an upstream status is a build' do
        let(:build) { create(:ci_build) }

        before do
          create(:ci_sources_pipeline, pipeline: pipeline, source_job: build)
        end

        describe '#bridge_triggered?' do
          it 'is a pipeline that has not been triggered by a bridge' do
            expect(pipeline).not_to be_bridge_triggered
          end
        end

        describe '#source_job' do
          it 'has a correct source job' do
            expect(pipeline.source_job).to eq build
          end
        end

        describe '#source_bridge' do
          it 'does not have a bridge source' do
            expect(pipeline.source_bridge).to be_nil
          end
        end
      end
    end
  end

  describe '#source_ref_path' do
    subject { pipeline.source_ref_path }

    let(:pipeline) { create(:ci_pipeline, :created) }

    context 'when pipeline is for a branch' do
      it { is_expected.to eq(Gitlab::Git::BRANCH_REF_PREFIX + pipeline.source_ref.to_s) }
    end

    context 'when pipeline is for a merge request' do
      let(:merge_request) { create(:merge_request, source_project: project) }
      let(:pipeline) { create(:ci_pipeline, project: project, head_pipeline_of: merge_request) }

      it { is_expected.to eq(Gitlab::Git::BRANCH_REF_PREFIX + pipeline.source_ref.to_s) }
    end

    context 'when pipeline is for a tag' do
      let(:pipeline) { create(:ci_pipeline, tag: true) }

      it { is_expected.to eq(Gitlab::Git::TAG_REF_PREFIX + pipeline.source_ref.to_s) }
    end
  end

  describe '#builds_with_coverage' do
    let_it_be(:pipeline) { create(:ci_pipeline, :created) }

    it 'returns builds with coverage only' do
      rspec = create(:ci_build, name: 'rspec', coverage: 97.1, pipeline: pipeline)
      jest  = create(:ci_build, name: 'jest', coverage: 94.1, pipeline: pipeline)
      karma = create(:ci_build, name: 'karma', coverage: nil, pipeline: pipeline)

      builds = pipeline.builds_with_coverage

      expect(builds).to include(rspec, jest)
      expect(builds).not_to include(karma)
    end

    it 'returns only latest builds' do
      obsolete = create(:ci_build, name: "jest", coverage: 10.12, pipeline: pipeline, retried: true)
      retried  = create(:ci_build, name: "jest", coverage: 20.11, pipeline: pipeline)

      builds = pipeline.builds_with_coverage

      expect(builds).to include(retried)
      expect(builds).not_to include(obsolete)
    end
  end

  describe '#self_and_upstreams' do
    subject(:self_and_upstreams) { pipeline.self_and_upstreams }

    let_it_be(:pipeline) { create(:ci_pipeline, :created) }

    context 'when pipeline is not child nor parent' do
      it 'returns just the pipeline itself' do
        expect(self_and_upstreams).to contain_exactly(pipeline)
      end
    end

    context 'when pipeline is child' do
      let(:parent) { create(:ci_pipeline) }
      let(:sibling) { create(:ci_pipeline) }

      before do
        create_source_pipeline(parent, pipeline)
        create_source_pipeline(parent, sibling)
      end

      it 'returns parent and self' do
        expect(self_and_upstreams).to contain_exactly(parent, pipeline)
      end
    end

    context 'when pipeline is parent' do
      let(:child) { create(:ci_pipeline) }

      before do
        create_source_pipeline(pipeline, child)
      end

      it 'returns self' do
        expect(self_and_upstreams).to contain_exactly(pipeline)
      end
    end

    context 'when pipeline is a child of a child pipeline' do
      let_it_be(:pipeline) { create(:ci_pipeline, :created) }

      let(:ancestor) { create(:ci_pipeline) }
      let(:parent) { create(:ci_pipeline) }

      before do
        create_source_pipeline(ancestor, parent)
        create_source_pipeline(parent, pipeline)
      end

      it 'returns self, parent and ancestor' do
        expect(self_and_upstreams).to contain_exactly(ancestor, parent, pipeline)
      end
    end

    context 'when pipeline is a triggered pipeline from a different project' do
      let_it_be(:pipeline) { create(:ci_pipeline, :created) }

      let(:upstream) { create(:ci_pipeline, project: create(:project)) }

      before do
        create_source_pipeline(upstream, pipeline)
      end

      it 'returns upstream and self' do
        expect(self_and_upstreams).to contain_exactly(pipeline, upstream)
      end
    end
  end

  describe '#self_and_ancestors' do
    subject(:self_and_ancestors) { pipeline.self_and_ancestors }

    context 'when pipeline is child' do
      let(:pipeline) { create(:ci_pipeline, :created) }
      let(:parent) { create(:ci_pipeline) }
      let(:sibling) { create(:ci_pipeline) }

      before do
        create_source_pipeline(parent, pipeline)
        create_source_pipeline(parent, sibling)
      end

      it 'returns parent and self' do
        expect(self_and_ancestors).to contain_exactly(parent, pipeline)
      end
    end

    context 'when pipeline is a triggered pipeline from a different project' do
      let_it_be(:pipeline) { create(:ci_pipeline, :created) }

      let(:upstream) { create(:ci_pipeline, project: create(:project)) }

      before do
        create_source_pipeline(upstream, pipeline)
      end

      it 'returns only self' do
        expect(self_and_ancestors).to contain_exactly(pipeline)
      end
    end
  end

  describe '#reset_source_bridge!' do
    let(:pipeline) { create(:ci_pipeline, :created, project: project) }

    subject(:reset_bridge) { pipeline.reset_source_bridge!(project.owner) }

    # This whole block will be removed by https://gitlab.com/gitlab-org/gitlab/-/issues/329194
    # It contains some duplicate checks.
    context 'when the FF ci_reset_bridge_with_subsequent_jobs is disabled' do
      before do
        stub_feature_flags(ci_reset_bridge_with_subsequent_jobs: false)
      end

      context 'when the pipeline is a child pipeline and the bridge is depended' do
        let!(:parent_pipeline) { create(:ci_pipeline) }
        let!(:bridge) { create_bridge(parent_pipeline, pipeline, true) }

        it 'marks source bridge as pending' do
          reset_bridge

          expect(bridge.reload).to be_pending
        end

        context 'when the parent pipeline has subsequent jobs after the bridge' do
          let!(:after_bridge_job) { create(:ci_build, :skipped, pipeline: parent_pipeline, stage_idx: bridge.stage_idx + 1) }

          it 'does not touch subsequent jobs of the bridge' do
            reset_bridge

            expect(after_bridge_job.reload).to be_skipped
          end
        end

        context 'when the parent pipeline has a dependent upstream pipeline' do
          let(:upstream_pipeline) { create(:ci_pipeline, project: create(:project)) }
          let!(:upstream_bridge) { create_bridge(upstream_pipeline, parent_pipeline, true) }

          let(:upstream_upstream_pipeline) { create(:ci_pipeline, project: create(:project)) }
          let!(:upstream_upstream_bridge) { create_bridge(upstream_upstream_pipeline, upstream_pipeline, true) }

          it 'marks all source bridges as pending' do
            reset_bridge

            expect(bridge.reload).to be_pending
            expect(upstream_bridge.reload).to be_pending
            expect(upstream_upstream_bridge.reload).to be_pending
          end
        end
      end
    end

    context 'when the pipeline is a child pipeline and the bridge is depended' do
      let!(:parent_pipeline) { create(:ci_pipeline) }
      let!(:bridge) { create_bridge(parent_pipeline, pipeline, true) }

      it 'marks source bridge as pending' do
        reset_bridge

        expect(bridge.reload).to be_pending
      end

      context 'when the parent pipeline has subsequent jobs after the bridge' do
        let!(:after_bridge_job) { create(:ci_build, :skipped, pipeline: parent_pipeline, stage_idx: bridge.stage_idx + 1) }

        it 'marks subsequent jobs of the bridge as processable' do
          reset_bridge

          expect(after_bridge_job.reload).to be_created
        end
      end

      context 'when the parent pipeline has a dependent upstream pipeline' do
        let!(:upstream_bridge) do
          create_bridge(create(:ci_pipeline, project: create(:project)), parent_pipeline, true)
        end

        it 'marks all source bridges as pending' do
          reset_bridge

          expect(bridge.reload).to be_pending
          expect(upstream_bridge.reload).to be_pending
        end
      end
    end

    context 'when the pipeline is a child pipeline and the bridge is not depended' do
      let!(:parent_pipeline) { create(:ci_pipeline) }
      let!(:bridge) { create_bridge(parent_pipeline, pipeline, false) }

      it 'does not touch source bridge' do
        reset_bridge

        expect(bridge.reload).to be_success
      end

      context 'when the parent pipeline has a dependent upstream pipeline' do
        let!(:upstream_bridge) do
          create_bridge(create(:ci_pipeline, project: create(:project)), parent_pipeline, true)
        end

        it 'does not touch any source bridge' do
          reset_bridge

          expect(bridge.reload).to be_success
          expect(upstream_bridge.reload).to be_success
        end
      end
    end

    private

    def create_bridge(upstream, downstream, depend = false)
      options = depend ? { trigger: { strategy: 'depend' } } : {}

      bridge = create(:ci_bridge, pipeline: upstream, status: 'success', options: options)
      create(:ci_sources_pipeline, pipeline: downstream, source_job: bridge)

      bridge
    end
  end

  describe 'test failure history processing' do
    let(:pipeline) { build(:ci_pipeline, :created) }

    it 'performs the service asynchronously when the pipeline is completed' do
      service = double

      expect(Ci::TestFailureHistoryService).to receive(:new).with(pipeline).and_return(service)
      expect(service).to receive_message_chain(:async, :perform_if_needed)

      pipeline.succeed!
    end
  end

  describe '#latest_test_report_builds' do
    let_it_be(:pipeline) { create(:ci_pipeline, :created) }

    it 'returns pipeline builds with test report artifacts' do
      test_build = create(:ci_build, :test_reports, pipeline: pipeline)
      create(:ci_build, :artifacts, pipeline: pipeline, project: project)

      expect(pipeline.latest_test_report_builds).to contain_exactly(test_build)
    end

    it 'preloads project on each build to avoid N+1 queries' do
      create(:ci_build, :test_reports, pipeline: pipeline)

      control_count = ActiveRecord::QueryRecorder.new do
        pipeline.latest_test_report_builds.map(&:project).map(&:full_path)
      end

      multi_build_pipeline = create(:ci_empty_pipeline, :created)
      create(:ci_build, :test_reports, pipeline: multi_build_pipeline, project: project)
      create(:ci_build, :test_reports, pipeline: multi_build_pipeline, project: project)

      expect { multi_build_pipeline.latest_test_report_builds.map(&:project).map(&:full_path) }
        .not_to exceed_query_limit(control_count)
    end
  end

  describe '#builds_with_failed_tests' do
    let_it_be(:pipeline) { create(:ci_pipeline, :created) }

    it 'returns pipeline builds with test report artifacts' do
      failed_build = create(:ci_build, :failed, :test_reports, pipeline: pipeline)
      create(:ci_build, :success, :test_reports, pipeline: pipeline)

      expect(pipeline.builds_with_failed_tests).to contain_exactly(failed_build)
    end

    it 'supports limiting the number of builds to fetch' do
      create(:ci_build, :failed, :test_reports, pipeline: pipeline)
      create(:ci_build, :failed, :test_reports, pipeline: pipeline)

      expect(pipeline.builds_with_failed_tests(limit: 1).count).to eq(1)
    end

    it 'preloads project on each build to avoid N+1 queries' do
      create(:ci_build, :failed, :test_reports, pipeline: pipeline)

      control_count = ActiveRecord::QueryRecorder.new do
        pipeline.builds_with_failed_tests.map(&:project).map(&:full_path)
      end

      multi_build_pipeline = create(:ci_empty_pipeline, :created)
      create(:ci_build, :failed, :test_reports, pipeline: multi_build_pipeline)
      create(:ci_build, :failed, :test_reports, pipeline: multi_build_pipeline)

      expect { multi_build_pipeline.builds_with_failed_tests.map(&:project).map(&:full_path) }
        .not_to exceed_query_limit(control_count)
    end
  end

  describe '#build_matchers' do
    let_it_be(:user) { create(:user) }
    let_it_be(:pipeline) { create(:ci_pipeline, user: user) }
    let_it_be(:builds) { create_list(:ci_build, 2, pipeline: pipeline, project: pipeline.project, user: user) }

    let(:project) { pipeline.project }

    subject(:matchers) { pipeline.build_matchers }

    it 'returns build matchers' do
      expect(matchers.size).to eq(1)
      expect(matchers).to all be_a(Gitlab::Ci::Matching::BuildMatcher)
      expect(matchers.first.build_ids).to match_array(builds.map(&:id))
    end

    context 'with retried builds' do
      let(:retried_build) { builds.first }

      before do
        stub_not_protect_default_branch
        project.add_developer(user)

        retried_build.cancel!
        ::Ci::Build.retry(retried_build, user)
      end

      it 'does not include retried builds' do
        expect(matchers.size).to eq(1)
        expect(matchers.first.build_ids).not_to include(retried_build.id)
      end
    end
  end
end
