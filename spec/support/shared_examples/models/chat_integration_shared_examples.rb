# frozen_string_literal: true

RSpec.shared_examples "chat integration" do |integration_name, supports_deployments: false, http_method: :post|
  describe "Associations" do
    it { is_expected.to belong_to :project }
  end

  describe "Validations" do
    context "when integration is active" do
      before do
        subject.active = true
      end

      it { is_expected.to validate_presence_of(:webhook) }

      it_behaves_like "issue tracker integration URL attribute", :webhook
    end

    context "when integration is inactive" do
      before do
        subject.active = false
      end

      it { is_expected.not_to validate_presence_of(:webhook) }
    end
  end

  describe '.supported_events' do
    if supports_deployments
      it 'supports deployment_events' do
        expect(described_class.supported_events).to include('deployment')
      end
    else
      it 'does not support deployment_events' do
        expect(described_class.supported_events).not_to include('deployment')
      end
    end
  end

  describe "#execute" do
    let_it_be(:user) { create(:user) }
    let_it_be_with_refind(:project) { create(:project, :repository) }

    let(:webhook_url) { "https://example.gitlab.com/" }
    let(:webhook_url_regex) { /\A#{webhook_url}.*/ }

    before do
      allow(subject).to receive_messages(
        project: project,
        project_id: project.id,
        service_hook: true,
        webhook: webhook_url
      )

      WebMock.stub_request(http_method, webhook_url_regex)
    end

    shared_examples "triggered #{integration_name} integration" do |branches_to_be_notified: nil|
      before do
        subject.branches_to_be_notified = branches_to_be_notified if branches_to_be_notified
      end

      it "calls #{integration_name} API" do
        result = subject.execute(sample_data)

        expect(result).to be(true)
        expect(WebMock).to have_requested(http_method, webhook_url_regex).once.with { |req|
          json_body = Gitlab::Json.parse(req.body).with_indifferent_access
          expect(json_body).to include(payload)
        }
      end
    end

    shared_examples "untriggered #{integration_name} integration" do |branches_to_be_notified: nil|
      before do
        subject.branches_to_be_notified = branches_to_be_notified if branches_to_be_notified
      end

      it "does not call #{integration_name} API" do
        result = subject.execute(sample_data)

        expect(result).to be_falsy
        expect(WebMock).not_to have_requested(http_method, webhook_url_regex)
      end
    end

    context "with push events" do
      let(:sample_data) do
        Gitlab::DataBuilder::Push.build_sample(project, user)
      end

      it_behaves_like "triggered #{integration_name} integration"

      it "specifies the webhook when it is configured", if: defined?(client) do
        expect(client).to receive(:new).with(client_arguments).and_return(double(:chat_service).as_null_object)

        subject.execute(sample_data)
      end

      context "with default branch" do
        let(:sample_data) do
          Gitlab::DataBuilder::Push.build(project: project, user: user, ref: project.default_branch)
        end

        context "when only default branch are to be notified" do
          it_behaves_like "triggered #{integration_name} integration", branches_to_be_notified: "default"
        end

        context "when only protected branches are to be notified" do
          it_behaves_like "untriggered #{integration_name} integration", branches_to_be_notified: "protected"
        end

        context "when default and protected branches are to be notified" do
          it_behaves_like "triggered #{integration_name} integration", branches_to_be_notified: "default_and_protected"
        end

        context "when all branches are to be notified" do
          it_behaves_like "triggered #{integration_name} integration", branches_to_be_notified: "all"
        end
      end

      context "with protected branch" do
        let(:sample_data) do
          Gitlab::DataBuilder::Push.build(project: project, user: user, ref: "a-protected-branch")
        end

        before_all do
          create(:protected_branch, :create_branch_on_repository, project: project, name: "a-protected-branch")
        end

        context "when only default branch are to be notified" do
          it_behaves_like "untriggered #{integration_name} integration", branches_to_be_notified: "default"
        end

        context "when only protected branches are to be notified" do
          it_behaves_like "triggered #{integration_name} integration", branches_to_be_notified: "protected"
        end

        context "when default and protected branches are to be notified" do
          it_behaves_like "triggered #{integration_name} integration", branches_to_be_notified: "default_and_protected"
        end

        context "when all branches are to be notified" do
          it_behaves_like "triggered #{integration_name} integration", branches_to_be_notified: "all"
        end
      end

      context "with neither default nor protected branch" do
        let(:sample_data) do
          Gitlab::DataBuilder::Push.build(project: project, user: user, ref: "a-random-branch")
        end

        context "when only default branch are to be notified" do
          it_behaves_like "untriggered #{integration_name} integration", branches_to_be_notified: "default"
        end

        context "when only protected branches are to be notified" do
          it_behaves_like "untriggered #{integration_name} integration", branches_to_be_notified: "protected"
        end

        context "when default and protected branches are to be notified" do
          it_behaves_like "untriggered #{integration_name} integration", branches_to_be_notified: "default_and_protected"
        end

        context "when all branches are to be notified" do
          it_behaves_like "triggered #{integration_name} integration", branches_to_be_notified: "all"
        end
      end
    end

    context "with issue events" do
      let(:opts) { { title: "Awesome issue", description: "please fix" } }
      let(:sample_data) do
        service = Issues::CreateService.new(container: project, current_user: user, params: opts)
        issue = service.execute[:issue]
        service.hook_data(issue, "open")
      end

      before do
        project.add_developer(user)
      end

      it_behaves_like "triggered #{integration_name} integration"
    end

    context "with merge events" do
      let(:opts) do
        {
          title: "Awesome merge_request",
          description: "please fix",
          source_branch: "feature",
          target_branch: "master"
        }
      end

      let(:sample_data) do
        service = MergeRequests::CreateService.new(project: project, current_user: user, params: opts)
        merge_request = service.execute
        service.hook_data(merge_request, "open")
      end

      before do
        project.add_developer(user)
      end

      it_behaves_like "triggered #{integration_name} integration"
    end

    context "with wiki page events" do
      let(:opts) do
        {
          title: "Awesome wiki_page",
          content: "Some text describing some thing or another",
          format: :markdown,
          message: "user created page: Awesome wiki_page"
        }
      end

      let(:wiki_page) { create(:wiki_page, wiki: project.wiki, **opts) }
      let(:sample_data) { Gitlab::DataBuilder::WikiPage.build(wiki_page, user, "create") }

      it_behaves_like "triggered #{integration_name} integration"
    end

    context "with note events" do
      let(:sample_data) { Gitlab::DataBuilder::Note.build(note, user, :create) }

      context "with commit comment" do
        let_it_be(:note) do
          create(
            :note_on_commit,
            author: user,
            project: project,
            commit_id: project.repository.commit.id,
            note: "a comment on a commit"
          )
        end

        it_behaves_like "triggered #{integration_name} integration"
      end

      context "with merge request comment" do
        let_it_be(:note) do
          create(:note_on_merge_request, project: project, note: "merge request note")
        end

        it_behaves_like "triggered #{integration_name} integration"
      end

      context "with issue comment" do
        let_it_be(:note) do
          create(:note_on_issue, project: project, note: "issue note")
        end

        it_behaves_like "triggered #{integration_name} integration"
      end

      context "with snippet comment" do
        let_it_be(:note) do
          create(:note_on_project_snippet, project: project, note: "snippet note")
        end

        it_behaves_like "triggered #{integration_name} integration"
      end
    end

    context "with pipeline events" do
      let(:sample_data) { Gitlab::DataBuilder::Pipeline.build(pipeline) }

      context "with failed pipeline" do
        let_it_be(:pipeline) do
          create(
            :ci_pipeline,
            project: project, status: "failed",
            sha: project.commit.sha, ref: project.default_branch
          )
        end

        it_behaves_like "triggered #{integration_name} integration"
      end

      context "with succeeded pipeline" do
        let_it_be(:pipeline) do
          create(
            :ci_pipeline,
            project: project, status: "success",
            sha: project.commit.sha, ref: project.default_branch
          )
        end

        context "with default notify_only_broken_pipelines" do
          it "does not call #{integration_name} API" do
            result = subject.execute(sample_data)

            expect(result).to be_falsy
          end
        end

        context "when notify_only_broken_pipelines is false" do
          before do
            subject.notify_only_broken_pipelines = false
          end

          it_behaves_like "triggered #{integration_name} integration"
        end
      end

      context "with default branch" do
        let(:sample_data) do
          Gitlab::DataBuilder::Push.build(project: project, user: user, ref: project.default_branch)
        end

        context "when only default branch are to be notified" do
          it_behaves_like "triggered #{integration_name} integration", branches_to_be_notified: "default"
        end

        context "when only protected branches are to be notified" do
          it_behaves_like "untriggered #{integration_name} integration", branches_to_be_notified: "protected"
        end

        context "when default and protected branches are to be notified" do
          it_behaves_like "triggered #{integration_name} integration", branches_to_be_notified: "default_and_protected"
        end

        context "when all branches are to be notified" do
          it_behaves_like "triggered #{integration_name} integration", branches_to_be_notified: "all"
        end
      end

      context "with protected branch" do
        before_all do
          create(:protected_branch, :create_branch_on_repository, project: project, name: "a-protected-branch")
        end

        let(:sample_data) do
          Gitlab::DataBuilder::Push.build(project: project, user: user, ref: "a-protected-branch")
        end

        context "when only default branch are to be notified" do
          it_behaves_like "untriggered #{integration_name} integration", branches_to_be_notified: "default"
        end

        context "when only protected branches are to be notified" do
          it_behaves_like "triggered #{integration_name} integration", branches_to_be_notified: "protected"
        end

        context "when default and protected branches are to be notified" do
          it_behaves_like "triggered #{integration_name} integration", branches_to_be_notified: "default_and_protected"
        end

        context "when all branches are to be notified" do
          it_behaves_like "triggered #{integration_name} integration", branches_to_be_notified: "all"
        end
      end

      context "with neither default nor protected branch" do
        let(:sample_data) do
          Gitlab::DataBuilder::Push.build(project: project, user: user, ref: "a-random-branch")
        end

        context "when only default branch are to be notified" do
          it_behaves_like "untriggered #{integration_name} integration", branches_to_be_notified: "default"
        end

        context "when only protected branches are to be notified" do
          it_behaves_like "untriggered #{integration_name} integration", branches_to_be_notified: "protected"
        end

        context "when default and protected branches are to be notified" do
          it_behaves_like "untriggered #{integration_name} integration", branches_to_be_notified: "default_and_protected"
        end

        context "when all branches are to be notified" do
          it_behaves_like "triggered #{integration_name} integration", branches_to_be_notified: "all"
        end
      end
    end

    context 'deployment events' do
      let_it_be(:deployment) { create(:deployment) }

      let(:sample_data) { Gitlab::DataBuilder::Deployment.build(deployment, deployment.status, Time.now) }

      if supports_deployments
        it_behaves_like "triggered #{integration_name} integration"
      else
        it_behaves_like "untriggered #{integration_name} integration"
      end
    end
  end
end

RSpec.shared_examples 'supports group mentions' do |integration_factory|
  it 'does not support group mentions for instance integrations' do
    allow(subject).to receive(:instance?).and_return(true)
    allow(subject).to receive(:webhook).and_return('http://example.com')

    expect(subject).not_to receive(:notify)

    subject.execute(
      object_kind: 'group_mention',
      object_attributes: { action: 'new', object_kind: 'issue' },
      mentioned: { name: 'John Doe', url: 'http://example.com' }
    )
  end

  it 'supports group mentions for non-instance integrations' do
    allow(subject).to receive(:instance?).and_return(false)
    allow(subject).to receive(:webhook).and_return('http://example.com')
    allow(subject).to receive(:group_level?).and_return(true)

    expect(subject).to receive(:notify).with(an_instance_of(Integrations::ChatMessage::GroupMentionMessage), {})

    subject.execute(
      object_kind: 'group_mention',
      object_attributes: { action: 'new', object_kind: 'issue' },
      mentioned: { name: 'John Doe', url: 'http://example.com' }
    )
  end

  describe '#supported_events' do
    context 'when used in a project' do
      let_it_be(:project) { create(:project) }
      let_it_be(:integration) { build(integration_factory, project: project) }

      it 'does not support group mentions', :aggregate_failures do
        expect(integration.supported_events).not_to include('group_mention')
        expect(integration.supported_events).not_to include('group_confidential_mention')
      end
    end

    context 'when used in a group' do
      let_it_be(:group) { create(:group) }
      let_it_be(:integration) { build(integration_factory, group: group) }

      it 'supports group mentions', :aggregate_failures do
        expect(integration.supported_events).to include('group_mention')
        expect(integration.supported_events).to include('group_confidential_mention')
      end
    end
  end
end
