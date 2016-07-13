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

  describe 'Validations' do
    context 'when service is active' do
      before { subject.active = true }

      it { is_expected.to validate_presence_of(:webhook) }
      it_behaves_like 'issue tracker service URL attribute', :webhook
    end

    context 'when service is inactive' do
      before { subject.active = false }

      it { is_expected.not_to validate_presence_of(:webhook) }
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

      opts = {
        title: "Awesome wiki_page",
        content: "Some text describing some thing or another",
        format: "md",
        message: "user created page: Awesome wiki_page"
      }

      wiki_page_service = WikiPages::CreateService.new(project, user, opts)
      @wiki_page = wiki_page_service.execute
      @wiki_page_sample_data = wiki_page_service.hook_data(@wiki_page, 'create')
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

    it "should call Slack API for wiki page events" do
      slack.execute(@wiki_page_sample_data)

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

    context "event channels" do
      it "uses the right channel for push event" do
        slack.update_attributes(push_channel: "random")

        expect(Slack::Notifier).to receive(:new).
         with(webhook_url, channel: "random").
         and_return(
           double(:slack_service).as_null_object
         )

        slack.execute(push_sample_data)
      end

      it "uses the right channel for merge request event" do
        slack.update_attributes(merge_request_channel: "random")

        expect(Slack::Notifier).to receive(:new).
         with(webhook_url, channel: "random").
         and_return(
           double(:slack_service).as_null_object
         )

        slack.execute(@merge_sample_data)
      end

      it "uses the right channel for issue event" do
        slack.update_attributes(issue_channel: "random")

        expect(Slack::Notifier).to receive(:new).
         with(webhook_url, channel: "random").
         and_return(
           double(:slack_service).as_null_object
         )

        slack.execute(@issues_sample_data)
      end

      it "uses the right channel for wiki event" do
        slack.update_attributes(wiki_page_channel: "random")

        expect(Slack::Notifier).to receive(:new).
         with(webhook_url, channel: "random").
         and_return(
           double(:slack_service).as_null_object
         )

        slack.execute(@wiki_page_sample_data)
      end

      context "note event" do
        let(:issue_note) do
          create(:note_on_issue, project: project, note: "issue note")
        end

        it "uses the right channel" do
          slack.update_attributes(note_channel: "random")

          note_data = Gitlab::NoteDataBuilder.build(issue_note, user)

          expect(Slack::Notifier).to receive(:new).
           with(webhook_url, channel: "random").
           and_return(
             double(:slack_service).as_null_object
           )

          slack.execute(note_data)
        end
      end
    end
  end

  describe "Note events" do
    let(:slack)   { SlackService.new }
    let(:user) { create(:user) }
    let(:project) { create(:project, creator_id: user.id) }
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

    context 'when commit comment event executed' do
      let(:commit_note) do
        create(:note_on_commit, author: user,
                                project: project,
                                commit_id: project.repository.commit.id,
                                note: 'a comment on a commit')
      end

      it "should call Slack API for commit comment events" do
        data = Gitlab::NoteDataBuilder.build(commit_note, user)
        slack.execute(data)

        expect(WebMock).to have_requested(:post, webhook_url).once
      end
    end

    context 'when merge request comment event executed' do
      let(:merge_request_note) do
        create(:note_on_merge_request, project: project,
                                       note: "merge request note")
      end

      it "should call Slack API for merge request comment events" do
        data = Gitlab::NoteDataBuilder.build(merge_request_note, user)
        slack.execute(data)

        expect(WebMock).to have_requested(:post, webhook_url).once
      end
    end

    context 'when issue comment event executed' do
      let(:issue_note) do
        create(:note_on_issue, project: project, note: "issue note")
      end

      it "should call Slack API for issue comment events" do
        data = Gitlab::NoteDataBuilder.build(issue_note, user)
        slack.execute(data)

        expect(WebMock).to have_requested(:post, webhook_url).once
      end
    end

    context 'when snippet comment event executed' do
      let(:snippet_note) do
        create(:note_on_project_snippet, project: project,
                                         note: "snippet note")
      end

      it "should call Slack API for snippet comment events" do
        data = Gitlab::NoteDataBuilder.build(snippet_note, user)
        slack.execute(data)

        expect(WebMock).to have_requested(:post, webhook_url).once
      end
    end
  end
end
