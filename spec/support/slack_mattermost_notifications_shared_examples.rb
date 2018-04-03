Dir[Rails.root.join("app/models/project_services/chat_message/*.rb")].each { |f| require f }

RSpec.shared_examples 'slack or mattermost notifications' do
  let(:chat_service) { described_class.new }
  let(:webhook_url) { 'https://example.gitlab.com/' }

  def execute_with_options(options)
    receive(:new).with(webhook_url, options)
     .and_return(double(:slack_service).as_null_object)
  end

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
    let(:username) { 'slack_username' }
    let(:channel)  { 'slack_channel' }
    let(:issue_service_options) { { title: 'Awesome issue', description: 'please fix' } }

    let(:push_sample_data) do
      Gitlab::DataBuilder::Push.build_sample(project, user)
    end

    before do
      allow(chat_service).to receive_messages(
        project: project,
        project_id: project.id,
        service_hook: true,
        webhook: webhook_url
      )

      WebMock.stub_request(:post, webhook_url)

      issue_service = Issues::CreateService.new(project, user, issue_service_options)
      @issue = issue_service.execute
      @issues_sample_data = issue_service.hook_data(@issue, 'open')

      project.add_developer(user)
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

      @wiki_page = create(:wiki_page, wiki: project.wiki, attrs: opts)
      @wiki_page_sample_data = Gitlab::DataBuilder::WikiPage.build(@wiki_page, user, 'create')
    end

    it "calls Slack/Mattermost API for push events" do
      chat_service.execute(push_sample_data)

      expect(WebMock).to have_requested(:post, webhook_url).once
    end

    it "calls Slack/Mattermost API for issue events" do
      chat_service.execute(@issues_sample_data)

      expect(WebMock).to have_requested(:post, webhook_url).once
    end

    it "calls Slack/Mattermost API for merge requests events" do
      chat_service.execute(@merge_sample_data)

      expect(WebMock).to have_requested(:post, webhook_url).once
    end

    it "calls Slack/Mattermost API for wiki page events" do
      chat_service.execute(@wiki_page_sample_data)

      expect(WebMock).to have_requested(:post, webhook_url).once
    end

    it 'uses the username as an option for slack when configured' do
      allow(chat_service).to receive(:username).and_return(username)

      expect(Slack::Notifier).to receive(:new)
       .with(webhook_url, username: username)
       .and_return(
         double(:slack_service).as_null_object
       )

      chat_service.execute(push_sample_data)
    end

    it 'uses the channel as an option when it is configured' do
      allow(chat_service).to receive(:channel).and_return(channel)
      expect(Slack::Notifier).to receive(:new)
        .with(webhook_url, channel: channel)
        .and_return(
          double(:slack_service).as_null_object
        )
      chat_service.execute(push_sample_data)
    end

    context "event channels" do
      it "uses the right channel for push event" do
        chat_service.update_attributes(push_channel: "random")

        expect(Slack::Notifier).to receive(:new)
         .with(webhook_url, channel: "random")
         .and_return(
           double(:slack_service).as_null_object
         )

        chat_service.execute(push_sample_data)
      end

      it "uses the right channel for merge request event" do
        chat_service.update_attributes(merge_request_channel: "random")

        expect(Slack::Notifier).to receive(:new)
         .with(webhook_url, channel: "random")
         .and_return(
           double(:slack_service).as_null_object
         )

        chat_service.execute(@merge_sample_data)
      end

      it "uses the right channel for issue event" do
        chat_service.update_attributes(issue_channel: "random")

        expect(Slack::Notifier).to receive(:new)
         .with(webhook_url, channel: "random")
         .and_return(
           double(:slack_service).as_null_object
         )

        chat_service.execute(@issues_sample_data)
      end

      context 'for confidential issues' do
        let(:issue_service_options) { { title: 'Secret', confidential: true } }

        it "uses confidential issue channel" do
          chat_service.update_attributes(confidential_issue_channel: 'confidential')

          expect(Slack::Notifier).to execute_with_options(channel: 'confidential')

          chat_service.execute(@issues_sample_data)
        end

        it 'falls back to issue channel' do
          chat_service.update_attributes(issue_channel: 'fallback_channel')

          expect(Slack::Notifier).to execute_with_options(channel: 'fallback_channel')

          chat_service.execute(@issues_sample_data)
        end
      end

      it "uses the right channel for wiki event" do
        chat_service.update_attributes(wiki_page_channel: "random")

        expect(Slack::Notifier).to receive(:new)
         .with(webhook_url, channel: "random")
         .and_return(
           double(:slack_service).as_null_object
         )

        chat_service.execute(@wiki_page_sample_data)
      end

      context "note event" do
        let(:issue_note) do
          create(:note_on_issue, project: project, note: "issue note")
        end

        it "uses the right channel" do
          chat_service.update_attributes(note_channel: "random")

          note_data = Gitlab::DataBuilder::Note.build(issue_note, user)

          expect(Slack::Notifier).to receive(:new)
           .with(webhook_url, channel: "random")
           .and_return(
             double(:slack_service).as_null_object
           )

          chat_service.execute(note_data)
        end

        context 'for confidential notes' do
          before do
            issue_note.noteable.update!(confidential: true)
          end

          it "uses confidential channel" do
            chat_service.update_attributes(confidential_note_channel: "confidential")

            note_data = Gitlab::DataBuilder::Note.build(issue_note, user)

            expect(Slack::Notifier).to execute_with_options(channel: 'confidential')

            chat_service.execute(note_data)
          end

          it 'falls back to note channel' do
            chat_service.update_attributes(note_channel: "fallback_channel")

            note_data = Gitlab::DataBuilder::Note.build(issue_note, user)

            expect(Slack::Notifier).to execute_with_options(channel: 'fallback_channel')

            chat_service.execute(note_data)
          end
        end
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

      it "calls Slack/Mattermost API for commit comment events" do
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

      it "calls Slack API for merge request comment events" do
        data = Gitlab::DataBuilder::Note.build(merge_request_note, user)
        chat_service.execute(data)

        expect(WebMock).to have_requested(:post, webhook_url).once
      end
    end

    context 'when issue comment event executed' do
      let(:issue_note) do
        create(:note_on_issue, project: project, note: "issue note")
      end

      let(:data) { Gitlab::DataBuilder::Note.build(issue_note, user) }

      it "calls Slack API for issue comment events" do
        chat_service.execute(data)

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

    shared_examples 'call Slack/Mattermost API' do
      before do
        WebMock.stub_request(:post, webhook_url)
      end

      it 'calls Slack/Mattermost API for pipeline events' do
        data = Gitlab::DataBuilder::Pipeline.build(pipeline)
        chat_service.execute(data)

        expect(WebMock).to have_requested(:post, webhook_url).once
      end
    end

    context 'with failed pipeline' do
      let(:status) { 'failed' }

      it_behaves_like 'call Slack/Mattermost API'
    end

    context 'with succeeded pipeline' do
      let(:status) { 'success' }

      context 'with default to notify_only_broken_pipelines' do
        it 'does not call Slack/Mattermost API for pipeline events' do
          data = Gitlab::DataBuilder::Pipeline.build(pipeline)
          result = chat_service.execute(data)

          expect(result).to be_falsy
        end
      end

      context 'with setting notify_only_broken_pipelines to false' do
        before do
          chat_service.notify_only_broken_pipelines = false
        end

        it_behaves_like 'call Slack/Mattermost API'
      end
    end

    context 'only notify for the default branch' do
      context 'when enabled' do
        let(:pipeline) do
          create(:ci_pipeline, :failed, project: project, ref: 'not-the-default-branch')
        end

        before do
          chat_service.notify_only_default_branch = true
        end

        it 'does not call the Slack/Mattermost API for pipeline events' do
          data = Gitlab::DataBuilder::Pipeline.build(pipeline)
          result = chat_service.execute(data)

          expect(result).to be_falsy
        end
      end

      context 'when disabled' do
        let(:pipeline) do
          create(:ci_pipeline, :failed, project: project, ref: 'not-the-default-branch')
        end

        before do
          chat_service.notify_only_default_branch = false
        end

        it_behaves_like 'call Slack/Mattermost API'
      end
    end
  end
end
