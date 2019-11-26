# frozen_string_literal: true

Dir[Rails.root.join("app/models/project_services/chat_message/*.rb")].each { |f| require f }

RSpec.shared_examples 'slack or mattermost notifications' do |service_name|
  include StubRequests

  let(:chat_service) { described_class.new }
  let(:webhook_url) { 'https://example.gitlab.com' }

  def execute_with_options(options)
    receive(:new).with(webhook_url, options.merge(http_client: SlackService::Notifier::HTTPClient))
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

  shared_examples "triggered #{service_name} service" do |event_type: nil, branches_to_be_notified: nil|
    before do
      chat_service.branches_to_be_notified = branches_to_be_notified if branches_to_be_notified
    end

    let!(:stubbed_resolved_hostname) do
      stub_full_request(webhook_url, method: :post).request_pattern.uri_pattern.to_s
    end

    it "notifies about #{event_type} events" do
      chat_service.execute(data)
      expect(WebMock).to have_requested(:post, stubbed_resolved_hostname)
    end
  end

  shared_examples "untriggered #{service_name} service" do |event_type: nil, branches_to_be_notified: nil|
    before do
      chat_service.branches_to_be_notified = branches_to_be_notified if branches_to_be_notified
    end

    let!(:stubbed_resolved_hostname) do
      stub_full_request(webhook_url, method: :post).request_pattern.uri_pattern.to_s
    end

    it "notifies about #{event_type} events" do
      chat_service.execute(data)
      expect(WebMock).not_to have_requested(:post, stubbed_resolved_hostname)
    end
  end

  describe "#execute" do
    let(:user)    { create(:user) }
    let(:project) { create(:project, :repository, :wiki_repo) }
    let(:username) { 'slack_username' }
    let(:channel)  { 'slack_channel' }
    let(:issue_service_options) { { title: 'Awesome issue', description: 'please fix' } }

    let(:data) do
      Gitlab::DataBuilder::Push.build_sample(project, user)
    end

    let!(:stubbed_resolved_hostname) do
      stub_full_request(webhook_url, method: :post).request_pattern.uri_pattern.to_s
    end

    before do
      allow(chat_service).to receive_messages(
        project: project,
        project_id: project.id,
        service_hook: true,
        webhook: webhook_url
      )

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

    it "calls #{service_name} API for push events" do
      chat_service.execute(data)

      expect(WebMock).to have_requested(:post, stubbed_resolved_hostname).once
    end

    it "calls #{service_name} API for issue events" do
      chat_service.execute(@issues_sample_data)

      expect(WebMock).to have_requested(:post, stubbed_resolved_hostname).once
    end

    it "calls #{service_name} API for merge requests events" do
      chat_service.execute(@merge_sample_data)

      expect(WebMock).to have_requested(:post, stubbed_resolved_hostname).once
    end

    it "calls #{service_name} API for wiki page events" do
      chat_service.execute(@wiki_page_sample_data)

      expect(WebMock).to have_requested(:post, stubbed_resolved_hostname).once
    end

    it "calls #{service_name} API for deployment events" do
      deployment_event_data = { object_kind: 'deployment' }

      chat_service.execute(deployment_event_data)

      expect(WebMock).to have_requested(:post, stubbed_resolved_hostname).once
    end

    it 'uses the username as an option for slack when configured' do
      allow(chat_service).to receive(:username).and_return(username)

      expect(Slack::Notifier).to receive(:new)
       .with(webhook_url, username: username, http_client: SlackService::Notifier::HTTPClient)
       .and_return(
         double(:slack_service).as_null_object
       )

      chat_service.execute(data)
    end

    it 'uses the channel as an option when it is configured' do
      allow(chat_service).to receive(:channel).and_return(channel)
      expect(Slack::Notifier).to receive(:new)
        .with(webhook_url, channel: channel, http_client: SlackService::Notifier::HTTPClient)
        .and_return(
          double(:slack_service).as_null_object
        )
      chat_service.execute(data)
    end

    context "event channels" do
      it "uses the right channel for push event" do
        chat_service.update(push_channel: "random")

        expect(Slack::Notifier).to receive(:new)
         .with(webhook_url, channel: "random", http_client: SlackService::Notifier::HTTPClient)
         .and_return(
           double(:slack_service).as_null_object
         )

        chat_service.execute(data)
      end

      it "uses the right channel for merge request event" do
        chat_service.update(merge_request_channel: "random")

        expect(Slack::Notifier).to receive(:new)
         .with(webhook_url, channel: "random", http_client: SlackService::Notifier::HTTPClient)
         .and_return(
           double(:slack_service).as_null_object
         )

        chat_service.execute(@merge_sample_data)
      end

      it "uses the right channel for issue event" do
        chat_service.update(issue_channel: "random")

        expect(Slack::Notifier).to receive(:new)
         .with(webhook_url, channel: "random", http_client: SlackService::Notifier::HTTPClient)
         .and_return(
           double(:slack_service).as_null_object
         )

        chat_service.execute(@issues_sample_data)
      end

      context 'for confidential issues' do
        let(:issue_service_options) { { title: 'Secret', confidential: true } }

        it "uses confidential issue channel" do
          chat_service.update(confidential_issue_channel: 'confidential')

          expect(Slack::Notifier).to execute_with_options(channel: 'confidential')

          chat_service.execute(@issues_sample_data)
        end

        it 'falls back to issue channel' do
          chat_service.update(issue_channel: 'fallback_channel')

          expect(Slack::Notifier).to execute_with_options(channel: 'fallback_channel')

          chat_service.execute(@issues_sample_data)
        end
      end

      it "uses the right channel for wiki event" do
        chat_service.update(wiki_page_channel: "random")

        expect(Slack::Notifier).to receive(:new)
         .with(webhook_url, channel: "random", http_client: SlackService::Notifier::HTTPClient)
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
          chat_service.update(note_channel: "random")

          note_data = Gitlab::DataBuilder::Note.build(issue_note, user)

          expect(Slack::Notifier).to receive(:new)
           .with(webhook_url, channel: "random", http_client: SlackService::Notifier::HTTPClient)
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
            chat_service.update(confidential_note_channel: "confidential")

            note_data = Gitlab::DataBuilder::Note.build(issue_note, user)

            expect(Slack::Notifier).to execute_with_options(channel: 'confidential')

            chat_service.execute(note_data)
          end

          it 'falls back to note channel' do
            chat_service.update(note_channel: "fallback_channel")

            note_data = Gitlab::DataBuilder::Note.build(issue_note, user)

            expect(Slack::Notifier).to execute_with_options(channel: 'fallback_channel')

            chat_service.execute(note_data)
          end
        end
      end
    end
  end

  describe 'Push events' do
    let(:user) { create(:user) }
    let(:project) { create(:project, :repository, creator: user) }

    before do
      allow(chat_service).to receive_messages(
        project: project,
        service_hook: true,
        webhook: webhook_url
      )

      stub_full_request(webhook_url, method: :post)
    end

    context 'on default branch' do
      let(:data) do
        Gitlab::DataBuilder::Push.build(
          project: project,
          user: user,
          ref: project.default_branch
        )
      end

      context 'pushing tags' do
        let(:data) do
          Gitlab::DataBuilder::Push.build(
            project: project,
            user: user,
            ref: "#{Gitlab::Git::TAG_REF_PREFIX}test"
          )
        end

        it_behaves_like "triggered #{service_name} service", event_type: "push"
      end

      context 'notification enabled only for default branch' do
        it_behaves_like "triggered #{service_name} service", event_type: "push", branches_to_be_notified: "default"
      end

      context 'notification enabled only for protected branches' do
        it_behaves_like "untriggered #{service_name} service", event_type: "push", branches_to_be_notified: "protected"
      end

      context 'notification enabled only for default and protected branches' do
        it_behaves_like "triggered #{service_name} service", event_type: "push", branches_to_be_notified: "default_and_protected"
      end

      context 'notification enabled for all branches' do
        it_behaves_like "triggered #{service_name} service", event_type: "push", branches_to_be_notified: "all"
      end
    end

    context 'on a protected branch' do
      before do
        create(:protected_branch, project: project, name: 'a-protected-branch')
      end

      let(:data) do
        Gitlab::DataBuilder::Push.build(
          project: project,
          user: user,
          ref: 'a-protected-branch'
        )
      end

      context 'pushing tags' do
        let(:data) do
          Gitlab::DataBuilder::Push.build(
            project: project,
            user: user,
            ref: "#{Gitlab::Git::TAG_REF_PREFIX}test"
          )
        end

        it_behaves_like "triggered #{service_name} service", event_type: "push"
      end

      context 'notification enabled only for default branch' do
        it_behaves_like "untriggered #{service_name} service", event_type: "push", branches_to_be_notified: "default"
      end

      context 'notification enabled only for protected branches' do
        it_behaves_like "triggered #{service_name} service", event_type: "push", branches_to_be_notified: "protected"
      end

      context 'notification enabled only for default and protected branches' do
        it_behaves_like "triggered #{service_name} service", event_type: "push", branches_to_be_notified: "default_and_protected"
      end

      context 'notification enabled for all branches' do
        it_behaves_like "triggered #{service_name} service", event_type: "push", branches_to_be_notified: "all"
      end
    end

    context 'on a neither protected nor default branch' do
      let(:data) do
        Gitlab::DataBuilder::Push.build(
          project: project,
          user: user,
          ref: 'a-random-branch'
        )
      end

      context 'pushing tags' do
        let(:data) do
          Gitlab::DataBuilder::Push.build(
            project: project,
            user: user,
            ref: "#{Gitlab::Git::TAG_REF_PREFIX}test"
          )
        end

        it_behaves_like "triggered #{service_name} service", event_type: "push"
      end

      context 'notification enabled only for default branch' do
        it_behaves_like "untriggered #{service_name} service", event_type: "push", branches_to_be_notified: "default"
      end

      context 'notification enabled only for protected branches' do
        it_behaves_like "untriggered #{service_name} service", event_type: "push", branches_to_be_notified: "protected"
      end

      context 'notification enabled only for default and protected branches' do
        it_behaves_like "untriggered #{service_name} service", event_type: "push", branches_to_be_notified: "default_and_protected"
      end

      context 'notification enabled for all branches' do
        it_behaves_like "triggered #{service_name} service", event_type: "push", branches_to_be_notified: "all"
      end
    end
  end

  describe 'Note events' do
    let(:user) { create(:user) }
    let(:project) { create(:project, :repository, creator: user) }

    before do
      allow(chat_service).to receive_messages(
        project: project,
        service_hook: true,
        webhook: webhook_url
      )

      stub_full_request(webhook_url, method: :post)
    end

    context 'when commit comment event executed' do
      let(:commit_note) do
        create(:note_on_commit, author: user,
                                project: project,
                                commit_id: project.repository.commit.id,
                                note: 'a comment on a commit')
      end

      let(:data) do
        Gitlab::DataBuilder::Note.build(commit_note, user)
      end

      it_behaves_like "triggered #{service_name} service", event_type: "commit comment"
    end

    context 'when merge request comment event executed' do
      let(:merge_request_note) do
        create(:note_on_merge_request, project: project,
                                       note: 'a comment on a merge request')
      end

      let(:data) do
        Gitlab::DataBuilder::Note.build(merge_request_note, user)
      end

      it_behaves_like "triggered #{service_name} service", event_type: "merge request comment"
    end

    context 'when issue comment event executed' do
      let(:issue_note) do
        create(:note_on_issue, project: project,
                               note: 'a comment on an issue')
      end

      let(:data) do
        Gitlab::DataBuilder::Note.build(issue_note, user)
      end

      it_behaves_like "triggered #{service_name} service", event_type: "issue comment"
    end

    context 'when snippet comment event executed' do
      let(:snippet_note) do
        create(:note_on_project_snippet, project: project,
                                         note: 'a comment on a snippet')
      end

      let(:data) do
        Gitlab::DataBuilder::Note.build(snippet_note, user)
      end

      it_behaves_like "triggered #{service_name} service", event_type: "snippet comment"
    end
  end

  describe 'Pipeline events' do
    let(:user) { create(:user) }
    let(:project) { create(:project, :repository, creator: user) }
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

      stub_full_request(webhook_url, method: :post)
    end

    context 'with succeeded pipeline' do
      let(:status) { 'success' }
      let(:data) { Gitlab::DataBuilder::Pipeline.build(pipeline) }

      context 'with default to notify_only_broken_pipelines' do
        it_behaves_like "untriggered #{service_name} service", event_type: "pipeline"
      end

      context 'with setting notify_only_broken_pipelines to false' do
        before do
          chat_service.notify_only_broken_pipelines = false
        end

        it_behaves_like "triggered #{service_name} service", event_type: "pipeline"
      end
    end

    context 'with failed pipeline' do
      context 'on default branch' do
        let(:pipeline) do
          create(:ci_pipeline,
                project: project, status: :failed,
                sha: project.commit.sha, ref: project.default_branch)
        end

        let(:data) { Gitlab::DataBuilder::Pipeline.build(pipeline) }

        context 'notification enabled only for default branch' do
          it_behaves_like "triggered #{service_name} service", event_type: "pipeline", branches_to_be_notified: "default"
        end

        context 'notification enabled only for protected branches' do
          it_behaves_like "untriggered #{service_name} service", event_type: "pipeline", branches_to_be_notified: "protected"
        end

        context 'notification enabled only for default and protected branches' do
          it_behaves_like "triggered #{service_name} service", event_type: "pipeline", branches_to_be_notified: "default_and_protected"
        end

        context 'notification enabled for all branches' do
          it_behaves_like "triggered #{service_name} service", event_type: "pipeline", branches_to_be_notified: "all"
        end
      end

      context 'on a protected branch' do
        before do
          create(:protected_branch, project: project, name: 'a-protected-branch')
        end

        let(:pipeline) do
          create(:ci_pipeline,
                project: project, status: :failed,
                sha: project.commit.sha, ref: 'a-protected-branch')
        end

        let(:data) { Gitlab::DataBuilder::Pipeline.build(pipeline) }

        context 'notification enabled only for default branch' do
          it_behaves_like "untriggered #{service_name} service", event_type: "pipeline", branches_to_be_notified: "default"
        end

        context 'notification enabled only for protected branches' do
          it_behaves_like "triggered #{service_name} service", event_type: "pipeline", branches_to_be_notified: "protected"
        end

        context 'notification enabled only for default and protected branches' do
          it_behaves_like "triggered #{service_name} service", event_type: "pipeline", branches_to_be_notified: "default_and_protected"
        end

        context 'notification enabled for all branches' do
          it_behaves_like "triggered #{service_name} service", event_type: "pipeline", branches_to_be_notified: "all"
        end
      end

      context 'on a neither protected nor default branch' do
        let(:pipeline) do
          create(:ci_pipeline,
                project: project, status: :failed,
                sha: project.commit.sha, ref: 'a-random-branch')
        end

        let(:data) { Gitlab::DataBuilder::Pipeline.build(pipeline) }

        context 'notification enabled only for default branch' do
          it_behaves_like "untriggered #{service_name} service", event_type: "pipeline", branches_to_be_notified: "default"
        end

        context 'notification enabled only for protected branches' do
          it_behaves_like "untriggered #{service_name} service", event_type: "pipeline", branches_to_be_notified: "protected"
        end

        context 'notification enabled only for default and protected branches' do
          it_behaves_like "untriggered #{service_name} service", event_type: "pipeline", branches_to_be_notified: "default_and_protected"
        end

        context 'notification enabled for all branches' do
          it_behaves_like "triggered #{service_name} service", event_type: "pipeline", branches_to_be_notified: "all"
        end
      end
    end
  end
end
