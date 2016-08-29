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
  let(:slack) { SlackService.new }
  let(:webhook_url) { 'https://example.gitlab.com/' }

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
    let(:user)    { create(:user) }
    let(:project) { create(:project) }
    let(:username) { 'slack_username' }
    let(:channel)  { 'slack_channel' }

    let(:push_sample_data) do
      Gitlab::DataBuilder::Push.build_sample(project, user)
    end

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

    it "calls Slack API for push events" do
      slack.execute(push_sample_data)

      expect(WebMock).to have_requested(:post, webhook_url).once
    end

    it "calls Slack API for issue events" do
      slack.execute(@issues_sample_data)

      expect(WebMock).to have_requested(:post, webhook_url).once
    end

    it "calls Slack API for merge requests events" do
      slack.execute(@merge_sample_data)

      expect(WebMock).to have_requested(:post, webhook_url).once
    end

    it "calls Slack API for wiki page events" do
      slack.execute(@wiki_page_sample_data)

      expect(WebMock).to have_requested(:post, webhook_url).once
    end

    it 'uses the username as an option for slack when configured' do
      allow(slack).to receive(:username).and_return(username)
      expect(Slack::Notifier).to receive(:new).
       with(webhook_url, username: username).
       and_return(
         double(:slack_service).as_null_object
       )

      slack.execute(push_sample_data)
    end

    it 'uses the channel as an option when it is configured' do
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

          note_data = Gitlab::DataBuilder::Note.build(issue_note, user)

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
    let(:user) { create(:user) }
    let(:project) { create(:project, creator_id: user.id) }

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

      it "calls Slack API for commit comment events" do
        data = Gitlab::DataBuilder::Note.build(commit_note, user)
        slack.execute(data)

        expect(WebMock).to have_requested(:post, webhook_url).once
      end
    end

    context 'when merge request comment event executed' do
      let(:merge_request_note) do
        create(:note_on_merge_request, project: project,
                                       note: "merge request note")
      end

      it "calls Slack API for merge request comment events" do
        data = Gitlab::DataBuilder::Note.build(merge_request_note, user)
        slack.execute(data)

        expect(WebMock).to have_requested(:post, webhook_url).once
      end
    end

    context 'when issue comment event executed' do
      let(:issue_note) do
        create(:note_on_issue, project: project, note: "issue note")
      end

      it "calls Slack API for issue comment events" do
        data = Gitlab::DataBuilder::Note.build(issue_note, user)
        slack.execute(data)

        expect(WebMock).to have_requested(:post, webhook_url).once
      end
    end

    context 'when snippet comment event executed' do
      let(:snippet_note) do
        create(:note_on_project_snippet, project: project,
                                         note: "snippet note")
      end

      it "calls Slack API for snippet comment events" do
        data = Gitlab::DataBuilder::Note.build(snippet_note, user)
        slack.execute(data)

        expect(WebMock).to have_requested(:post, webhook_url).once
      end
    end
  end

  describe 'Pipeline events' do
    let(:user) { create(:user) }
    let(:project) { create(:project) }

    let(:pipeline) do
      create(:ci_pipeline,
             project: project, status: status,
             sha: project.commit.sha, ref: project.default_branch)
    end

    before do
      allow(slack).to receive_messages(
        project: project,
        service_hook: true,
        webhook: webhook_url
      )
    end

    shared_examples 'call Slack API' do
      before do
        WebMock.stub_request(:post, webhook_url)
      end

      it 'calls Slack API for pipeline events' do
        data = Gitlab::DataBuilder::Pipeline.build(pipeline)
        slack.execute(data)

        expect(WebMock).to have_requested(:post, webhook_url).once
      end
    end

    context 'with failed pipeline' do
      let(:status) { 'failed' }

      it_behaves_like 'call Slack API'
    end

    context 'with succeeded pipeline' do
      let(:status) { 'success' }

      context 'with default to notify_only_broken_pipelines' do
        it 'does not call Slack API for pipeline events' do
          data = Gitlab::DataBuilder::Pipeline.build(pipeline)
          result = slack.execute(data)

          expect(result).to be_falsy
        end
      end

      context 'with setting notify_only_broken_pipelines to false' do
        before do
          slack.notify_only_broken_pipelines = false
        end

        it_behaves_like 'call Slack API'
      end
    end
  end
end
