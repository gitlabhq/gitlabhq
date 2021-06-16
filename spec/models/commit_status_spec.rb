# frozen_string_literal: true

require 'spec_helper'

RSpec.describe CommitStatus do
  let_it_be(:project) { create(:project, :repository) }

  let_it_be(:pipeline) do
    create(:ci_pipeline, project: project, sha: project.commit.id)
  end

  let(:commit_status) { create_status(stage: 'test') }

  def create_status(**opts)
    create(:commit_status, pipeline: pipeline, **opts)
  end

  it_behaves_like 'having unique enum values'

  it { is_expected.to belong_to(:pipeline) }
  it { is_expected.to belong_to(:user) }
  it { is_expected.to belong_to(:project) }
  it { is_expected.to belong_to(:auto_canceled_by) }

  it { is_expected.to validate_presence_of(:name) }
  it { is_expected.to validate_inclusion_of(:status).in_array(%w(pending running failed success canceled)) }

  it { is_expected.to delegate_method(:sha).to(:pipeline) }
  it { is_expected.to delegate_method(:short_sha).to(:pipeline) }

  it { is_expected.to respond_to :success? }
  it { is_expected.to respond_to :failed? }
  it { is_expected.to respond_to :running? }
  it { is_expected.to respond_to :pending? }

  describe '#author' do
    subject { commit_status.author }

    before do
      commit_status.author = User.new
    end

    it { is_expected.to eq(commit_status.user) }
  end

  describe 'status state machine' do
    let!(:commit_status) { create(:commit_status, :running, project: project) }

    it 'invalidates the cache after a transition' do
      expect(ExpireJobCacheWorker).to receive(:perform_async).with(commit_status.id)

      commit_status.success!
    end

    describe 'transitioning to running' do
      let(:commit_status) { create(:commit_status, :pending, started_at: nil) }

      it 'records the started at time' do
        commit_status.run!

        expect(commit_status.started_at).to be_present
      end
    end

    describe 'transitioning to created from skipped or manual' do
      let(:commit_status) { create(:commit_status, :skipped) }

      it 'does not update user without parameter' do
        commit_status.process!

        expect { commit_status.process }.not_to change { commit_status.reload.user }
      end

      it 'updates user with user parameter' do
        new_user = create(:user)

        expect { commit_status.process(new_user) }.to change { commit_status.reload.user }.to(new_user)
      end
    end
  end

  describe '.updated_before' do
    let!(:lookback) { 5.days.ago }
    let!(:timeout) { 1.day.ago }
    let!(:before_lookback) { lookback - 1.hour }
    let!(:after_lookback) { lookback + 1.hour }
    let!(:before_timeout) { timeout - 1.hour }
    let!(:after_timeout) { timeout + 1.hour }

    subject { described_class.updated_before(lookback: lookback, timeout: timeout) }

    def create_build_with_set_timestamps(created_at:, updated_at:)
      travel_to(created_at) { create(:ci_build, created_at: Time.current) }.tap do |build|
        travel_to(updated_at) { build.update!(status: :failed) }
      end
    end

    it 'finds builds updated and created in the window between lookback and timeout' do
      build_in_lookback_timeout_window = create_build_with_set_timestamps(created_at: after_lookback, updated_at: before_timeout)
      build_outside_lookback_window = create_build_with_set_timestamps(created_at: before_lookback, updated_at: before_timeout)
      build_outside_timeout_window = create_build_with_set_timestamps(created_at: after_lookback, updated_at: after_timeout)

      expect(subject).to contain_exactly(build_in_lookback_timeout_window)
      expect(subject).not_to include(build_outside_lookback_window, build_outside_timeout_window)
    end
  end

  describe '#processed' do
    subject { commit_status.processed }

    context 'status is latest' do
      before do
        commit_status.update!(retried: false, status: :pending)
      end

      it { is_expected.to be_falsey }
    end

    context 'status is retried' do
      before do
        commit_status.update!(retried: true, status: :pending)
      end

      it { is_expected.to be_truthy }
    end

    it "processed state is always persisted" do
      commit_status.update!(retried: false, status: :pending)

      # another process does mark object as processed
      CommitStatus.find(commit_status.id).update_column(:processed, true)

      # subsequent status transitions on the same instance
      # always saves processed=false to DB even though
      # the current value did not change
      commit_status.update!(retried: false, status: :running)

      # we look at a persisted state in DB
      expect(CommitStatus.find(commit_status.id).processed).to eq(false)
    end
  end

  describe '#started?' do
    subject { commit_status.started? }

    context 'without started_at' do
      before do
        commit_status.started_at = nil
      end

      it { is_expected.to be_falsey }
    end

    %w[running success failed].each do |status|
      context "if commit status is #{status}" do
        before do
          commit_status.status = status
        end

        it { is_expected.to be_truthy }
      end
    end

    %w[pending canceled].each do |status|
      context "if commit status is #{status}" do
        before do
          commit_status.status = status
        end

        it { is_expected.to be_falsey }
      end
    end
  end

  describe '#active?' do
    subject { commit_status.active? }

    %w[pending running].each do |state|
      context "if commit_status.status is #{state}" do
        before do
          commit_status.status = state
        end

        it { is_expected.to be_truthy }
      end
    end

    %w[success failed canceled].each do |state|
      context "if commit_status.status is #{state}" do
        before do
          commit_status.status = state
        end

        it { is_expected.to be_falsey }
      end
    end
  end

  describe '#complete?' do
    subject { commit_status.complete? }

    %w[success failed canceled].each do |state|
      context "if commit_status.status is #{state}" do
        before do
          commit_status.status = state
        end

        it { is_expected.to be_truthy }
      end
    end

    %w[pending running].each do |state|
      context "if commit_status.status is #{state}" do
        before do
          commit_status.status = state
        end

        it { is_expected.to be_falsey }
      end
    end
  end

  describe '#cancel' do
    subject { job.cancel }

    context 'when status is scheduled' do
      let(:job) { build(:commit_status, :scheduled) }

      it 'updates the status' do
        subject

        expect(job).to be_canceled
      end
    end
  end

  describe '#auto_canceled?' do
    subject { commit_status.auto_canceled? }

    context 'when it is canceled' do
      before do
        commit_status.update!(status: 'canceled')
      end

      context 'when there is auto_canceled_by' do
        before do
          commit_status.update!(auto_canceled_by: create(:ci_empty_pipeline))
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
    end
  end

  describe '#duration' do
    subject { commit_status.duration }

    it { is_expected.to eq(120.0) }

    context 'if the building process has not started yet' do
      before do
        commit_status.started_at = nil
        commit_status.finished_at = nil
      end

      it { is_expected.to be_nil }
    end

    context 'if the building process has started' do
      before do
        commit_status.started_at = Time.current - 1.minute
        commit_status.finished_at = nil
      end

      it { is_expected.to be_a(Float) }
      it { is_expected.to be > 0.0 }
    end
  end

  describe '#queued_duration' do
    subject { commit_status.queued_duration }

    around do |example|
      travel_to(Time.current) { example.run }
    end

    context 'when created, then enqueued, then started' do
      before do
        commit_status.queued_at = 30.seconds.ago
        commit_status.started_at = 25.seconds.ago
      end

      it { is_expected.to eq(5.0) }
    end

    context 'when created but not yet enqueued' do
      before do
        commit_status.queued_at = nil
      end

      it { is_expected.to be_nil }
    end

    context 'when enqueued, but not started' do
      before do
        commit_status.queued_at = Time.current - 1.minute
        commit_status.started_at = nil
      end

      it { is_expected.to eq(1.minute) }
    end
  end

  describe '.latest' do
    subject { described_class.latest.order(:id) }

    let(:statuses) do
      [create_status(name: 'aa', ref: 'bb', status: 'running', retried: true),
       create_status(name: 'cc', ref: 'cc', status: 'pending', retried: true),
       create_status(name: 'aa', ref: 'cc', status: 'success', retried: true),
       create_status(name: 'cc', ref: 'bb', status: 'success'),
       create_status(name: 'aa', ref: 'bb', status: 'success')]
    end

    it 'returns unique statuses' do
      is_expected.to eq(statuses.values_at(3, 4))
    end
  end

  describe '.retried' do
    subject { described_class.retried.order(:id) }

    let(:statuses) do
      [create_status(name: 'aa', ref: 'bb', status: 'running', retried: true),
       create_status(name: 'cc', ref: 'cc', status: 'pending', retried: true),
       create_status(name: 'aa', ref: 'cc', status: 'success', retried: true),
       create_status(name: 'cc', ref: 'bb', status: 'success'),
       create_status(name: 'aa', ref: 'bb', status: 'success')]
    end

    it 'returns unique statuses' do
      is_expected.to contain_exactly(*statuses.values_at(0, 1, 2))
    end
  end

  describe '.running_or_pending' do
    subject { described_class.running_or_pending.order(:id) }

    let(:statuses) do
      [create_status(name: 'aa', ref: 'bb', status: 'running'),
       create_status(name: 'cc', ref: 'cc', status: 'pending'),
       create_status(name: 'aa', ref: nil, status: 'success'),
       create_status(name: 'dd', ref: nil, status: 'failed'),
       create_status(name: 'ee', ref: nil, status: 'canceled')]
    end

    it 'returns statuses that are running or pending' do
      is_expected.to contain_exactly(*statuses.values_at(0, 1))
    end
  end

  describe '.after_stage' do
    subject { described_class.after_stage(0) }

    let(:statuses) do
      [create_status(name: 'aa', stage_idx: 0),
       create_status(name: 'cc', stage_idx: 1),
       create_status(name: 'aa', stage_idx: 2)]
    end

    it 'returns statuses from second and third stage' do
      is_expected.to eq(statuses.values_at(1, 2))
    end
  end

  describe '.exclude_ignored' do
    subject { described_class.exclude_ignored.order(:id) }

    let(:statuses) do
      [create_status(when: 'manual', status: 'skipped'),
       create_status(when: 'manual', status: 'success'),
       create_status(when: 'manual', status: 'failed'),
       create_status(when: 'on_failure', status: 'skipped'),
       create_status(when: 'on_failure', status: 'success'),
       create_status(when: 'on_failure', status: 'failed'),
       create_status(allow_failure: true, status: 'success'),
       create_status(allow_failure: true, status: 'failed'),
       create_status(allow_failure: false, status: 'success'),
       create_status(allow_failure: false, status: 'failed'),
       create_status(allow_failure: true, status: 'manual'),
       create_status(allow_failure: false, status: 'manual')]
    end

    it 'returns statuses without what we want to ignore' do
      is_expected.to eq(statuses.values_at(0, 1, 2, 3, 4, 5, 6, 8, 9, 11))
    end
  end

  describe '.failed_but_allowed' do
    subject { described_class.failed_but_allowed.order(:id) }

    let(:statuses) do
      [create_status(allow_failure: true, status: 'success'),
       create_status(allow_failure: true, status: 'failed'),
       create_status(allow_failure: false, status: 'success'),
       create_status(allow_failure: false, status: 'failed'),
       create_status(allow_failure: true, status: 'canceled'),
       create_status(allow_failure: false, status: 'canceled'),
       create_status(allow_failure: true, status: 'manual'),
       create_status(allow_failure: false, status: 'manual')]
    end

    it 'returns statuses without what we want to ignore' do
      is_expected.to eq(statuses.values_at(1, 4))
    end
  end

  describe '.for_ref' do
    subject { described_class.for_ref('bb').order(:id) }

    let(:statuses) do
      [create_status(ref: 'aa'),
       create_status(ref: 'bb'),
       create_status(ref: 'cc')]
    end

    it 'returns statuses with the specified ref' do
      is_expected.to eq(statuses.values_at(1))
    end
  end

  describe '.by_name' do
    subject { described_class.by_name('bb').order(:id) }

    let(:statuses) do
      [create_status(name: 'aa'),
       create_status(name: 'bb'),
       create_status(name: 'cc')]
    end

    it 'returns statuses with the specified name' do
      is_expected.to eq(statuses.values_at(1))
    end
  end

  describe '.for_project_paths' do
    subject do
      described_class
        .for_project_paths(paths)
        .order(:id)
    end

    context 'with a single path' do
      let(:other_project) { create(:project, :repository) }
      let(:paths) { other_project.full_path }

      let(:other_pipeline) do
        create(:ci_pipeline, project: other_project, sha: other_project.commit.id)
      end

      let(:statuses) do
        [create_status(pipeline: pipeline),
         create_status(pipeline: other_pipeline)]
      end

      it 'returns statuses for other_project' do
        is_expected.to eq(statuses.values_at(1))
      end
    end

    context 'with array of paths' do
      let(:paths) { [project.full_path] }

      let(:statuses) do
        [create_status(pipeline: pipeline)]
      end

      it 'returns statuses for project' do
        is_expected.to eq(statuses.values_at(0))
      end
    end
  end

  describe '.status' do
    context 'when there are multiple statuses present' do
      before do
        create_status(status: 'running')
        create_status(status: 'success')
        create_status(allow_failure: true, status: 'failed')
      end

      it 'returns a correct compound status' do
        expect(described_class.all.composite_status).to eq 'running'
      end
    end

    context 'when there are only allowed to fail commit statuses present' do
      before do
        create_status(allow_failure: true, status: 'failed')
      end

      it 'returns status that indicates success' do
        expect(described_class.all.composite_status).to eq 'success'
      end
    end

    context 'when using a scope to select latest statuses' do
      before do
        create_status(name: 'test', retried: true, status: 'failed')
        create_status(allow_failure: true, name: 'test', status: 'failed')
      end

      it 'returns status according to the scope' do
        expect(described_class.latest.composite_status).to eq 'success'
      end
    end
  end

  describe '.match_id_and_lock_version' do
    let(:status_1) { create_status(lock_version: 1) }
    let(:status_2) { create_status(lock_version: 2) }

    it 'returns statuses that match the given id and lock versions' do
      params = [
        { id: status_1.id, lock_version: 1 },
        { id: status_2.id, lock_version: 3 }
      ]
      expect(described_class.match_id_and_lock_version(params)).to contain_exactly(status_1)
    end
  end

  describe '#before_sha' do
    subject { commit_status.before_sha }

    context 'when no before_sha is set for pipeline' do
      before do
        pipeline.before_sha = nil
      end

      it 'returns blank sha' do
        is_expected.to eq(Gitlab::Git::BLANK_SHA)
      end
    end

    context 'for before_sha set for pipeline' do
      let(:value) { '1234' }

      before do
        pipeline.before_sha = value
      end

      it 'returns the set value' do
        is_expected.to eq(value)
      end
    end
  end

  describe '#commit' do
    it 'returns commit pipeline has been created for' do
      expect(commit_status.commit).to eq project.commit
    end
  end

  describe '#group_name' do
    using RSpec::Parameterized::TableSyntax

    let(:commit_status) do
      build(:commit_status, pipeline: pipeline, stage: 'test')
    end

    subject { commit_status.group_name }

    where(:name, :group_name) do
      'rspec1'                                              | 'rspec1'
      'rspec1 0 1'                                          | 'rspec1'
      'rspec1 0/2'                                          | 'rspec1'
      'rspec:windows'                                       | 'rspec:windows'
      'rspec:windows 0'                                     | 'rspec:windows 0'
      'rspec:windows 0 2/2'                                 | 'rspec:windows 0'
      'rspec:windows 0 test'                                | 'rspec:windows 0 test'
      'rspec:windows 0 test 2/2'                            | 'rspec:windows 0 test'
      'rspec:windows 0 1 2/2'                               | 'rspec:windows'
      'rspec:windows 0 1 [aws] 2/2'                         | 'rspec:windows'
      'rspec:windows 0 1 name [aws] 2/2'                    | 'rspec:windows 0 1 name'
      'rspec:windows 0 1 name'                              | 'rspec:windows 0 1 name'
      'rspec:windows 0 1 name 1/2'                          | 'rspec:windows 0 1 name'
      'rspec:windows 0/1'                                   | 'rspec:windows'
      'rspec:windows 0/1 name'                              | 'rspec:windows 0/1 name'
      'rspec:windows 0/1 name 1/2'                          | 'rspec:windows 0/1 name'
      'rspec:windows 0:1'                                   | 'rspec:windows'
      'rspec:windows 0:1 name'                              | 'rspec:windows 0:1 name'
      'rspec:windows 10000 20000'                           | 'rspec:windows'
      'rspec:windows 0 : / 1'                               | 'rspec:windows'
      'rspec:windows 0 : / 1 name'                          | 'rspec:windows 0 : / 1 name'
      '0 1 name ruby'                                       | '0 1 name ruby'
      '0 :/ 1 name ruby'                                    | '0 :/ 1 name ruby'
      'rspec: [aws]'                                        | 'rspec'
      'rspec: [aws] 0/1'                                    | 'rspec'
      'rspec: [aws, max memory]'                            | 'rspec'
      'rspec:linux: [aws, max memory, data]'                | 'rspec:linux'
      'rspec: [inception: [something, other thing], value]' | 'rspec'
      'rspec:windows 0/1: [name, other]'                    | 'rspec:windows'
      'rspec:windows: [name, other] 0/1'                    | 'rspec:windows'
      'rspec:windows: [name, 0/1] 0/1'                      | 'rspec:windows'
      'rspec:windows: [0/1, name]'                          | 'rspec:windows'
      'rspec:windows: [, ]'                                 | 'rspec:windows'
      'rspec:windows: [name]'                               | 'rspec:windows'
      'rspec:windows: [name,other]'                         | 'rspec:windows'
    end

    with_them do
      it "#{params[:name]} puts in #{params[:group_name]}" do
        commit_status.name = name

        is_expected.to eq(group_name)
      end
    end
  end

  describe '#detailed_status' do
    let(:user) { create(:user) }

    it 'returns a detailed status' do
      expect(commit_status.detailed_status(user))
        .to be_a Gitlab::Ci::Status::Success
    end
  end

  describe '#sortable_name' do
    tests = {
      'karma' => ['karma'],
      'karma 0 20' => ['karma ', 0, ' ', 20],
      'karma 10 20' => ['karma ', 10, ' ', 20],
      'karma 50:100' => ['karma ', 50, ':', 100],
      'karma 1.10' => ['karma ', 1, '.', 10],
      'karma 1.5.1' => ['karma ', 1, '.', 5, '.', 1],
      'karma 1 a' => ['karma ', 1, ' a']
    }

    tests.each do |name, sortable_name|
      it "'#{name}' sorts as '#{sortable_name}'" do
        commit_status.name = name
        expect(commit_status.sortable_name).to eq(sortable_name)
      end
    end
  end

  describe '#locking_enabled?' do
    before do
      commit_status.lock_version = 100
    end

    subject { commit_status.locking_enabled? }

    context "when changing status" do
      before do
        commit_status.status = "running"
      end

      it "lock" do
        is_expected.to be_truthy
      end

      it "raise exception when trying to update" do
        expect { commit_status.save! }.to raise_error(ActiveRecord::StaleObjectError)
      end
    end

    context "when changing description" do
      before do
        commit_status.description = "test"
      end

      it "do not lock" do
        is_expected.to be_falsey
      end

      it "save correctly" do
        expect(commit_status.save).to be true
      end
    end
  end

  describe '#drop' do
    let(:commit_status) { create(:commit_status, :created) }
    let(:counter) { Gitlab::Metrics.counter(:gitlab_ci_job_failure_reasons, 'desc') }
    let(:failure_reason) { reason.to_s }

    subject do
      commit_status.drop!(reason)
      commit_status
    end

    shared_examples 'incrementing failure reason counter' do
      it 'increments the counter with the failure_reason' do
        expect { subject }.to change { counter.get(reason: failure_reason) }.by(1)
      end
    end

    context 'when failure_reason is nil' do
      let(:reason) { }
      let(:failure_reason) { 'unknown_failure' }

      it { is_expected.to be_unknown_failure }

      it_behaves_like 'incrementing failure reason counter'
    end

    context 'when failure_reason is script_failure' do
      let(:reason) { :script_failure }

      it { is_expected.to be_script_failure }

      it_behaves_like 'incrementing failure reason counter'
    end

    context 'when failure_reason is unmet_prerequisites' do
      let(:reason) { :unmet_prerequisites }

      it { is_expected.to be_unmet_prerequisites }

      it_behaves_like 'incrementing failure reason counter'
    end
  end

  describe 'ensure stage assignment' do
    context 'when commit status has a stage_id assigned' do
      let!(:stage) do
        create(:ci_stage_entity, project: project, pipeline: pipeline)
      end

      let(:commit_status) do
        create(:commit_status, stage_id: stage.id, name: 'rspec', stage: 'test')
      end

      it 'does not create a new stage' do
        expect { commit_status }.not_to change { Ci::Stage.count }
        expect(commit_status.stage_id).to eq stage.id
      end
    end

    context 'when commit status does not have a stage_id assigned' do
      let(:commit_status) do
        create(:commit_status, name: 'rspec', stage: 'test', status: :success)
      end

      let(:stage) { Ci::Stage.first }

      it 'creates a new stage', :sidekiq_might_not_need_inline do
        expect { commit_status }.to change { Ci::Stage.count }.by(1)

        expect(stage.name).to eq 'test'
        expect(stage.project).to eq commit_status.project
        expect(stage.pipeline).to eq commit_status.pipeline
        expect(stage.status).to eq commit_status.status
        expect(commit_status.stage_id).to eq stage.id
      end
    end

    context 'when commit status does not have stage but it exists' do
      let!(:stage) do
        create(:ci_stage_entity, project: project,
                                 pipeline: pipeline,
                                 name: 'test')
      end

      let(:commit_status) do
        create(:commit_status, project: project,
                               pipeline: pipeline,
                               name: 'rspec',
                               stage: 'test',
                               status: :success)
      end

      it 'uses existing stage', :sidekiq_might_not_need_inline do
        expect { commit_status }.not_to change { Ci::Stage.count }

        expect(commit_status.stage_id).to eq stage.id
        expect(stage.reload.status).to eq commit_status.status
      end
    end

    context 'when commit status is being imported' do
      let(:commit_status) do
        create(:commit_status, name: 'rspec', stage: 'test', importing: true)
      end

      it 'does not create a new stage' do
        expect { commit_status }.not_to change { Ci::Stage.count }
        expect(commit_status.stage_id).not_to be_present
      end
    end
  end

  describe '#all_met_to_become_pending?' do
    subject { commit_status.all_met_to_become_pending? }

    let(:commit_status) { create(:commit_status) }

    it { is_expected.to eq(true) }
  end

  describe '#enqueue' do
    let!(:current_time) { Time.zone.local(2018, 4, 5, 14, 0, 0) }

    before do
      allow(Time).to receive(:now).and_return(current_time)
    end

    shared_examples 'commit status enqueued' do
      it 'sets queued_at value when enqueued' do
        expect { commit_status.enqueue }.to change { commit_status.reload.queued_at }.from(nil).to(current_time)
      end
    end

    context 'when initial state is :created' do
      let(:commit_status) { create(:commit_status, :created) }

      it_behaves_like 'commit status enqueued'
    end

    context 'when initial state is :skipped' do
      let(:commit_status) { create(:commit_status, :skipped) }

      it_behaves_like 'commit status enqueued'
    end

    context 'when initial state is :manual' do
      let(:commit_status) { create(:commit_status, :manual) }

      it_behaves_like 'commit status enqueued'
    end

    context 'when initial state is :scheduled' do
      let(:commit_status) { create(:commit_status, :scheduled) }

      it_behaves_like 'commit status enqueued'
    end
  end

  describe '#present' do
    subject { commit_status.present }

    it { is_expected.to be_a(CommitStatusPresenter) }
  end

  describe '#recoverable?' do
    using RSpec::Parameterized::TableSyntax

    let(:commit_status) { create(:commit_status, :pending) }

    subject(:recoverable?) { commit_status.recoverable? }

    context 'when commit status is failed' do
      before do
        commit_status.drop!
      end

      where(:failure_reason, :recoverable) do
        :script_failure | false
        :missing_dependency_failure | false
        :archived_failure | false
        :scheduler_failure | false
        :data_integrity_failure | false
        :unknown_failure | true
        :api_failure | true
        :stuck_or_timeout_failure | true
        :runner_system_failure | true
      end

      with_them do
        context "when failure reason is #{params[:failure_reason]}" do
          before do
            commit_status.update_attribute(:failure_reason, failure_reason)
          end

          it { is_expected.to eq(recoverable) }
        end
      end
    end

    context 'when commit status is not failed' do
      before do
        commit_status.success!
      end

      it { is_expected.to eq(false) }
    end
  end

  describe '#update_older_statuses_retried!' do
    let!(:build_old) { create_status(name: 'build') }
    let!(:build_new) { create_status(name: 'build') }
    let!(:test) { create_status(name: 'test') }
    let!(:build_from_other_pipeline) do
      new_pipeline = create(:ci_pipeline, project: project, sha: project.commit.id)
      create_status(name: 'build', pipeline: new_pipeline)
    end

    it "updates 'retried' and 'status' columns of the latest status with the same name in the same pipeline" do
      build_new.update_older_statuses_retried!

      expect(build_new.reload).to have_attributes(retried: false, processed: false)
      expect(build_old.reload).to have_attributes(retried: true, processed: true)
      expect(test.reload).to have_attributes(retried: false, processed: false)
      expect(build_from_other_pipeline.reload).to have_attributes(retried: false, processed: false)
    end
  end
end
