# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Integrations::ChatMessage::DeploymentMessage do
  describe '#pretext' do
    it 'returns a message with the data returned by the deployment data builder' do
      environment = create(:environment, name: "myenvironment")
      project = create(:project, :repository)
      commit = project.commit('HEAD')
      deployment = create(:deployment, status: :success, environment: environment, project: project, sha: commit.sha)
      data = Gitlab::DataBuilder::Deployment.build(deployment, Time.current)

      message = described_class.new(data)

      expect(message.pretext).to eq("Deploy to myenvironment succeeded")
    end

    it 'returns a message for a successful deployment' do
      data = {
        status: 'success',
        environment: 'production'
      }

      message = described_class.new(data)

      expect(message.pretext).to eq('Deploy to production succeeded')
    end

    it 'returns a message for a failed deployment' do
      data = {
        status: 'failed',
        environment: 'production'
      }

      message = described_class.new(data)

      expect(message.pretext).to eq('Deploy to production failed')
    end

    it 'returns a message for a canceled deployment' do
      data = {
        status: 'canceled',
        environment: 'production'
      }

      message = described_class.new(data)

      expect(message.pretext).to eq('Deploy to production canceled')
    end

    it 'returns a message for a deployment to another environment' do
      data = {
        status: 'success',
        environment: 'staging'
      }

      message = described_class.new(data)

      expect(message.pretext).to eq('Deploy to staging succeeded')
    end

    it 'returns a message for a deployment with any other status' do
      data = {
        status: 'unknown',
        environment: 'staging'
      }

      message = described_class.new(data)

      expect(message.pretext).to eq('Deploy to staging unknown')
    end

    it 'returns a message for a running deployment' do
      data = {
          status: 'running',
          environment: 'production'
      }

      message = described_class.new(data)

      expect(message.pretext).to eq('Starting deploy to production')
    end
  end

  describe '#attachments' do
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

    it 'returns attachments with the data returned by the deployment data builder' do
      user = create(:user, name: "John Smith", username: "smith")
      namespace = create(:namespace, name: "myspace")
      project = create(:project, :repository, namespace: namespace, name: "myproject")
      commit = project.commit('HEAD')
      environment = create(:environment, name: "myenvironment", project: project)
      ci_build = create(:ci_build, project: project)
      deployment = create(:deployment, :success, deployable: ci_build, environment: environment, project: project, user: user, sha: commit.sha)
      job_url = Gitlab::Routing.url_helpers.project_job_url(project, ci_build)
      commit_url = Gitlab::UrlBuilder.build(deployment.commit)
      user_url = Gitlab::Routing.url_helpers.user_url(user)
      data = Gitlab::DataBuilder::Deployment.build(deployment, Time.current)

      message = described_class.new(data)

      expect(message.attachments).to eq([{
        text: "[myspace/myproject](#{project.web_url}) with job [##{ci_build.id}](#{job_url}) by [John Smith (smith)](#{user_url})\n[#{deployment.short_sha}](#{commit_url}): #{commit.title}",
        color: "good"
      }])
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
end
