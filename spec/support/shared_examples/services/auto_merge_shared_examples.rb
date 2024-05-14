# frozen_string_literal: true

RSpec.shared_context 'for auto_merge strategy context' do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, :repository, maintainers: user) }

  let(:mr_merge_if_green_enabled) do
    create(:merge_request,
      merge_when_pipeline_succeeds: true,
      merge_user: user,
      source_branch: 'master', target_branch: 'feature',
      source_project: project, target_project: project,
      state: 'opened')
  end

  let(:pipeline) { create(:ci_pipeline, ref: mr_merge_if_green_enabled.source_branch, project: project) }

  let(:service) { described_class.new(project, user, commit_message: 'Awesome message') }

  before do
    allow(MergeWorker).to receive(:with_status).and_return(MergeWorker)
  end
end

RSpec.shared_examples 'auto_merge service #execute' do
  let(:merge_request) do
    create(:merge_request, target_project: project, source_project: project,
      source_branch: 'feature', target_branch: 'master')
  end

  context 'when first time enabling' do
    before do
      allow(merge_request)
        .to receive_messages(head_pipeline: pipeline, diff_head_pipeline: pipeline)
      allow(MailScheduler::NotificationServiceWorker).to receive(:perform_async)

      service.execute(merge_request)
    end

    it 'sets the params, merge_user, and flag' do
      expect(merge_request).to be_valid
      expect(merge_request.merge_when_pipeline_succeeds).to be_truthy
      expect(merge_request.merge_params).to include 'commit_message' => 'Awesome message'
      expect(merge_request.merge_user).to be user
      expect(merge_request.auto_merge_strategy).to eq auto_merge_strategy
    end

    it 'schedules a notification' do
      expect(MailScheduler::NotificationServiceWorker).to have_received(:perform_async).with(
        'merge_when_pipeline_succeeds', merge_request, user).once
    end

    it 'creates a system note' do
      pipeline = build(:ci_pipeline)
      allow(merge_request).to receive(:diff_head_pipeline) { pipeline }

      note = merge_request.notes.last
      expect(note.note).to match expected_note
    end
  end

  context 'when already approved' do
    let(:service) { described_class.new(project, user, should_remove_source_branch: true) }
    let(:build) { create(:ci_build, ref: mr_merge_if_green_enabled.source_branch) }

    before do
      allow(mr_merge_if_green_enabled)
        .to receive_messages(head_pipeline: pipeline, diff_head_pipeline: pipeline)

      allow(mr_merge_if_green_enabled).to receive(:mergeable?)
                                            .and_return(true)

      allow(pipeline).to receive(:success?).and_return(true)
    end

    it 'updates the merge params' do
      expect(SystemNoteService).not_to receive(:merge_when_pipeline_succeeds)
      expect(MailScheduler::NotificationServiceWorker).not_to receive(:perform_async).with(
        'merge_when_pipeline_succeeds', any_args)

      service.execute(mr_merge_if_green_enabled)
      expect(mr_merge_if_green_enabled.merge_params).to have_key('should_remove_source_branch')
    end
  end
end

RSpec.shared_examples 'auto_merge service #process' do
  let(:merge_request_ref) { mr_merge_if_green_enabled.source_branch }
  let(:merge_request_head) do
    project.commit(mr_merge_if_green_enabled.source_branch).id
  end

  context 'when triggered by pipeline with valid ref and sha' do
    let(:triggering_pipeline) do
      create(:ci_pipeline, project: project, ref: merge_request_ref,
        sha: merge_request_head, status: 'success',
        head_pipeline_of: mr_merge_if_green_enabled)
    end

    it "merges all merge requests with merge when the pipeline succeeds enabled" do
      allow(mr_merge_if_green_enabled)
        .to receive_messages(head_pipeline: triggering_pipeline, diff_head_pipeline: triggering_pipeline)

      expect(MergeWorker).to receive(:perform_async)
      service.process(mr_merge_if_green_enabled)
    end
  end

  context 'when triggered by an old pipeline' do
    let(:old_pipeline) do
      create(:ci_pipeline, project: project, ref: merge_request_ref,
        sha: '1234abcdef', status: 'success')
    end

    it 'does not merge request' do
      expect(MergeWorker).not_to receive(:perform_async)
      service.process(mr_merge_if_green_enabled)
    end
  end

  context 'when triggered by pipeline from a different branch' do
    let(:unrelated_pipeline) do
      create(:ci_pipeline, project: project, ref: 'feature',
        sha: merge_request_head, status: 'success')
    end

    it 'does not merge request' do
      expect(MergeWorker).not_to receive(:perform_async)
      service.process(mr_merge_if_green_enabled)
    end
  end

  context 'when pipeline is merge request pipeline' do
    let(:pipeline) do
      create(:ci_pipeline, :success,
        source: :merge_request_event,
        ref: mr_merge_if_green_enabled.merge_ref_path,
        merge_request: mr_merge_if_green_enabled,
        merge_requests_as_head_pipeline: [mr_merge_if_green_enabled])
    end

    it 'merges the associated merge request' do
      allow(mr_merge_if_green_enabled)
        .to receive_messages(head_pipeline: pipeline, diff_head_pipeline: pipeline)

      expect(MergeWorker).to receive(:perform_async)
      service.process(mr_merge_if_green_enabled)
    end
  end
end

RSpec.shared_examples 'auto_merge service #cancel' do
  before do
    service.cancel(mr_merge_if_green_enabled)
  end

  it "resets all the pipeline succeeds params" do
    expect(mr_merge_if_green_enabled.merge_when_pipeline_succeeds).to be_falsey
    expect(mr_merge_if_green_enabled.merge_params).to eq({})
    expect(mr_merge_if_green_enabled.merge_user).to be nil
  end

  it 'posts a system note' do
    note = mr_merge_if_green_enabled.notes.last
    expect(note.note).to include 'canceled the automatic merge'
  end
end

RSpec.shared_examples 'auto_merge service #abort' do
  before do
    service.abort(mr_merge_if_green_enabled, 'an error')
  end

  it 'posts a system note' do
    note = mr_merge_if_green_enabled.notes.last
    expect(note.note).to include 'aborted the automatic merge'
  end
end
