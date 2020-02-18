# frozen_string_literal: true

require 'spec_helper'

describe PostReceiveService do
  include Gitlab::Routing

  let_it_be(:project) { create(:project, :repository, :wiki_repo) }
  let_it_be(:user) { create(:user) }

  let(:identifier) { 'key-123' }
  let(:gl_repository) { "project-#{project.id}" }
  let(:branch_name) { 'feature' }
  let(:secret_token) { Gitlab::Shell.secret_token }
  let(:reference_counter) { double('ReferenceCounter') }
  let(:push_options) { ['ci.skip', 'another push option'] }

  let(:changes) do
    "#{Gitlab::Git::BLANK_SHA} 570e7b2abdd848b95f2f578043fc23bd6f6fd24d refs/heads/#{branch_name}"
  end

  let(:params) do
    {
      gl_repository: gl_repository,
      secret_token: secret_token,
      identifier: identifier,
      changes: changes,
      push_options: push_options
    }
  end

  let(:response) { PostReceiveService.new(user, project, params).execute }

  subject { response.messages.as_json }

  it 'enqueues a PostReceive worker job' do
    expect(PostReceive).to receive(:perform_async)
      .with(gl_repository, identifier, changes, { ci: { skip: true } })

    subject
  end

  it 'decreases the reference counter and returns the result' do
    expect(Gitlab::ReferenceCounter).to receive(:new).with(gl_repository)
      .and_return(reference_counter)
    expect(reference_counter).to receive(:decrease).and_return(true)

    expect(response.reference_counter_decreased).to be(true)
  end

  it 'returns link to create new merge request' do
    message = <<~MESSAGE.strip
      To create a merge request for #{branch_name}, visit:
        http://#{Gitlab.config.gitlab.host}/#{project.full_path}/-/merge_requests/new?merge_request%5Bsource_branch%5D=#{branch_name}
    MESSAGE

    expect(subject).to include(build_basic_message(message))
  end

  it 'returns the link to an existing merge request when it exists' do
    merge_request = create(:merge_request, source_project: project, source_branch: branch_name, target_branch: 'master')
    message = <<~MESSAGE.strip
      View merge request for feature:
        #{project_merge_request_url(project, merge_request)}
    MESSAGE

    expect(subject).to include(build_basic_message(message))
  end

  context 'when printing_merge_request_link_enabled is false' do
    let(:project) { create(:project, printing_merge_request_link_enabled: false) }

    it 'returns no merge request messages' do
      expect(subject).to be_blank
    end
  end

  it 'does not invoke MergeRequests::PushOptionsHandlerService' do
    expect(MergeRequests::PushOptionsHandlerService).not_to receive(:new)

    subject
  end

  context 'when there are merge_request push options' do
    let(:params) { super().merge(push_options: ['merge_request.create']) }

    before do
      project.add_developer(user)
    end

    it 'invokes MergeRequests::PushOptionsHandlerService' do
      expect(MergeRequests::PushOptionsHandlerService).to receive(:new).and_call_original

      subject
    end

    it 'creates a new merge request' do
      expect { Sidekiq::Testing.fake! { subject } }.to change(MergeRequest, :count).by(1)
    end

    it 'links to the newly created merge request' do
      message = <<~MESSAGE.strip
        View merge request for #{branch_name}:
          http://#{Gitlab.config.gitlab.host}/#{project.full_path}/-/merge_requests/1
      MESSAGE

      expect(subject).to include(build_basic_message(message))
    end

    it 'adds errors on the service instance to warnings' do
      expect_any_instance_of(
        MergeRequests::PushOptionsHandlerService
      ).to receive(:errors).at_least(:once).and_return(['my error'])

      message = "WARNINGS:\nError encountered with push options 'merge_request.create': my error"

      expect(subject).to include(build_alert_message(message))
    end

    it 'adds ActiveRecord errors on invalid MergeRequest records to warnings' do
      invalid_merge_request = MergeRequest.new
      invalid_merge_request.errors.add(:base, 'my error')
      message = "WARNINGS:\nError encountered with push options 'merge_request.create': my error"

      expect_any_instance_of(
        MergeRequests::CreateService
      ).to receive(:execute).and_return(invalid_merge_request)

      expect(subject).to include(build_alert_message(message))
    end
  end

  context 'broadcast message exists' do
    it 'outputs a broadcast message' do
      broadcast_message = create(:broadcast_message, starts_at: 1.day.ago, ends_at: 1.day.from_now)

      expect(subject).to include(build_alert_message(broadcast_message.message))
    end
  end

  context 'broadcast message does not exist' do
    it 'does not output a broadcast message' do
      expect(has_alert_messages?(subject)).to be_falsey
    end
  end

  context 'nil broadcast message' do
    it 'does not output a broadcast message' do
      allow(BroadcastMessage).to receive(:current).and_return(nil)

      expect(has_alert_messages?(subject)).to be_falsey
    end
  end

  context 'with a redirected data' do
    it 'returns redirected message on the response' do
      project_moved = Gitlab::Checks::ProjectMoved.new(project, user, 'http', 'foo/baz')
      project_moved.add_message

      expect(subject).to include(build_basic_message(project_moved.message))
    end
  end

  context 'with new project data' do
    it 'returns new project message on the response' do
      project_created = Gitlab::Checks::ProjectCreated.new(project, user, 'http')
      project_created.add_message

      expect(subject).to include(build_basic_message(project_created.message))
    end
  end

  def build_alert_message(message)
    { 'type' => 'alert', 'message' => message }
  end

  def build_basic_message(message)
    { 'type' => 'basic', 'message' => message }
  end

  def has_alert_messages?(messages)
    messages.any? do |message|
      message['type'] == 'alert'
    end
  end
end
