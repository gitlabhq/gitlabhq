# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Integrations::MicrosoftTeams, feature_category: :integrations do
  it_behaves_like "chat integration", "Microsoft Teams" do
    let(:client) { ::MicrosoftTeams::Notifier }
    let(:client_arguments) { webhook_url }

    let(:payload) do
      {
        attachments: be_present
      }
    end
  end

  let(:chat_integration) { described_class.new }
  let(:webhook_url) { 'https://example.gitlab.com/' }

  describe "#execute" do
    let_it_be(:user) { create(:user) }
    let_it_be(:project) { create(:project, :repository, :wiki_repo) }

    before do
      allow(chat_integration).to receive_messages(
        project: project,
        project_id: project.id,
        webhook: webhook_url
      )

      WebMock.stub_request(:post, webhook_url)
    end

    context 'with push events' do
      let(:push_sample_data) do
        Gitlab::DataBuilder::Push.build_sample(project, user)
      end

      it "calls Microsoft Teams API for push events" do
        chat_integration.execute(push_sample_data)

        expect(WebMock).to have_requested(:post, webhook_url).once
      end

      it 'specifies the webhook when it is configured' do
        integration = double(:microsoft_teams_integration).as_null_object
        expect(::MicrosoftTeams::Notifier).to receive(:new).with(webhook_url).and_return(integration)

        chat_integration.execute(push_sample_data)
      end
    end

    context 'with issue events' do
      let(:opts) { { title: 'Awesome issue', description: 'please fix' } }
      let(:issues_sample_data) do
        service = Issues::CreateService.new(container: project, current_user: user, params: opts)
        issue = service.execute[:issue]
        service.hook_data(issue, 'open')
      end

      before do
        project.add_developer(user)
      end

      it "calls Microsoft Teams API" do
        chat_integration.execute(issues_sample_data)

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
        service = MergeRequests::CreateService.new(project: project, current_user: user, params: opts)
        merge_request = service.execute
        service.hook_data(merge_request, 'open')
      end

      before do
        project.add_developer(user)
      end

      it "calls Microsoft Teams API" do
        chat_integration.execute(merge_sample_data)

        expect(WebMock).to have_requested(:post, webhook_url).once
      end
    end

    context 'with wiki page events' do
      let(:opts) do
        {
          title: "Awesome wiki_page",
          content: "Some text describing some thing or another",
          format: :markdown,
          message: "user created page: Awesome wiki_page"
        }
      end

      let(:wiki_page) { create(:wiki_page, wiki: project.wiki, **opts) }
      let(:wiki_page_sample_data) { Gitlab::DataBuilder::WikiPage.build(wiki_page, user, 'create') }

      it "calls Microsoft Teams API" do
        chat_integration.execute(wiki_page_sample_data)

        expect(WebMock).to have_requested(:post, webhook_url).once
      end
    end
  end

  describe "Note events" do
    let_it_be(:user) { create(:user) }
    let_it_be(:project) { create(:project, :repository, creator: user) }

    before do
      allow(chat_integration).to receive_messages(
        project: project,
        project_id: project.id,
        webhook: webhook_url
      )

      WebMock.stub_request(:post, webhook_url)
    end

    context 'when commit comment event executed' do
      let(:commit_note) do
        create(
          :note_on_commit,
          author: user,
          project: project,
          commit_id: project.repository.commit.id,
          note: 'a comment on a commit'
        )
      end

      it "calls Microsoft Teams API for commit comment events" do
        data = Gitlab::DataBuilder::Note.build(commit_note, user, :create)

        chat_integration.execute(data)

        expect(WebMock).to have_requested(:post, webhook_url).once
      end
    end

    context 'when merge request comment event executed' do
      let(:merge_request_note) do
        create(:note_on_merge_request, project: project, note: "merge request note")
      end

      it "calls Microsoft Teams API for merge request comment events" do
        data = Gitlab::DataBuilder::Note.build(merge_request_note, user, :create)

        chat_integration.execute(data)

        expect(WebMock).to have_requested(:post, webhook_url).once
      end
    end

    context 'when issue comment event executed' do
      let(:issue_note) do
        create(:note_on_issue, project: project, note: "issue note")
      end

      it "calls Microsoft Teams API for issue comment events" do
        data = Gitlab::DataBuilder::Note.build(issue_note, user, :create)

        chat_integration.execute(data)

        expect(WebMock).to have_requested(:post, webhook_url).once
      end
    end

    context 'when snippet comment event executed' do
      let(:snippet_note) do
        create(:note_on_project_snippet, project: project, note: "snippet note")
      end

      it "calls Microsoft Teams API for snippet comment events" do
        data = Gitlab::DataBuilder::Note.build(snippet_note, user, :create)

        chat_integration.execute(data)

        expect(WebMock).to have_requested(:post, webhook_url).once
      end
    end
  end

  describe 'Pipeline events' do
    let_it_be_with_refind(:project) { create(:project, :repository) }

    let(:pipeline) do
      create(
        :ci_pipeline,
        project: project, status: status,
        sha: project.commit.sha, ref: project.default_branch
      )
    end

    before do
      allow(chat_integration).to receive_messages(
        project: project,
        webhook: webhook_url
      )
    end

    shared_examples 'call Microsoft Teams API' do |branches_to_be_notified: nil|
      before do
        WebMock.stub_request(:post, webhook_url)
        chat_integration.branches_to_be_notified = branches_to_be_notified if branches_to_be_notified
      end

      it 'calls Microsoft Teams API for pipeline events' do
        data = Gitlab::DataBuilder::Pipeline.build(pipeline)
        data[:markdown] = true

        chat_integration.execute(data)

        expect(WebMock).to have_requested(:post, webhook_url).once
      end
    end

    shared_examples 'does not call Microsoft Teams API' do |branches_to_be_notified: nil|
      before do
        chat_integration.branches_to_be_notified = branches_to_be_notified if branches_to_be_notified
      end

      it 'does not call Microsoft Teams API for pipeline events' do
        data = Gitlab::DataBuilder::Pipeline.build(pipeline)
        result = chat_integration.execute(data)

        expect(result).to be_falsy
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
          result = chat_integration.execute(data)

          expect(result).to be_falsy
        end
      end

      context 'with setting notify_only_broken_pipelines to false' do
        before do
          chat_integration.notify_only_broken_pipelines = false
        end

        it_behaves_like 'call Microsoft Teams API'
      end
    end

    context 'with default branch' do
      let(:pipeline) do
        create(:ci_pipeline, project: project, status: 'failed', sha: project.commit.sha, ref: project.default_branch)
      end

      context 'only notify for the default branch' do
        it_behaves_like 'call Microsoft Teams API', branches_to_be_notified: "default"
      end

      context 'notify for only protected branches' do
        it_behaves_like 'does not call Microsoft Teams API', branches_to_be_notified: "protected"
      end

      context 'notify for only default and protected branches' do
        it_behaves_like 'call Microsoft Teams API', branches_to_be_notified: "default_and_protected"
      end

      context 'notify for all branches' do
        it_behaves_like 'call Microsoft Teams API', branches_to_be_notified: "all"
      end
    end

    context 'with protected branch' do
      before do
        create(:protected_branch, :create_branch_on_repository, project: project, name: 'a-protected-branch')
      end

      let(:pipeline) do
        create(:ci_pipeline, project: project, status: 'failed', sha: project.commit.sha, ref: 'a-protected-branch')
      end

      context 'only notify for the default branch' do
        it_behaves_like 'does not call Microsoft Teams API', branches_to_be_notified: "default"
      end

      context 'notify for only protected branches' do
        it_behaves_like 'call Microsoft Teams API', branches_to_be_notified: "protected"
      end

      context 'notify for only default and protected branches' do
        it_behaves_like 'call Microsoft Teams API', branches_to_be_notified: "default_and_protected"
      end

      context 'notify for all branches' do
        it_behaves_like 'call Microsoft Teams API', branches_to_be_notified: "all"
      end
    end

    context 'with neither protected nor default branch' do
      let(:pipeline) do
        create(:ci_pipeline, project: project, status: 'failed', sha: project.commit.sha, ref: 'a-random-branch')
      end

      context 'only notify for the default branch' do
        it_behaves_like 'does not call Microsoft Teams API', branches_to_be_notified: "default"
      end

      context 'notify for only protected branches' do
        it_behaves_like 'does not call Microsoft Teams API', branches_to_be_notified: "protected"
      end

      context 'notify for only default and protected branches' do
        it_behaves_like 'does not call Microsoft Teams API', branches_to_be_notified: "default_and_protected"
      end

      context 'notify for all branches' do
        it_behaves_like 'call Microsoft Teams API', branches_to_be_notified: "all"
      end
    end
  end
end
