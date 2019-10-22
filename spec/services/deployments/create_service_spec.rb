# frozen_string_literal: true

require 'spec_helper'

describe Deployments::CreateService do
  let(:environment) do
    double(
      :environment,
      deployment_platform: double(:platform, cluster_id: 1),
      project_id: 2,
      id: 3
    )
  end

  let(:user) { double(:user) }

  describe '#execute' do
    let(:service) { described_class.new(environment, user, {}) }

    it 'does not run the AfterCreateService service if the deployment is not persisted' do
      deploy = double(:deployment, persisted?: false)

      expect(service)
        .to receive(:create_deployment)
        .and_return(deploy)

      expect(Deployments::AfterCreateService)
        .not_to receive(:new)

      expect(service.execute).to eq(deploy)
    end

    it 'runs the AfterCreateService service if the deployment is persisted' do
      deploy = double(:deployment, persisted?: true)
      after_service = double(:after_create_service)

      expect(service)
        .to receive(:create_deployment)
        .and_return(deploy)

      expect(Deployments::AfterCreateService)
        .to receive(:new)
        .with(deploy)
        .and_return(after_service)

      expect(after_service)
        .to receive(:execute)

      expect(service.execute).to eq(deploy)
    end
  end

  describe '#create_deployment' do
    it 'creates a deployment' do
      environment = build(:environment)
      service = described_class.new(environment, user, {})

      expect(environment.deployments)
        .to receive(:create)
        .with(an_instance_of(Hash))

      service.create_deployment
    end
  end

  describe '#deployment_attributes' do
    it 'only includes attributes that we want to persist' do
      service = described_class.new(
        environment,
        user,
        ref: 'master',
        tag: true,
        sha: '123',
        foo: 'bar',
        on_stop: 'stop',
        status: 'running'
      )

      expect(service.deployment_attributes).to eq(
        cluster_id: 1,
        project_id: 2,
        environment_id: 3,
        ref: 'master',
        tag: true,
        sha: '123',
        user: user,
        on_stop: 'stop',
        status: 'running'
      )
    end
  end
end
