# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Integrations::ChatMessage::DeploymentMessage, feature_category: :integrations do
  subject { described_class.new(args) }

  let_it_be(:user) { create(:user, name: 'John Smith', username: 'smith') }
  let_it_be(:namespace) { create(:namespace, name: 'myspace') }
  let_it_be(:project) { create(:project, :repository, namespace: namespace, path: 'myproject') }
  let_it_be(:commit) { project.commit('HEAD') }
  let_it_be(:ci_build) { create(:ci_build, project: project) }
  let_it_be(:environment) { create(:environment, name: 'myenvironment', project: project) }
  let_it_be(:deployment) { create(:deployment, status: :success, deployable: ci_build, environment: environment, project: project, user: user, sha: commit.sha) }

  let(:args) do
    Gitlab::DataBuilder::Deployment.build(deployment, 'success', Time.current)
  end

  it_behaves_like Integrations::ChatMessage

  def deployment_data(params)
    {
      object_kind: "deployment",
      status: "success",
      deployable_id: 3,
      deployable_url: "deployable_url",
      environment: "sandbox",
      project: {
        name: "greatproject",
        web_url: "project_web_url",
        path_with_namespace: "project_path_with_namespace"
      },
      user: {
        name: "Jane Person",
        username: "jane"
      },
      user_url: "user_url",
      short_sha: "12345678",
      commit_url: "commit_url",
      commit_title: "commit title text"
    }.merge(params)
  end

  describe '#pretext' do
    it 'returns a message with the data returned by the deployment data builder' do
      expect(subject.pretext).to eq("Deploy to myenvironment succeeded")
    end

    it 'returns a message for a successful deployment' do
      args.merge!(
        status: 'success',
        environment: 'production'
      )

      expect(subject.pretext).to eq('Deploy to production succeeded')
    end

    it 'returns a message for a failed deployment' do
      args.merge!(
        status: 'failed',
        environment: 'production'
      )

      expect(subject.pretext).to eq('Deploy to production failed')
    end

    it 'returns a message for a canceled deployment' do
      args.merge!(
        status: 'canceled',
        environment: 'production'
      )

      expect(subject.pretext).to eq('Deploy to production canceled')
    end

    it 'returns a message for a deployment to another environment' do
      args.merge!(
        status: 'success',
        environment: 'staging'
      )

      expect(subject.pretext).to eq('Deploy to staging succeeded')
    end

    it 'returns a message for a deployment with any other status' do
      args.merge!(
        status: 'unknown',
        environment: 'staging'
      )

      expect(subject.pretext).to eq('Deploy to staging unknown')
    end

    it 'returns a message for a running deployment' do
      args.merge!(
        status: 'running',
        environment: 'production'
      )

      expect(subject.pretext).to eq('Starting deploy to production')
    end
  end

  describe '#attachments' do
    context 'without markdown' do
      it 'returns attachments with the data returned by the deployment data builder' do
        job_url = Gitlab::Routing.url_helpers.project_job_url(project, ci_build)
        commit_url = Gitlab::UrlBuilder.build(deployment.commit)
        user_url = Gitlab::Routing.url_helpers.user_url(user)

        expect(subject.attachments).to eq([{
          text: "<#{project.web_url}|myspace/myproject> with job <#{job_url}|##{ci_build.id}> by <#{user_url}|John Smith (smith)>\n<#{commit_url}|#{deployment.short_sha}>: #{commit.title}",
          color: "good"
        }])
      end
    end

    context 'with markdown' do
      before do
        args.merge!(markdown: true)
      end

      it 'returns attachments with the data returned by the deployment data builder' do
        job_url = Gitlab::Routing.url_helpers.project_job_url(project, ci_build)
        commit_url = Gitlab::UrlBuilder.build(deployment.commit)
        user_url = Gitlab::Routing.url_helpers.user_url(user)

        expect(subject.attachments).to eq(
          "[myspace/myproject](#{project.web_url}) with job [##{ci_build.id}](#{job_url}) by [John Smith (smith)](#{user_url})\n[#{deployment.short_sha}](#{commit_url}): #{commit.title}"
        )
      end
    end

    it 'returns attachments for a failed deployment' do
      data = deployment_data(status: 'failed')

      message = described_class.new(data)

      expect(message.attachments).to eq([{
        text: "[project_path_with_namespace](project_web_url) with job [#3](deployable_url) by [Jane Person (jane)](user_url)\n[12345678](commit_url): commit title text",
        color: "danger"
      }])
    end

    it 'returns attachments for a canceled deployment' do
      data = deployment_data(status: 'canceled')

      message = described_class.new(data)

      expect(message.attachments).to eq([{
        text: "[project_path_with_namespace](project_web_url) with job [#3](deployable_url) by [Jane Person (jane)](user_url)\n[12345678](commit_url): commit title text",
        color: "warning"
      }])
    end

    it 'uses a neutral color for a deployment with any other status' do
      data = deployment_data(status: 'some-new-status-we-make-in-the-future')

      message = described_class.new(data)

      expect(message.attachments).to eq([{
        text: "[project_path_with_namespace](project_web_url) with job [#3](deployable_url) by [Jane Person (jane)](user_url)\n[12345678](commit_url): commit title text",
        color: "#334455"
      }])
    end
  end

  describe '#attachment_color' do
    using RSpec::Parameterized::TableSyntax
    where(:status, :expected_color) do
      'success'  | 'good'
      'canceled' | 'warning'
      'failed'   | 'danger'
      'blub'     | '#334455'
    end

    with_them do
      it 'returns the correct color' do
        data = deployment_data(status: status)
        message = described_class.new(data)

        expect(message.attachment_color).to eq(expected_color)
      end
    end
  end
end
