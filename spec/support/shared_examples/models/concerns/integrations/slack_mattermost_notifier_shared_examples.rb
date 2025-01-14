# frozen_string_literal: true

RSpec.shared_examples Integrations::SlackMattermostNotifier do |integration_name|
  include StubRequests

  let(:chat_integration) { described_class.new }
  let(:webhook_url) { 'https://example.gitlab.com' }

  def execute_with_options(options)
    receive(:new).with(webhook_url, options.merge(http_client: Integrations::SlackMattermostNotifier::HTTPClient))
     .and_return(double(:slack_integration).as_null_object)
  end

  describe "Associations" do
    it { is_expected.to belong_to :project }
  end

  describe 'Validations' do
    context 'when integration is active' do
      before do
        subject.active = true
      end

      it { is_expected.to validate_presence_of(:webhook) }

      it_behaves_like 'issue tracker integration URL attribute', :webhook
    end

    context 'when integration is inactive' do
      before do
        subject.active = false
      end

      it { is_expected.not_to validate_presence_of(:webhook) }
    end
  end

  shared_examples "triggered #{integration_name} integration" do |event_type: nil, branches_to_be_notified: nil|
    before do
      chat_integration.branches_to_be_notified = branches_to_be_notified if branches_to_be_notified
    end

    let!(:stubbed_resolved_hostname) do
      stub_full_request(webhook_url, method: :post).request_pattern.uri_pattern.to_s
    end

    it "notifies about #{event_type} events" do
      expect(chat_integration).not_to receive(:log_error)

      chat_integration.execute(data)

      expect(WebMock).to have_requested(:post, stubbed_resolved_hostname)
    end

    context 'when the response is not successful' do
      let!(:stubbed_resolved_hostname) do
        stub_full_request(webhook_url, method: :post)
          .to_return(status: 409, body: 'error message')
          .request_pattern.uri_pattern.to_s
      end

      it 'logs an error' do
        expect(chat_integration).to receive(:log_error).with(
          'SlackMattermostNotifier HTTP error response',
          request_host: 'example.gitlab.com',
          response_code: 409,
          response_body: 'error message'
        )

        chat_integration.execute(data)

        expect(WebMock).to have_requested(:post, stubbed_resolved_hostname)
      end
    end
  end

  shared_examples "untriggered #{integration_name} integration" do |event_type: nil, branches_to_be_notified: nil|
    before do
      chat_integration.branches_to_be_notified = branches_to_be_notified if branches_to_be_notified
    end

    let!(:stubbed_resolved_hostname) do
      stub_full_request(webhook_url, method: :post).request_pattern.uri_pattern.to_s
    end

    it "does not notify about #{event_type} events" do
      chat_integration.execute(data)

      expect(WebMock).not_to have_requested(:post, stubbed_resolved_hostname)
    end
  end

  describe "#execute" do
    let_it_be(:project) { create(:project, :repository, :wiki_repo) }
    let_it_be(:user) { create(:user) }

    let(:chat_integration) { described_class.new({ project: project, webhook: webhook_url, branches_to_be_notified: 'all' }.merge(chat_integration_params)) }
    let(:chat_integration_params) { {} }
    let(:data) { Gitlab::DataBuilder::Push.build_sample(project, user) }

    let!(:stubbed_resolved_hostname) do
      stub_full_request(webhook_url, method: :post).request_pattern.uri_pattern.to_s
    end

    subject(:execute_integration) { chat_integration.execute(data) }

    shared_examples 'calls the integration API with the event message' do |event_message|
      specify do
        expect_next_instance_of(::Slack::Messenger) do |messenger|
          expect(messenger).to receive(:ping).with(event_message, anything).and_call_original
        end

        execute_integration

        expect(WebMock).to have_requested(:post, stubbed_resolved_hostname).once
      end
    end

    context 'with username for slack configured' do
      let(:chat_integration_params) { { username: 'slack_username' } }

      it 'uses the username as an option' do
        expect(::Slack::Messenger).to execute_with_options(username: 'slack_username')

        execute_integration
      end
    end

    context 'push events' do
      let(:data) { Gitlab::DataBuilder::Push.build_sample(project, user) }

      it_behaves_like 'calls the integration API with the event message', /pushed to branch/

      context 'with event channel' do
        let(:chat_integration_params) { { push_channel: 'random' } }

        it 'uses the right channel for push event' do
          expect(::Slack::Messenger).to execute_with_options(channel: ['random'])

          execute_integration
        end
      end
    end

    context 'tag_push events' do
      let(:oldrev) { Gitlab::Git::SHA1_BLANK_SHA }
      let(:newrev) { '8a2a6eb295bb170b34c24c76c49ed0e9b2eaf34b' } # gitlab-test: git rev-parse refs/tags/v1.1.0
      let(:ref) { 'refs/tags/v1.1.0' }
      let(:data) { Git::TagHooksService.new(project, user, change: { oldrev: oldrev, newrev: newrev, ref: ref }).send(:push_data) }

      it_behaves_like 'calls the integration API with the event message', /pushed new tag/
    end

    context 'issue events' do
      let_it_be(:issue) { create(:issue, project: project) }

      let(:data) { issue.to_hook_data(user) }

      it_behaves_like 'calls the integration API with the event message', /Issue (.*?) opened by/

      context 'whith event channel' do
        let(:chat_integration_params) { { issue_channel: 'random' } }

        it 'uses the right channel for issue event' do
          expect(::Slack::Messenger).to execute_with_options(channel: ['random'])

          execute_integration
        end

        context 'for confidential issues' do
          before_all do
            issue.update!(confidential: true)
          end

          it 'falls back to issue channel' do
            expect(::Slack::Messenger).to execute_with_options(channel: ['random'])

            execute_integration
          end

          context 'and confidential_issue_channel is defined' do
            let(:chat_integration_params) { { issue_channel: 'random', confidential_issue_channel: 'confidential' } }

            it 'uses the confidential issue channel when it is defined' do
              expect(::Slack::Messenger).to execute_with_options(channel: ['confidential'])

              execute_integration
            end
          end
        end
      end
    end

    context 'merge request events' do
      let_it_be(:merge_request) { create(:merge_request, source_project: project) }

      let(:data) { merge_request.to_hook_data(user) }

      it_behaves_like 'calls the integration API with the event message', /opened merge request/

      context 'with event channel' do
        let(:chat_integration_params) { { merge_request_channel: 'random' } }

        it 'uses the right channel for merge request event' do
          expect(::Slack::Messenger).to execute_with_options(channel: ['random'])

          execute_integration
        end
      end
    end

    context 'wiki page events' do
      let_it_be(:wiki_page) { create(:wiki_page, wiki: project.wiki, project: project, message: 'user created page: Awesome wiki_page') }

      let(:data) { Gitlab::DataBuilder::WikiPage.build(wiki_page, user, 'create') }

      it_behaves_like 'calls the integration API with the event message', %r{ created (.*?)wikis/(.*?)|wiki page> in}

      context 'with event channel' do
        let(:chat_integration_params) { { wiki_page_channel: 'random' } }

        it 'uses the right channel for wiki event' do
          expect(::Slack::Messenger).to execute_with_options(channel: ['random'])

          execute_integration
        end
      end
    end

    context 'deployment events' do
      let_it_be(:deployment) { create(:deployment, project: project) }

      let(:data) { Gitlab::DataBuilder::Deployment.build(deployment, 'created', Time.current) }

      it_behaves_like 'calls the integration API with the event message', /Deploy to (.*?) created/
    end

    context 'note event' do
      let_it_be(:issue_note) { create(:note_on_issue, project: project, note: "issue note") }

      let(:data) { Gitlab::DataBuilder::Note.build(issue_note, user, :create) }

      it_behaves_like 'calls the integration API with the event message', /commented on issue/

      context 'with event channel' do
        let(:chat_integration_params) { { note_channel: 'random' } }

        it 'uses the right channel' do
          expect(::Slack::Messenger).to execute_with_options(channel: ['random'])

          execute_integration
        end

        context 'for confidential notes' do
          let_it_be(:issue_note) { create(:note_on_issue, project: project, note: "issue note", confidential: true) }

          it 'falls back to note channel' do
            expect(::Slack::Messenger).to execute_with_options(channel: ['random'])

            execute_integration
          end

          context 'and confidential_note_channel is defined' do
            let(:chat_integration_params) { { note_channel: 'random', confidential_note_channel: 'confidential' } }

            it 'uses confidential channel' do
              expect(::Slack::Messenger).to execute_with_options(channel: ['confidential'])

              execute_integration
            end
          end
        end
      end
    end
  end

  describe 'Push events' do
    let_it_be(:user) { create(:user) }
    let_it_be_with_refind(:project) { create(:project, :repository, creator: user) }

    before do
      allow(chat_integration).to receive_messages(
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

        it_behaves_like "triggered #{integration_name} integration", event_type: "push"
      end

      context 'notification enabled only for default branch' do
        it_behaves_like "triggered #{integration_name} integration", event_type: "push", branches_to_be_notified: "default"
      end

      context 'notification enabled only for protected branches' do
        it_behaves_like "untriggered #{integration_name} integration", event_type: "push", branches_to_be_notified: "protected"
      end

      context 'notification enabled only for default and protected branches' do
        it_behaves_like "triggered #{integration_name} integration", event_type: "push", branches_to_be_notified: "default_and_protected"
      end

      context 'notification enabled for all branches' do
        it_behaves_like "triggered #{integration_name} integration", event_type: "push", branches_to_be_notified: "all"
      end
    end

    context 'on a protected branch' do
      before_all do
        create(:protected_branch, :create_branch_on_repository, project: project, name: 'a-protected-branch')
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

        it_behaves_like "triggered #{integration_name} integration", event_type: "push"
      end

      context 'notification enabled only for default branch' do
        it_behaves_like "untriggered #{integration_name} integration", event_type: "push", branches_to_be_notified: "default"
      end

      context 'notification enabled only for protected branches' do
        it_behaves_like "triggered #{integration_name} integration", event_type: "push", branches_to_be_notified: "protected"
      end

      context 'notification enabled only for default and protected branches' do
        it_behaves_like "triggered #{integration_name} integration", event_type: "push", branches_to_be_notified: "default_and_protected"
      end

      context 'notification enabled for all branches' do
        it_behaves_like "triggered #{integration_name} integration", event_type: "push", branches_to_be_notified: "all"
      end
    end

    context 'on a protected branch with protected branches defined using wildcards' do
      before_all do
        create(:protected_branch, :create_branch_on_repository, repository_branch_name: '1-stable', project: project, name: '*-stable')
      end

      let(:data) do
        Gitlab::DataBuilder::Push.build(
          project: project,
          user: user,
          ref: '1-stable'
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

        it_behaves_like "triggered #{integration_name} integration", event_type: "push"
      end

      context 'notification enabled only for default branch' do
        it_behaves_like "untriggered #{integration_name} integration", event_type: "push", branches_to_be_notified: "default"
      end

      context 'notification enabled only for protected branches' do
        it_behaves_like "triggered #{integration_name} integration", event_type: "push", branches_to_be_notified: "protected"
      end

      context 'notification enabled only for default and protected branches' do
        it_behaves_like "triggered #{integration_name} integration", event_type: "push", branches_to_be_notified: "default_and_protected"
      end

      context 'notification enabled for all branches' do
        it_behaves_like "triggered #{integration_name} integration", event_type: "push", branches_to_be_notified: "all"
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

        it_behaves_like "triggered #{integration_name} integration", event_type: "push"
      end

      context 'notification enabled only for default branch' do
        it_behaves_like "untriggered #{integration_name} integration", event_type: "push", branches_to_be_notified: "default"
      end

      context 'notification enabled only for protected branches' do
        it_behaves_like "untriggered #{integration_name} integration", event_type: "push", branches_to_be_notified: "protected"
      end

      context 'notification enabled only for default and protected branches' do
        it_behaves_like "untriggered #{integration_name} integration", event_type: "push", branches_to_be_notified: "default_and_protected"
      end

      context 'notification enabled for all branches' do
        it_behaves_like "triggered #{integration_name} integration", event_type: "push", branches_to_be_notified: "all"
      end
    end
  end

  describe 'Note events' do
    let_it_be(:user) { create(:user) }
    let_it_be_with_reload(:project) { create(:project, :repository, creator: user) }

    before do
      allow(chat_integration).to receive_messages(
        project: project,
        service_hook: true,
        webhook: webhook_url
      )

      stub_full_request(webhook_url, method: :post)
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

      let(:data) do
        Gitlab::DataBuilder::Note.build(commit_note, user, :create)
      end

      it_behaves_like "triggered #{integration_name} integration", event_type: "commit comment"
    end

    context 'when merge request comment event executed' do
      let(:merge_request_note) do
        create(:note_on_merge_request, project: project, note: 'a comment on a merge request')
      end

      let(:data) do
        Gitlab::DataBuilder::Note.build(merge_request_note, user, :create)
      end

      it_behaves_like "triggered #{integration_name} integration", event_type: "merge request comment"
    end

    context 'when issue comment event executed' do
      let(:issue_note) do
        create(:note_on_issue, project: project, note: 'a comment on an issue')
      end

      let(:data) do
        Gitlab::DataBuilder::Note.build(issue_note, user, :create)
      end

      it_behaves_like "triggered #{integration_name} integration", event_type: "issue comment"
    end

    context 'when snippet comment event executed' do
      let(:snippet_note) do
        create(:note_on_project_snippet, project: project, note: 'a comment on a snippet')
      end

      let(:data) do
        Gitlab::DataBuilder::Note.build(snippet_note, user, :create)
      end

      it_behaves_like "triggered #{integration_name} integration", event_type: "snippet comment"
    end
  end

  describe 'Pipeline events' do
    let_it_be(:user) { create(:user) }
    let_it_be_with_refind(:project) { create(:project, :repository, creator: user) }
    let(:pipeline) do
      create(:ci_pipeline, project: project, status: status, sha: project.commit.sha, ref: project.default_branch)
    end

    before do
      allow(chat_integration).to receive_messages(
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
        it_behaves_like "untriggered #{integration_name} integration", event_type: "pipeline"
      end

      context 'with setting notify_only_broken_pipelines to false' do
        before do
          chat_integration.notify_only_broken_pipelines = false
        end

        it_behaves_like "triggered #{integration_name} integration", event_type: "pipeline"
      end
    end

    context 'with failed pipeline' do
      context 'on default branch' do
        let(:pipeline) do
          create(:ci_pipeline, project: project, status: :failed, sha: project.commit.sha, ref: project.default_branch)
        end

        let(:data) { Gitlab::DataBuilder::Pipeline.build(pipeline) }

        context 'notification enabled only for default branch' do
          it_behaves_like "triggered #{integration_name} integration", event_type: "pipeline", branches_to_be_notified: "default"
        end

        context 'notification enabled only for protected branches' do
          it_behaves_like "untriggered #{integration_name} integration", event_type: "pipeline", branches_to_be_notified: "protected"
        end

        context 'notification enabled only for default and protected branches' do
          it_behaves_like "triggered #{integration_name} integration", event_type: "pipeline", branches_to_be_notified: "default_and_protected"
        end

        context 'notification enabled for all branches' do
          it_behaves_like "triggered #{integration_name} integration", event_type: "pipeline", branches_to_be_notified: "all"
        end
      end

      context 'on a protected branch' do
        before_all do
          create(:protected_branch, :create_branch_on_repository, project: project, name: 'a-protected-branch')
        end

        let(:pipeline) do
          create(:ci_pipeline, project: project, status: :failed, sha: project.commit.sha, ref: 'a-protected-branch')
        end

        let(:data) { Gitlab::DataBuilder::Pipeline.build(pipeline) }

        context 'notification enabled only for default branch' do
          it_behaves_like "untriggered #{integration_name} integration", event_type: "pipeline", branches_to_be_notified: "default"
        end

        context 'notification enabled only for protected branches' do
          it_behaves_like "triggered #{integration_name} integration", event_type: "pipeline", branches_to_be_notified: "protected"
        end

        context 'notification enabled only for default and protected branches' do
          it_behaves_like "triggered #{integration_name} integration", event_type: "pipeline", branches_to_be_notified: "default_and_protected"
        end

        context 'notification enabled for all branches' do
          it_behaves_like "triggered #{integration_name} integration", event_type: "pipeline", branches_to_be_notified: "all"
        end
      end

      context 'on a protected branch with protected branches defined usin wildcards' do
        before_all do
          create(:protected_branch, :create_branch_on_repository, repository_branch_name: '1-stable', project: project, name: '*-stable')
        end

        let(:pipeline) do
          create(:ci_pipeline, project: project, status: :failed, sha: project.commit.sha, ref: '1-stable')
        end

        let(:data) { Gitlab::DataBuilder::Pipeline.build(pipeline) }

        context 'notification enabled only for default branch' do
          it_behaves_like "untriggered #{integration_name} integration", event_type: "pipeline", branches_to_be_notified: "default"
        end

        context 'notification enabled only for protected branches' do
          it_behaves_like "triggered #{integration_name} integration", event_type: "pipeline", branches_to_be_notified: "protected"
        end

        context 'notification enabled only for default and protected branches' do
          it_behaves_like "triggered #{integration_name} integration", event_type: "pipeline", branches_to_be_notified: "default_and_protected"
        end

        context 'notification enabled for all branches' do
          it_behaves_like "triggered #{integration_name} integration", event_type: "pipeline", branches_to_be_notified: "all"
        end
      end

      context 'on a neither protected nor default branch' do
        let(:pipeline) do
          create(:ci_pipeline, project: project, status: :failed, sha: project.commit.sha, ref: 'a-random-branch')
        end

        let(:data) { Gitlab::DataBuilder::Pipeline.build(pipeline) }

        context 'notification enabled only for default branch' do
          it_behaves_like "untriggered #{integration_name} integration", event_type: "pipeline", branches_to_be_notified: "default"
        end

        context 'notification enabled only for protected branches' do
          it_behaves_like "untriggered #{integration_name} integration", event_type: "pipeline", branches_to_be_notified: "protected"
        end

        context 'notification enabled only for default and protected branches' do
          it_behaves_like "untriggered #{integration_name} integration", event_type: "pipeline", branches_to_be_notified: "default_and_protected"
        end

        context 'notification enabled for all branches' do
          it_behaves_like "triggered #{integration_name} integration", event_type: "pipeline", branches_to_be_notified: "all"
        end
      end
    end
  end

  describe 'Deployment events' do
    let_it_be(:user) { create(:user) }
    let_it_be_with_refind(:project) { create(:project, :repository, creator: user) }

    let_it_be(:deployment) do
      create(:deployment, :success, project: project, sha: project.commit.sha, ref: project.default_branch)
    end

    let(:data) { Gitlab::DataBuilder::Deployment.build(deployment, deployment.status, Time.now) }

    before do
      allow(chat_integration).to receive_messages(
        project: project,
        service_hook: true,
        webhook: webhook_url
      )

      stub_full_request(webhook_url, method: :post)
    end

    it_behaves_like "triggered #{integration_name} integration", event_type: "deployment"

    context 'on a protected branch' do
      before_all do
        create(:protected_branch, :create_branch_on_repository, project: project, name: 'a-protected-branch')
      end

      let_it_be(:deployment) do
        create(:deployment, :success, project: project, sha: project.commit.sha, ref: 'a-protected-branch')
      end

      context 'notification enabled only for default branch' do
        it_behaves_like "untriggered #{integration_name} integration", event_type: "pipeline", branches_to_be_notified: "default"
      end

      context 'notification enabled only for protected branches' do
        it_behaves_like "triggered #{integration_name} integration", event_type: "pipeline", branches_to_be_notified: "protected"
      end

      context 'notification enabled only for default and protected branches' do
        it_behaves_like "triggered #{integration_name} integration", event_type: "pipeline", branches_to_be_notified: "default_and_protected"
      end

      context 'notification enabled for all branches' do
        it_behaves_like "triggered #{integration_name} integration", event_type: "pipeline", branches_to_be_notified: "all"
      end
    end
  end
end
