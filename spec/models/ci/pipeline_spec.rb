# frozen_string_literal: true

require 'spec_helper'

describe Ci::Pipeline, :mailer do
  include ProjectForksHelper
  include StubRequests

  let(:user) { create(:user) }
  set(:project) { create(:project) }

  let(:pipeline) do
    create(:ci_empty_pipeline, status: :created, project: project)
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
  it { is_expected.to have_many(:auto_canceled_pipelines) }
  it { is_expected.to have_many(:auto_canceled_jobs) }
  it { is_expected.to have_many(:sourced_pipelines) }
  it { is_expected.to have_many(:triggered_pipelines) }

  it { is_expected.to have_one(:chat_data) }
  it { is_expected.to have_one(:source_pipeline) }
  it { is_expected.to have_one(:triggered_by_pipeline) }
  it { is_expected.to have_one(:source_job) }
  it { is_expected.to have_one(:pipeline_config) }

  it { is_expected.to validate_presence_of(:sha) }
  it { is_expected.to validate_presence_of(:status) }

  it { is_expected.to respond_to :git_author_name }
  it { is_expected.to respond_to :git_author_email }
  it { is_expected.to respond_to :short_sha }
  it { is_expected.to delegate_method(:full_path).to(:project).with_prefix }

  describe 'associations' do
    it 'has a bidirectional relationship with projects' do
      expect(described_class.reflect_on_association(:project).has_inverse?).to eq(:all_pipelines)
      expect(Project.reflect_on_association(:all_pipelines).has_inverse?).to eq(:project)
      expect(Project.reflect_on_association(:ci_pipelines).has_inverse?).to eq(:project)
    end
  end

  describe '.processables' do
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

  describe '.for_sha' do
    subject { described_class.for_sha(sha) }

    let(:sha) { 'abc' }
    let!(:pipeline) { create(:ci_pipeline, sha: 'abc') }

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
    let!(:pipeline) { create(:ci_pipeline, source_sha: 'abc') }

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

  describe '#merge_request_pipeline?' do
    subject { pipeline.merge_request_pipeline? }

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

    set(:merge_request) { create(:merge_request) }
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
    subject { described_class.with_reports(Ci::JobArtifact.test_reports) }

    context 'when pipeline has a test report' do
      let!(:pipeline_with_report) { create(:ci_pipeline, :with_test_reports) }

      it 'selects the pipeline' do
        is_expected.to eq([pipeline_with_report])
      end
    end

    context 'when pipeline does not have metrics reports' do
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

  describe 'Validations for merge request pipelines' do
    let(:pipeline) do
      build(:ci_pipeline, source: source, merge_request: merge_request)
    end

    let(:merge_request) do
      create(:merge_request,
        source_project: project,
        source_branch:  'feature',
        target_project: project,
        target_branch:  'master')
    end

    context 'when source is merge request' do
      let(:source) { :merge_request_event }

      context 'when merge request is specified' do
        it { expect(pipeline).to be_valid }
      end

      context 'when merge request is empty' do
        let(:merge_request) { nil }

        it { expect(pipeline).not_to be_valid }
      end
    end

    context 'when source is web' do
      let(:source) { :web }

      context 'when merge request is specified' do
        it { expect(pipeline).not_to be_valid }
      end

      context 'when merge request is empty' do
        let(:merge_request) { nil }

        it { expect(pipeline).to be_valid }
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
        build(:ci_empty_pipeline, status: :created, project: project, source: nil)
      end

      it "prevents from creating an object" do
        expect(pipeline).not_to be_valid
      end
    end

    context 'when updating existing pipeline' do
      before do
        pipeline.update_attribute(:source, nil)
      end

      it "object is valid" do
        expect(pipeline).to be_valid
      end
    end
  end

  describe '#block' do
    it 'changes pipeline status to manual' do
      expect(pipeline.block).to be true
      expect(pipeline.reload).to be_manual
      expect(pipeline.reload).to be_blocked
    end
  end

  describe '#delay' do
    subject { pipeline.delay }

    let(:pipeline) { build(:ci_pipeline, status: :created) }

    it 'changes pipeline status to schedule' do
      subject

      expect(pipeline).to be_scheduled
    end
  end

  describe '#valid_commit_sha' do
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

    it 'has 8 items' do
      expect(subject.size).to eq(8)
    end
    it { expect(pipeline.sha).to start_with(subject) }
  end

  describe '#retried' do
    subject { pipeline.retried }

    before do
      @build1 = create(:ci_build, pipeline: pipeline, name: 'deploy', retried: true)
      @build2 = create(:ci_build, pipeline: pipeline, name: 'deploy')
    end

    it 'returns old builds' do
      is_expected.to contain_exactly(@build1)
    end
  end

  describe "coverage" do
    let(:project) { create(:project, build_coverage_regex: "/.*/") }
    let(:pipeline) { create(:ci_empty_pipeline, project: project) }

    it "calculates average when there are two builds with coverage" do
      create(:ci_build, name: "rspec", coverage: 30, pipeline: pipeline)
      create(:ci_build, name: "rubocop", coverage: 40, pipeline: pipeline)
      expect(pipeline.coverage).to eq("35.00")
    end

    it "calculates average when there are two builds with coverage and one with nil" do
      create(:ci_build, name: "rspec", coverage: 30, pipeline: pipeline)
      create(:ci_build, name: "rubocop", coverage: 40, pipeline: pipeline)
      create(:ci_build, pipeline: pipeline)
      expect(pipeline.coverage).to eq("35.00")
    end

    it "calculates average when there are two builds with coverage and one is retried" do
      create(:ci_build, name: "rspec", coverage: 30, pipeline: pipeline)
      create(:ci_build, name: "rubocop", coverage: 30, pipeline: pipeline, retried: true)
      create(:ci_build, name: "rubocop", coverage: 40, pipeline: pipeline)
      expect(pipeline.coverage).to eq("35.00")
    end

    it "calculates average when there is one build without coverage" do
      FactoryBot.create(:ci_build, pipeline: pipeline)
      expect(pipeline.coverage).to be_nil
    end
  end

  describe '#retryable?' do
    subject { pipeline.retryable? }

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

    it 'includes all predefined variables in a valid order' do
      keys = subject.map { |variable| variable[:key] }

      expect(keys).to eq %w[
        CI_PIPELINE_IID
        CI_PIPELINE_SOURCE
        CI_CONFIG_PATH
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
        CI_BUILD_REF
        CI_BUILD_BEFORE_SHA
        CI_BUILD_REF_NAME
        CI_BUILD_REF_SLUG
      ]
    end

    context 'when source is merge request' do
      let(:pipeline) do
        create(:ci_pipeline, source: :merge_request_event, merge_request: merge_request)
      end

      let(:merge_request) do
        create(:merge_request,
               source_project: project,
               source_branch: 'feature',
               target_project: project,
               target_branch: 'master',
               assignees: assignees,
               milestone: milestone,
               labels: labels)
      end

      let(:assignees) { create_list(:user, 2) }
      let(:milestone) { create(:milestone, project: project) }
      let(:labels) { create_list(:label, 2) }

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
            'CI_MERGE_REQUEST_TARGET_BRANCH_SHA' => pipeline.target_sha.to_s,
            'CI_MERGE_REQUEST_SOURCE_PROJECT_ID' => merge_request.source_project.id.to_s,
            'CI_MERGE_REQUEST_SOURCE_PROJECT_PATH' => merge_request.source_project.full_path,
            'CI_MERGE_REQUEST_SOURCE_PROJECT_URL' => merge_request.source_project.web_url,
            'CI_MERGE_REQUEST_SOURCE_BRANCH_NAME' => merge_request.source_branch.to_s,
            'CI_MERGE_REQUEST_SOURCE_BRANCH_SHA' => pipeline.source_sha.to_s,
            'CI_MERGE_REQUEST_TITLE' => merge_request.title,
            'CI_MERGE_REQUEST_ASSIGNEES' => merge_request.assignee_username_list,
            'CI_MERGE_REQUEST_MILESTONE' => milestone.title,
            'CI_MERGE_REQUEST_LABELS' => labels.map(&:title).join(','),
            'CI_MERGE_REQUEST_EVENT_TYPE' => pipeline.merge_request_event_type.to_s)
      end

      context 'when source project does not exist' do
        before do
          merge_request.update_column(:source_project_id, nil)
        end

        it 'does not expose source project related variables' do
          expect(subject.to_hash.keys).not_to include(
            %w[CI_MERGE_REQUEST_SOURCE_PROJECT_ID
               CI_MERGE_REQUEST_SOURCE_PROJECT_PATH
               CI_MERGE_REQUEST_SOURCE_PROJECT_URL
               CI_MERGE_REQUEST_SOURCE_BRANCH_NAME])
        end
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

    context 'when source is external pull request' do
      let(:pipeline) do
        create(:ci_pipeline, source: :external_pull_request_event, external_pull_request: pull_request)
      end

      let(:pull_request) { create(:external_pull_request, project: project) }

      it 'exposes external pull request pipeline variables' do
        expect(subject.to_hash)
          .to include(
            'CI_EXTERNAL_PULL_REQUEST_IID' => pull_request.pull_request_iid.to_s,
            'CI_EXTERNAL_PULL_REQUEST_SOURCE_BRANCH_SHA' => pull_request.source_sha,
            'CI_EXTERNAL_PULL_REQUEST_TARGET_BRANCH_SHA' => pull_request.target_sha,
            'CI_EXTERNAL_PULL_REQUEST_SOURCE_BRANCH_NAME' => pull_request.source_branch,
            'CI_EXTERNAL_PULL_REQUEST_TARGET_BRANCH_NAME' => pull_request.target_branch
          )
      end
    end
  end

  describe '#protected_ref?' do
    before do
      pipeline.project = create(:project, :repository)
    end

    it 'delegates method to project' do
      expect(pipeline).not_to be_protected_ref
    end
  end

  describe '#legacy_trigger' do
    let(:trigger_request) { create(:ci_trigger_request) }

    before do
      pipeline.trigger_requests << trigger_request
    end

    it 'returns first trigger request' do
      expect(pipeline.legacy_trigger).to eq trigger_request
    end
  end

  describe '#auto_canceled?' do
    subject { pipeline.auto_canceled? }

    context 'when it is canceled' do
      before do
        pipeline.cancel
      end

      context 'when there is auto_canceled_by' do
        before do
          pipeline.update(auto_canceled_by: create(:ci_empty_pipeline))
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

        where(:ci_composite_status) do
          [false, true]
        end

        with_them do
          before do
            stub_feature_flags(ci_composite_status: ci_composite_status)
          end

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
              before do
                create(:commit_status, pipeline: pipeline,
                                      stage: 'build',
                                      name: 'mac',
                                      stage_idx: 0,
                                      status: 'success')

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
      before do
        create(:ci_stage_entity, project: project,
                                 pipeline: pipeline,
                                 name: 'build')
      end

      it 'returns persisted stages' do
        expect(pipeline.stages).not_to be_empty
        expect(pipeline.stages).to all(be_persisted)
      end
    end

    describe '#ordered_stages' do
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

      subject { pipeline.ordered_stages }

      context 'when using legacy stages' do
        before do
          stub_feature_flags(ci_pipeline_persisted_stages: false)
        end

        it 'returns legacy stages in valid order' do
          expect(subject.map(&:name)).to eq %w[build test]
        end
      end

      context 'when using persisted stages' do
        before do
          stub_feature_flags(ci_pipeline_persisted_stages: true)
        end

        context 'when pipelines is not complete' do
          it 'still returns legacy stages' do
            expect(subject).to all(be_a Ci::LegacyStage)
            expect(subject.map(&:name)).to eq %w[build test]
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
  end

  describe 'state machine' do
    let(:current) { Time.now.change(usec: 0) }
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

    describe '#duration', :sidekiq_might_not_need_inline do
      context 'when multiple builds are finished' do
        before do
          travel_to(current + 30) do
            build.run!
            build.success!
            build_b.run!
            build_c.run!
          end

          travel_to(current + 40) do
            build_b.drop!
          end

          travel_to(current + 70) do
            build_c.success!
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
            build.success!
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

          it 'schedules pipeline success worker' do
            expect(PipelineSuccessWorker).to receive(:perform_async).with(pipeline.id)

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

    describe 'auto merge' do
      let(:merge_request) { create(:merge_request, :merge_when_pipeline_succeeds) }

      let(:pipeline) do
        create(:ci_pipeline, :running, project: merge_request.source_project,
                                       ref: merge_request.source_branch,
                                       sha: merge_request.diff_head_sha)
      end

      before do
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

      context 'when auto merge is not enabled in the merge request' do
        let(:merge_request) { create(:merge_request) }

        it 'performs AutoMergeProcessWorker' do
          expect(AutoMergeProcessWorker).not_to receive(:perform_async)

          pipeline.succeed!
        end
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

    context 'when ref is not a tag' do
      before do
        pipeline.tag = false
      end

      it 'return true' do
        is_expected.to be_truthy
      end

      context 'when source is merge request' do
        let(:pipeline) do
          create(:ci_pipeline, source: :merge_request_event, merge_request: merge_request)
        end

        let(:merge_request) do
          create(:merge_request,
                 source_project: project,
                 source_branch: 'feature',
                 target_project: project,
                 target_branch: 'master')
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

      let(:project) { create(:project, :repository) }

      where(:tag, :ref, :result) do
        false | 'master'              | true
        false | 'non-existent-branch' | false
        true  | 'v1.1.0'              | true
        true  | 'non-existent-tag'    | false
      end

      with_them do
        let(:pipeline) do
          create(:ci_empty_pipeline, project: project, tag: tag, ref: ref)
        end

        it "correctly detects ref" do
          expect(pipeline.ref_exists?).to be result
        end
      end
    end

    context 'when repository does not exist' do
      let(:pipeline) do
        create(:ci_empty_pipeline, project: project, ref: 'master')
      end

      it 'always returns false' do
        expect(pipeline.ref_exists?).to eq false
      end
    end
  end

  context 'with non-empty project' do
    let(:project) { create(:project, :repository) }

    let(:pipeline) do
      create(:ci_pipeline,
             project: project,
             ref: project.default_branch,
             sha: project.commit.sha)
    end

    describe '#latest?' do
      context 'with latest sha' do
        it 'returns true' do
          expect(pipeline).to be_latest
        end
      end

      context 'with a branch name as the ref' do
        it 'looks up commit with the full ref name' do
          expect(pipeline.project).to receive(:commit).with('refs/heads/master').and_call_original

          expect(pipeline).to be_latest
        end
      end

      context 'with not latest sha' do
        before do
          pipeline.update(
            sha: project.commit("#{project.default_branch}~1").sha)
        end

        it 'returns false' do
          expect(pipeline).not_to be_latest
        end
      end
    end
  end

  describe '#manual_actions' do
    subject { pipeline.manual_actions }

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
          manual.update(retried: true)
        end

        it 'returns latest one' do
          is_expected.to contain_exactly(manual2)
        end
      end
    end
  end

  describe '#branch_updated?' do
    context 'when pipeline has before SHA' do
      before do
        pipeline.update_column(:before_sha, 'a1b2c3d4')
      end

      it 'runs on a branch update push' do
        expect(pipeline.before_sha).not_to be Gitlab::Git::BLANK_SHA
        expect(pipeline.branch_updated?).to be true
      end
    end

    context 'when pipeline does not have before SHA' do
      before do
        pipeline.update_column(:before_sha, Gitlab::Git::BLANK_SHA)
      end

      it 'does not run on a branch updating push' do
        expect(pipeline.branch_updated?).to be false
      end
    end
  end

  describe '#modified_paths' do
    context 'when old and new revisions are set' do
      let(:project) { create(:project, :repository) }

      before do
        pipeline.update(before_sha: '1234abcd', sha: '2345bcde')
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
        pipeline.update_column(:before_sha, Gitlab::Git::BLANK_SHA)
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
        create(:merge_request,
               source_project: project,
               source_branch: 'feature',
               target_project: project,
               target_branch: 'master')
      end

      it 'returns merge request modified paths' do
        expect(pipeline.modified_paths).to match(merge_request.modified_paths)
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
  end

  describe '#number_of_warnings' do
    it 'returns the number of warnings' do
      create(:ci_build, :allowed_to_fail, :failed, pipeline: pipeline, name: 'rubocop')

      expect(pipeline.number_of_warnings).to eq(1)
    end

    it 'supports eager loading of the number of warnings' do
      pipeline2 = create(:ci_empty_pipeline, status: :created, project: project)

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

  shared_context 'with some outdated pipelines' do
    before do
      create_pipeline(:canceled, 'ref', 'A', project)
      create_pipeline(:success, 'ref', 'A', project)
      create_pipeline(:failed, 'ref', 'B', project)
      create_pipeline(:skipped, 'feature', 'C', project)
    end

    def create_pipeline(status, ref, sha, project)
      create(
        :ci_empty_pipeline,
        status: status,
        ref: ref,
        sha: sha,
        project: project
      )
    end
  end

  describe '.newest_first' do
    include_context 'with some outdated pipelines'

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
    include_context 'with some outdated pipelines'

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
    include_context 'with some outdated pipelines'

    let!(:latest_successful_pipeline) do
      create_pipeline(:success, 'ref', 'D', project)
    end

    it 'returns the latest successful pipeline' do
      expect(described_class.latest_successful_for_ref('ref'))
        .to eq(latest_successful_pipeline)
    end
  end

  describe '.latest_successful_for_sha' do
    include_context 'with some outdated pipelines'

    let!(:latest_successful_pipeline) do
      create_pipeline(:success, 'ref', 'awesomesha', project)
    end

    it 'returns the latest successful pipeline' do
      expect(described_class.latest_successful_for_sha('awesomesha'))
        .to eq(latest_successful_pipeline)
    end
  end

  describe '.latest_successful_for_refs' do
    include_context 'with some outdated pipelines'

    let!(:latest_successful_pipeline1) do
      create_pipeline(:success, 'ref1', 'D', project)
    end

    let!(:latest_successful_pipeline2) do
      create_pipeline(:success, 'ref2', 'D', project)
    end

    it 'returns the latest successful pipeline for both refs' do
      refs = %w(ref1 ref2 ref3)

      expect(described_class.latest_successful_for_refs(refs)).to eq({ 'ref1' => latest_successful_pipeline1, 'ref2' => latest_successful_pipeline2 })
    end
  end

  describe '.latest_pipeline_per_commit' do
    let(:project) { create(:project) }

    let!(:commit_123_ref_master) do
      create(
        :ci_empty_pipeline,
        status: 'success',
        ref: 'master',
        sha: '123',
        project: project
      )
    end
    let!(:commit_123_ref_develop) do
      create(
        :ci_empty_pipeline,
        status: 'success',
        ref: 'develop',
        sha: '123',
        project: project
      )
    end
    let!(:commit_456_ref_test) do
      create(
        :ci_empty_pipeline,
        status: 'success',
        ref: 'test',
        sha: '456',
        project: project
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

  describe '.internal_sources' do
    subject { described_class.internal_sources }

    it { is_expected.to be_an(Array) }
  end

  describe '.bridgeable_statuses' do
    subject { described_class.bridgeable_statuses }

    it { is_expected.to be_an(Array) }
    it { is_expected.not_to include('created', 'preparing', 'pending') }
  end

  describe '#status', :sidekiq_might_not_need_inline do
    let(:build) do
      create(:ci_build, :created, pipeline: pipeline, name: 'test')
    end

    subject { pipeline.reload.status }

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
        build.run
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

  describe '#update_status' do
    context 'when pipeline is empty' do
      it 'updates does not change pipeline status' do
        expect(pipeline.statuses.latest.slow_composite_status).to be_nil

        expect { pipeline.update_status }
          .to change { pipeline.reload.status }
          .from('created')
          .to('skipped')
      end
    end

    context 'when updating status to pending' do
      before do
        create(:ci_build, pipeline: pipeline, status: :running)
      end

      it 'updates pipeline status to running' do
        expect { pipeline.update_status }
          .to change { pipeline.reload.status }
          .from('created')
          .to('running')
      end
    end

    context 'when updating status to scheduled' do
      before do
        create(:ci_build, pipeline: pipeline, status: :scheduled)
      end

      it 'updates pipeline status to scheduled' do
        expect { pipeline.update_status }
          .to change { pipeline.reload.status }
          .from('created')
          .to('scheduled')
      end
    end

    context 'when statuses status was not recognized' do
      before do
        allow(pipeline)
          .to receive(:latest_builds_status)
          .and_return(:unknown)
      end

      it 'raises an exception' do
        expect { pipeline.update_status }
          .to raise_error(HasStatus::UnknownStatusError)
      end
    end
  end

  describe '#detailed_status' do
    subject { pipeline.detailed_status(user) }

    context 'when pipeline is created' do
      let(:pipeline) { create(:ci_pipeline, status: :created) }

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
    let(:latest_status) { pipeline.statuses.pluck(:status) }

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
  end

  describe '#retry_failed' do
    let(:latest_status) { pipeline.statuses.latest.pluck(:status) }

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
    let!(:build_a) { create_build('a', 0) }
    let!(:build_b) { create_build('b', 0) }

    let!(:hook) do
      create(:project_hook, project: project, pipeline_events: enabled)
    end

    before do
      WebHookWorker.drain
    end

    context 'with pipeline hooks enabled' do
      let(:enabled) { true }

      before do
        stub_full_request(hook.url, method: :post)
      end

      context 'with multiple builds', :sidekiq_might_not_need_inline do
        context 'when build is queued' do
          before do
            build_a.enqueue
            build_b.enqueue
          end

          it 'receives a pending event once' do
            expect(WebMock).to have_requested_pipeline_hook('pending').once
          end
        end

        context 'when build is run' do
          before do
            build_a.enqueue
            build_a.run
            build_b.enqueue
            build_b.run
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
            json_body = JSON.parse(req.body)
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
    end

    def create_build(name, stage_idx)
      create(:ci_build,
             :created,
             pipeline: pipeline,
             name: name,
             stage_idx: stage_idx)
    end
  end

  describe "#merge_requests_as_head_pipeline" do
    let(:project) { create(:project) }
    let(:pipeline) { create(:ci_empty_pipeline, status: 'created', project: project, ref: 'master', sha: 'a288a022a53a5a944fae87bcec6efc87b7061808') }

    it "returns merge requests whose `diff_head_sha` matches the pipeline's SHA" do
      allow_next_instance_of(MergeRequest) do |instance|
        allow(instance).to receive(:diff_head_sha) { 'a288a022a53a5a944fae87bcec6efc87b7061808' }
      end
      merge_request = create(:merge_request, source_project: project, head_pipeline: pipeline, source_branch: pipeline.ref)

      expect(pipeline.merge_requests_as_head_pipeline).to eq([merge_request])
    end

    it "doesn't return merge requests whose source branch doesn't match the pipeline's ref" do
      create(:merge_request, source_project: project, source_branch: 'feature', target_branch: 'master')

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

  describe "#all_merge_requests" do
    let(:project) { create(:project) }

    shared_examples 'a method that returns all merge requests for a given pipeline' do
      let(:pipeline) { create(:ci_empty_pipeline, status: 'created', project: pipeline_project, ref: 'master') }

      it "returns all merge requests having the same source branch" do
        merge_request = create(:merge_request, source_project: pipeline_project, target_project: project, source_branch: pipeline.ref)

        expect(pipeline.all_merge_requests).to eq([merge_request])
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

  describe '#stuck?' do
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

  describe '#has_yaml_errors?' do
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
    let(:project) { create(:project, :repository) }

    let(:pipeline) do
      create(:ci_pipeline,
             project: project,
             sha: project.commit('master').sha,
             user: project.owner)
    end

    before do
      project.add_developer(pipeline.user)

      pipeline.user.global_notification_setting
        .update(level: 'custom', failed_pipeline: true, success_pipeline: true)

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
      before do
        perform_enqueued_jobs do
          pipeline.succeed
        end
      end

      it_behaves_like 'sending a notification'
    end

    context 'with failed pipeline' do
      before do
        perform_enqueued_jobs do
          create(:ci_build, :failed, pipeline: pipeline)
          create(:generic_commit_status, :failed, pipeline: pipeline)

          pipeline.drop
        end
      end

      it_behaves_like 'sending a notification'
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

  describe '#latest_builds_with_artifacts' do
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

  describe '#has_reports?' do
    subject { pipeline.has_reports?(Ci::JobArtifact.test_reports) }

    context 'when pipeline has builds with test reports' do
      before do
        create(:ci_build, :test_reports, pipeline: pipeline, project: project)
      end

      context 'when pipeline status is running' do
        let(:pipeline) { create(:ci_pipeline, :running, project: project) }

        it { is_expected.to be_falsey }
      end

      context 'when pipeline status is success' do
        let(:pipeline) { create(:ci_pipeline, :success, project: project) }

        it { is_expected.to be_truthy }
      end
    end

    context 'when pipeline does not have builds with test reports' do
      before do
        create(:ci_build, :artifacts, pipeline: pipeline, project: project)
      end

      let(:pipeline) { create(:ci_pipeline, :success, project: project) }

      it { is_expected.to be_falsey }
    end

    context 'when retried build has test reports' do
      before do
        create(:ci_build, :retried, :test_reports, pipeline: pipeline, project: project)
      end

      let(:pipeline) { create(:ci_pipeline, :success, project: project) }

      it { is_expected.to be_falsey }
    end
  end

  describe '#test_reports' do
    subject { pipeline.test_reports }

    context 'when pipeline has multiple builds with test reports' do
      let!(:build_rspec) { create(:ci_build, :success, name: 'rspec', pipeline: pipeline, project: project) }
      let!(:build_java) { create(:ci_build, :success, name: 'java', pipeline: pipeline, project: project) }

      before do
        create(:ci_job_artifact, :junit, job: build_rspec, project: project)
        create(:ci_job_artifact, :junit_with_ant, job: build_java, project: project)
      end

      it 'returns test reports with collected data' do
        expect(subject.total_count).to be(7)
        expect(subject.success_count).to be(5)
        expect(subject.failed_count).to be(2)
      end

      context 'when builds are retried' do
        let!(:build_rspec) { create(:ci_build, :retried, :success, name: 'rspec', pipeline: pipeline, project: project) }
        let!(:build_java) { create(:ci_build, :retried, :success, name: 'java', pipeline: pipeline, project: project) }

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

  describe '#total_size' do
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
    end
  end

  describe '#default_branch?' do
    let(:default_branch) { 'master'}

    subject { pipeline.default_branch? }

    before do
      allow(project).to receive(:default_branch).and_return(default_branch)
    end

    context 'when pipeline ref is the default branch of the project' do
      let(:pipeline) do
        build(:ci_empty_pipeline, status: :created, project: project, ref: default_branch)
      end

      it "returns true" do
        expect(subject).to be_truthy
      end
    end

    context 'when pipeline ref is not the default branch of the project' do
      let(:pipeline) do
        build(:ci_empty_pipeline, status: :created, project: project, ref: 'another_branch')
      end

      it "returns false" do
        expect(subject).to be_falsey
      end
    end
  end

  describe '#find_stage_by_name' do
    let(:pipeline) { create(:ci_pipeline) }
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

  describe '#error_messages' do
    subject { pipeline.error_messages }

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
end
