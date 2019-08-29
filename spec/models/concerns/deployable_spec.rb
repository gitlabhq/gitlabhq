# frozen_string_literal: true

require 'spec_helper'

describe Deployable do
  describe '#create_deployment' do
    let(:deployment) { job.deployment }
    let(:environment) { deployment&.environment }

    context 'when the deployable object will deploy to production' do
      let!(:job) { create(:ci_build, :start_review_app) }

      it 'creates a deployment and environment record' do
        expect(deployment.project).to eq(job.project)
        expect(deployment.ref).to eq(job.ref)
        expect(deployment.tag).to eq(job.tag)
        expect(deployment.sha).to eq(job.sha)
        expect(deployment.user).to eq(job.user)
        expect(deployment.deployable).to eq(job)
        expect(deployment.on_stop).to eq('stop_review_app')
        expect(environment.name).to eq('review/master')
      end
    end

    context 'when the deployable object will deploy to a cluster' do
      let(:project) { create(:project) }
      let!(:cluster) { create(:cluster, :provided_by_user, projects: [project]) }
      let!(:job) { create(:ci_build, :start_review_app, project: project) }

      it 'creates a deployment with cluster association' do
        expect(deployment.cluster).to eq(cluster)
      end
    end

    context 'when the deployable object will stop an environment' do
      let!(:job) { create(:ci_build, :stop_review_app) }

      it 'does not create a deployment record' do
        expect(deployment).to be_nil
      end
    end

    context 'when the deployable object has already had a deployment' do
      let!(:job) { create(:ci_build, :start_review_app, deployment: race_deployment) }
      let!(:race_deployment) { create(:deployment, :success) }

      it 'does not create a new deployment' do
        expect(deployment).to eq(race_deployment)
      end
    end

    context 'when the deployable object will not deploy' do
      let!(:job) { create(:ci_build) }

      it 'does not create a deployment and environment record' do
        expect(deployment).to be_nil
        expect(environment).to be_nil
      end
    end

    context 'when environment scope contains invalid character' do
      let(:job) do
        create(
          :ci_build,
          name: 'job:deploy-to-test-site',
          environment: '$CI_JOB_NAME',
          options: {
            environment: {
              name: '$CI_JOB_NAME',
              url: 'http://staging.example.com/$CI_JOB_NAME',
              on_stop: 'stop_review_app'
            }
          })
      end

      it 'does not create a deployment and environment record' do
        expect(deployment).to be_nil
        expect(environment).to be_nil
      end
    end
  end
end
