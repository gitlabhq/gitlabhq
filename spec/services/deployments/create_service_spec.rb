# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Deployments::CreateService do
  let(:user) { create(:user) }

  describe '#execute' do
    let(:project) { create(:project, :repository) }
    let(:environment) { create(:environment, project: project) }

    it 'creates a deployment' do
      service = described_class.new(
        environment,
        user,
        sha: 'b83d6e391c22777fca1ed3012fce84f633d7fed0',
        ref: 'master',
        tag: false,
        status: 'success'
      )

      expect(Deployments::UpdateEnvironmentWorker).to receive(:perform_async)
      expect(Deployments::LinkMergeRequestWorker).to receive(:perform_async)
      expect(Deployments::HooksWorker).to receive(:perform_async)

      expect(service.execute).to be_persisted
    end

    it 'does not change the status if no status is given' do
      service = described_class.new(
        environment,
        user,
        sha: 'b83d6e391c22777fca1ed3012fce84f633d7fed0',
        ref: 'master',
        tag: false
      )

      expect(Deployments::UpdateEnvironmentWorker).not_to receive(:perform_async)
      expect(Deployments::LinkMergeRequestWorker).not_to receive(:perform_async)
      expect(Deployments::HooksWorker).not_to receive(:perform_async)

      expect(service.execute).to be_persisted
    end

    context 'when the last deployment has the same parameters' do
      let(:params) do
        {
          sha: 'b83d6e391c22777fca1ed3012fce84f633d7fed0',
          ref: 'master',
          tag: false,
          status: 'success'
        }
      end

      it 'does not create a new deployment' do
        described_class.new(environment, user, params).execute

        expect(Deployments::UpdateEnvironmentWorker).not_to receive(:perform_async)
        expect(Deployments::LinkMergeRequestWorker).not_to receive(:perform_async)
        expect(Deployments::HooksWorker).not_to receive(:perform_async)

        described_class.new(environment.reload, user, params).execute
      end
    end
  end

  describe '#deployment_attributes' do
    let(:environment) do
      double(
        :environment,
        deployment_platform: double(:platform, cluster_id: 1),
        project_id: 2,
        id: 3
      )
    end

    it 'only includes attributes that we want to persist' do
      service = described_class.new(
        environment,
        user,
        ref: 'master',
        tag: true,
        sha: '123',
        foo: 'bar',
        on_stop: 'stop'
      )

      expect(service.deployment_attributes).to eq(
        cluster_id: 1,
        project_id: 2,
        environment_id: 3,
        ref: 'master',
        tag: true,
        sha: '123',
        user: user,
        on_stop: 'stop'
      )
    end
  end
end
