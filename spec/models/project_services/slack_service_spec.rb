# == Schema Information
#
# Table name: services
#
#  id                    :integer          not null, primary key
#  type                  :string(255)
#  title                 :string(255)
#  project_id            :integer
#  created_at            :datetime
#  updated_at            :datetime
#  active                :boolean          default(FALSE), not null
#  properties            :text
#  template              :boolean          default(FALSE)
#  push_events           :boolean          default(TRUE)
#  issues_events         :boolean          default(TRUE)
#  merge_requests_events :boolean          default(TRUE)
#  tag_push_events       :boolean          default(TRUE)
#  note_events           :boolean          default(TRUE), not null
#

require 'spec_helper'

describe SlackService, models: true do
  describe "Associations" do
    it { is_expected.to belong_to :project }
    it { is_expected.to have_one :service_hook }
  end

  describe "Validations" do
    context "active" do
      before do
        subject.active = true
      end

      it { is_expected.to validate_presence_of :webhook }
    end
  end

  describe "Execute" do
    let(:slack)   { SlackService.new }
    let(:user)    { create(:user) }
    let(:project) { create(:project) }
    let(:push_sample_data) { Gitlab::PushDataBuilder.build_sample(project, user) }
    let(:webhook_url) { 'https://hooks.slack.com/services/SVRWFV0VVAR97N/B02R25XN3/ZBqu7xMupaEEICInN685' }
    let(:username) { 'slack_username' }
    let(:channel) { 'slack_channel' }

    before do
      allow(slack).to receive_messages(
        project: project,
        project_id: project.id,
        service_hook: true,
        webhook: webhook_url
      )

      WebMock.stub_request(:post, webhook_url)

      opts = {
        title: 'Awesome issue',
        description: 'please fix'
      }

      issue_service = Issues::CreateService.new(project, user, opts)
      @issue = issue_service.execute
      @issues_sample_data = issue_service.hook_data(@issue, 'open')

      opts = {
        title: 'Awesome merge_request',
        description: 'please fix',
        source_branch: 'feature',
        target_branch: 'master'
      }
      merge_service = MergeRequests::CreateService.new(project,
                                                       user, opts)
      @merge_request = merge_service.execute
      @merge_sample_data = merge_service.hook_data(@merge_request,
                                                   'open')
    end

    it "should call Slack API for push events" do
      slack.execute(push_sample_data)

      expect(WebMock).to have_requested(:post, webhook_url).once
    end

    it "should call Slack API for issue events" do
      slack.execute(@issues_sample_data)

      expect(WebMock).to have_requested(:post, webhook_url).once
    end

    it "should call Slack API for merge requests events" do
      slack.execute(@merge_sample_data)

      expect(WebMock).to have_requested(:post, webhook_url).once
    end

    it 'should use the username as an option for slack when configured' do
      allow(slack).to receive(:username).and_return(username)
      expect(Slack::Notifier).to receive(:new).
       with(webhook_url, username: username).
       and_return(
         double(:slack_service).as_null_object
       )
      slack.execute(push_sample_data)
    end

    it 'should use the channel as an option when it is configured' do
      allow(slack).to receive(:channel).and_return(channel)
      expect(Slack::Notifier).to receive(:new).
        with(webhook_url, channel: channel).
        and_return(
          double(:slack_service).as_null_object
        )
      slack.execute(push_sample_data)
    end
  end

  describe "Note events" do
    let(:slack)   { SlackService.new }
    let(:user) { create(:user) }
    let(:project) { create(:project, creator_id: user.id) }
    let(:issue)         { create(:issue, project: project) }
    let(:merge_request) { create(:merge_request, source_project: project, target_project: project) }
    let(:snippet)       { create(:project_snippet, project: project) }
    let(:commit_note) { create(:note_on_commit, author: user, project: project, commit_id: project.repository.commit.id, note: 'a comment on a commit') }
    let(:merge_request_note) { create(:note_on_merge_request, noteable_id: merge_request.id, note: "merge request note") }
    let(:issue_note) { create(:note_on_issue, noteable_id: issue.id, note: "issue note")}
    let(:snippet_note) { create(:note_on_project_snippet, noteable_id: snippet.id, note: "snippet note") }
    let(:webhook_url) { 'https://hooks.slack.com/services/SVRWFV0VVAR97N/B02R25XN3/ZBqu7xMupaEEICInN685' }

    before do
      allow(slack).to receive_messages(
        project: project,
        project_id: project.id,
        service_hook: true,
        webhook: webhook_url
      )

      WebMock.stub_request(:post, webhook_url)
    end

    it "should call Slack API for commit comment events" do
      data = Gitlab::NoteDataBuilder.build(commit_note, user)
      slack.execute(data)

      expect(WebMock).to have_requested(:post, webhook_url).once
    end

    it "should call Slack API for merge request comment events" do
      data = Gitlab::NoteDataBuilder.build(merge_request_note, user)
      slack.execute(data)

      expect(WebMock).to have_requested(:post, webhook_url).once
    end

    it "should call Slack API for issue comment events" do
      data = Gitlab::NoteDataBuilder.build(issue_note, user)
      slack.execute(data)

      expect(WebMock).to have_requested(:post, webhook_url).once
    end

    it "should call Slack API for snippet comment events" do
      data = Gitlab::NoteDataBuilder.build(snippet_note, user)
      slack.execute(data)

      expect(WebMock).to have_requested(:post, webhook_url).once
    end
  end
end
