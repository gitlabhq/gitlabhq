# frozen_string_literal: true

require "spec_helper"

RSpec.describe Integrations::HangoutsChat do
  it_behaves_like "chat integration", "Hangouts Chat" do
    let(:client) { HangoutsChat::Sender }
    let(:client_arguments) { webhook_url }
    let(:payload) do
      {
        text: be_present
      }
    end
  end

  let(:chat_integration) { described_class.new }
  let(:webhook_url) { 'https://example.gitlab.com/' }
  let(:webhook_url_regex) { /\A#{webhook_url}.*/ }

  describe "#execute" do
    let_it_be(:user) { create(:user) }
    let_it_be(:project) { create(:project, :repository, :wiki_repo) }

    before do
      allow(chat_integration).to receive_messages(
        project: project,
        project_id: project.id,
        webhook: webhook_url
      )

      WebMock.stub_request(:post, webhook_url_regex)
    end

    context 'with push events' do
      let(:push_sample_data) do
        Gitlab::DataBuilder::Push.build_sample(project, user)
      end

      it "adds thread key for push events" do
        expect(chat_integration.execute(push_sample_data)).to be(true)

        expect(WebMock).to have_requested(:post, webhook_url)
          .with(query: hash_including({ "threadKey" => /push .*?/ }))
          .once
      end
    end

    context 'with issue events' do
      let(:issues_sample_data) { create(:issue, project: project).to_hook_data(user) }

      it "adds thread key for issue events" do
        expect(chat_integration.execute(issues_sample_data)).to be(true)

        expect(WebMock).to have_requested(:post, webhook_url)
          .with(query: hash_including({ "threadKey" => /issue .*?/ }))
          .once
      end
    end

    context 'with merge events' do
      let(:merge_sample_data) { create(:merge_request, source_project: project).to_hook_data(user) }

      it "adds thread key for merge events" do
        expect(chat_integration.execute(merge_sample_data)).to be(true)

        expect(WebMock).to have_requested(:post, webhook_url)
          .with(query: hash_including({ "threadKey" => /merge request .*?/ }))
          .once
      end
    end

    context 'with wiki page events' do
      let(:wiki_page_sample_data) do
        Gitlab::DataBuilder::WikiPage.build(create(:wiki_page, project: project, message: 'foo'), user, 'create')
      end

      it "adds thread key for wiki page events" do
        expect(chat_integration.execute(wiki_page_sample_data)).to be(true)

        expect(WebMock).to have_requested(:post, webhook_url)
          .with(query: hash_including({ "threadKey" => /wiki_page .*?/ }))
          .once
      end
    end

    context 'with pipeline events' do
      let(:pipeline) do
        create(:ci_pipeline, :failed, project: project, sha: project.commit.sha, ref: project.default_branch)
      end

      let(:pipeline_sample_data) { Gitlab::DataBuilder::Pipeline.build(pipeline) }

      it "adds thread key for pipeline events" do
        expect(chat_integration.execute(pipeline_sample_data)).to be(true)

        expect(WebMock).to have_requested(:post, webhook_url)
          .with(query: hash_including({ "threadKey" => /pipeline .*?/ }))
          .once
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

      WebMock.stub_request(:post, webhook_url_regex)
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

      it "adds thread key" do
        data = Gitlab::DataBuilder::Note.build(commit_note, user)

        expect(chat_integration.execute(data)).to be(true)

        expect(WebMock).to have_requested(:post, webhook_url)
          .with(query: hash_including({ "threadKey" => /commit .*?/ }))
          .once
      end
    end

    context 'when merge request comment event executed' do
      let(:merge_request_note) do
        create(:note_on_merge_request, project: project, note: "merge request note")
      end

      it "adds thread key" do
        data = Gitlab::DataBuilder::Note.build(merge_request_note, user)

        expect(chat_integration.execute(data)).to be(true)

        expect(WebMock).to have_requested(:post, webhook_url)
          .with(query: hash_including({ "threadKey" => /merge request .*?/ }))
          .once
      end
    end

    context 'when issue comment event executed' do
      let(:issue_note) do
        create(:note_on_issue, project: project, note: "issue note")
      end

      it "adds thread key" do
        data = Gitlab::DataBuilder::Note.build(issue_note, user)

        expect(chat_integration.execute(data)).to be(true)

        expect(WebMock).to have_requested(:post, webhook_url)
          .with(query: hash_including({ "threadKey" => /issue .*?/ }))
          .once
      end
    end

    context 'when snippet comment event executed' do
      let(:snippet_note) do
        create(:note_on_project_snippet, project: project, note: "snippet note")
      end

      it "adds thread key" do
        data = Gitlab::DataBuilder::Note.build(snippet_note, user)

        expect(chat_integration.execute(data)).to be(true)

        expect(WebMock).to have_requested(:post, webhook_url)
          .with(query: hash_including({ "threadKey" => /snippet .*?/ }))
          .once
      end
    end
  end
end
