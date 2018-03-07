require 'spec_helper'

describe MicrosoftTeamsService do
  let(:chat_service) { described_class.new }
  let(:webhook_url) { 'https://example.gitlab.com/' }

  describe "Associations" do
    it { is_expected.to belong_to :project }
    it { is_expected.to have_one :service_hook }
  end

  describe 'Validations' do
    context 'when service is active' do
      before do
        subject.active = true
      end

      it { is_expected.to validate_presence_of(:webhook) }
      it_behaves_like 'issue tracker service URL attribute', :webhook
    end

    context 'when service is inactive' do
      before do
        subject.active = false
      end

      it { is_expected.not_to validate_presence_of(:webhook) }
    end
  end

  describe "#execute" do
    let(:user)    { create(:user) }
    let(:project) { create(:project, :repository) }

    before do
      allow(chat_service).to receive_messages(
        project: project,
        project_id: project.id,
        service_hook: true,
        webhook: webhook_url
      )

      WebMock.stub_request(:post, webhook_url)
    end

    context 'with push events' do
      let(:push_sample_data) do
        Gitlab::DataBuilder::Push.build_sample(project, user)
      end

      it "calls Microsoft Teams API for push events" do
        chat_service.execute(push_sample_data)

        expect(WebMock).to have_requested(:post, webhook_url).once
      end

      it 'specifies the webhook when it is configured' do
        expect(MicrosoftTeams::Notifier).to receive(:new).with(webhook_url).and_return(double(:microsoft_teams_service).as_null_object)

        chat_service.execute(push_sample_data)
      end
    end

    context 'with issue events' do
      let(:opts) { { title: 'Awesome issue', description: 'please fix' } }
      let(:issues_sample_data) do
        service = Issues::CreateService.new(project, user, opts)
        issue = service.execute
        service.hook_data(issue, 'open')
      end

      it "calls Microsoft Teams API" do
        chat_service.execute(issues_sample_data)

        expect(WebMock).to have_requested(:post, webhook_url).once
      end
    end

    context 'with merge events' do
      let(:opts) do
        {
          title: 'Awesome merge_request',
          description: 'please fix',
          source_branch: 'feature',
          target_branch: 'master'
        }
      end

      let(:merge_sample_data) do
        service = MergeRequests::CreateService.new(project, user, opts)
        merge_request = service.execute
        service.hook_data(merge_request, 'open')
      end

      before do
        project.add_developer(user)
      end

      it "calls Microsoft Teams API" do
        chat_service.execute(merge_sample_data)

        expect(WebMock).to have_requested(:post, webhook_url).once
      end
    end

    context 'with wiki page events' do
      let(:opts) do
        {
          title: "Awesome wiki_page",
          content: "Some text describing some thing or another",
          format: "md",
          message: "user created page: Awesome wiki_page"
        }
      end
      let(:wiki_page) { create(:wiki_page, wiki: project.wiki, attrs: opts) }
      let(:wiki_page_sample_data) { Gitlab::DataBuilder::WikiPage.build(wiki_page, user, 'create') }

      it "calls Microsoft Teams API" do
        chat_service.execute(wiki_page_sample_data)

        expect(WebMock).to have_requested(:post, webhook_url).once
      end
    end
  end

  describe "Note events" do
    let(:user) { create(:user) }
    let(:project) { create(:project, :repository, creator: user) }

    before do
      allow(chat_service).to receive_messages(
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

      it "calls Microsoft Teams API for commit comment events" do
        data = Gitlab::DataBuilder::Note.build(commit_note, user)

        chat_service.execute(data)

        expect(WebMock).to have_requested(:post, webhook_url).once
      end
    end

    context 'when merge request comment event executed' do
      let(:merge_request_note) do
        create(:note_on_merge_request, project: project,
                                       note: "merge request note")
      end

      it "calls Microsoft Teams API for merge request comment events" do
        data = Gitlab::DataBuilder::Note.build(merge_request_note, user)

        chat_service.execute(data)

        expect(WebMock).to have_requested(:post, webhook_url).once
      end
    end

    context 'when issue comment event executed' do
      let(:issue_note) do
        create(:note_on_issue, project: project, note: "issue note")
      end

      it "calls Microsoft Teams API for issue comment events" do
        data = Gitlab::DataBuilder::Note.build(issue_note, user)

        chat_service.execute(data)

        expect(WebMock).to have_requested(:post, webhook_url).once
      end
    end

    context 'when snippet comment event executed' do
      let(:snippet_note) do
        create(:note_on_project_snippet, project: project,
                                         note: "snippet note")
      end

      it "calls Microsoft Teams API for snippet comment events" do
        data = Gitlab::DataBuilder::Note.build(snippet_note, user)

        chat_service.execute(data)

        expect(WebMock).to have_requested(:post, webhook_url).once
      end
    end
  end

  describe 'Pipeline events' do
    let(:user) { create(:user) }
    let(:project) { create(:project, :repository) }

    let(:pipeline) do
      create(:ci_pipeline,
             project: project, status: status,
             sha: project.commit.sha, ref: project.default_branch)
    end

    before do
      allow(chat_service).to receive_messages(
        project: project,
        service_hook: true,
        webhook: webhook_url
      )
    end

    shared_examples 'call Microsoft Teams API' do
      before do
        WebMock.stub_request(:post, webhook_url)
      end

      it 'calls Microsoft Teams API for pipeline events' do
        data = Gitlab::DataBuilder::Pipeline.build(pipeline)

        chat_service.execute(data)

        expect(WebMock).to have_requested(:post, webhook_url).once
      end
    end

    context 'with failed pipeline' do
      let(:status) { 'failed' }

      it_behaves_like 'call Microsoft Teams API'
    end

    context 'with succeeded pipeline' do
      let(:status) { 'success' }

      context 'with default to notify_only_broken_pipelines' do
        it 'does not call Microsoft Teams API for pipeline events' do
          data = Gitlab::DataBuilder::Pipeline.build(pipeline)
          result = chat_service.execute(data)

          expect(result).to be_falsy
        end
      end

      context 'with setting notify_only_broken_pipelines to false' do
        before do
          chat_service.notify_only_broken_pipelines = false
        end

        it_behaves_like 'call Microsoft Teams API'
      end
    end

    context 'only notify for the default branch' do
      context 'when enabled' do
        let(:pipeline) do
          create(:ci_pipeline, project: project, status: 'failed', ref: 'not-the-default-branch')
        end

        before do
          chat_service.notify_only_default_branch = true
        end

        it 'does not call the Microsoft Teams API for pipeline events' do
          data = Gitlab::DataBuilder::Pipeline.build(pipeline)
          result = chat_service.execute(data)

          expect(result).to be_falsy
        end
      end
    end
  end
end
