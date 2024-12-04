# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Deployments::UpdateEnvironmentService, feature_category: :continuous_delivery do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, :repository, developers: [user]) }
  let_it_be(:pipeline) do
    create(
      :ci_pipeline,
      sha: 'b83d6e391c22777fca1ed3012fce84f633d7fed0',
      project: project,
      user: user
    )
  end

  let(:job) do
    create(:ci_build,
      :with_deployment,
      pipeline: pipeline,
      ref: 'master',
      tag: false,
      environment: environment_name,
      options: { environment: options },
      user: user,
      project: project)
  end

  let(:deployment) { job.deployment }
  let(:environment) { deployment.environment }
  let(:environment_name) { 'production' }
  let(:options) { { name: environment_name } }

  subject(:service) { described_class.new(deployment) }

  before do
    allow(Deployments::LinkMergeRequestWorker).to receive(:perform_async)
    allow(Deployments::HooksWorker).to receive(:perform_async)
    job.success! # Create/Succeed deployment
  end

  describe '#execute' do
    let(:store) { Gitlab::EtagCaching::Store.new }

    it 'invalidates the environment etag cache' do
      old_value = store.get(environment.etag_cache_key)

      service.execute

      expect(store.get(environment.etag_cache_key)).not_to eq(old_value)
    end

    it 'creates ref' do
      expect_any_instance_of(Repository)
        .to receive(:create_ref)
        .with(deployment.sha, "refs/environments/production/deployments/#{deployment.iid}")

      service.execute
    end

    it 'updates merge request metrics' do
      expect_any_instance_of(Deployment)
        .to receive(:update_merge_request_metrics!)

      service.execute
    end

    it 'returns the deployment' do
      expect(subject.execute).to eq(deployment)
    end

    it 'returns the deployment when could not save the environment' do
      allow(environment).to receive(:save).and_return(false)

      expect(subject.execute).to eq(deployment)
    end

    it 'returns the deployment when environment is stopped' do
      allow(environment).to receive(:stopped?).and_return(true)

      expect(subject.execute).to eq(deployment)
    end

    context 'when deployable is bridge job' do
      let(:job) do
        create(:ci_bridge,
          :with_deployment,
          pipeline: pipeline,
          ref: 'master',
          tag: false,
          environment: environment_name,
          options: { environment: options },
          project: project)
      end

      it 'creates ref' do
        expect_any_instance_of(Repository)
          .to receive(:create_ref)
          .with(deployment.sha, "refs/environments/production/deployments/#{deployment.iid}")

        service.execute
      end
    end

    context 'when start action is defined' do
      let(:options) { { name: 'production', action: 'start' } }

      context 'and environment is stopped' do
        before do
          environment.stop_complete
        end

        it 'makes environment available' do
          service.execute

          expect(environment.reload).to be_available
        end
      end
    end

    context 'when external URL is specified and the tier is unset' do
      let(:options) { { name: 'production', url: external_url } }

      before do
        environment.update_columns(external_url: external_url, tier: nil)
        job.update!(environment: 'production')
      end

      context 'when external URL is valid' do
        let(:external_url) { 'https://google.com' }

        it 'succeeds to update the tier automatically' do
          expect { subject.execute }.to change { environment.tier }.from(nil).to('production')
        end
      end

      context 'when external URL is invalid' do
        let(:external_url) { 'javascript:alert("hello")' }

        it 'fails to update the tier due to validation error' do
          expect { subject.execute }.not_to change { environment.reload.tier }
        end

        it 'tracks an exception' do
          expect(Gitlab::ErrorTracking).to receive(:track_exception)
            .with(
              an_instance_of(described_class::EnvironmentUpdateFailure),
              project_id: project.id,
              environment_id: environment.id,
              reason: %q(External url javascript scheme is not allowed)
            )
            .once

          subject.execute
        end
      end
    end

    context 'when variables are used' do
      let(:options) do
        { name: 'review-apps/$CI_COMMIT_REF_NAME',
          url: 'http://$CI_COMMIT_REF_NAME.review-apps.gitlab.com' }
      end

      before do
        environment.update!(name: 'review-apps/master')
        job.update!(environment: 'review-apps/$CI_COMMIT_REF_NAME')
      end

      it 'does not create a new environment' do
        expect { subject.execute }.not_to change { Environment.count }
      end

      it 'updates external url' do
        subject.execute

        expect(subject.environment.name).to eq('review-apps/master')
        expect(subject.environment.external_url).to eq('http://master.review-apps.gitlab.com')
      end
    end

    context 'when auto_stop_in are used' do
      before do
        environment.update_attribute(:auto_stop_at, nil)

        allow(job).to receive(:expanded_auto_stop_in).and_return('1 day')
      end

      it 'renews auto stop at' do
        freeze_time do
          expect { subject.execute }
            .to change { environment.reset.auto_stop_at&.round }.from(nil).to(1.day.since.round)
        end
      end
    end

    context 'when deployment tier is specified' do
      let(:environment_name) { 'customer-portal' }
      let(:options) { { name: environment_name, deployment_tier: 'production' } }

      context 'when tier has already been set' do
        before do
          environment.update_column(:tier, Environment.tiers[:other])
        end

        it 'overwrites the guessed tier by the specified deployment tier' do
          expect { subject.execute }
            .to change { environment.reset.tier }.from('other').to('production')
        end
      end

      context 'when tier has not been set' do
        before do
          environment.update_column(:tier, nil)
        end

        it 'sets the specified deployment tier' do
          expect { subject.execute }
            .to change { environment.reset.tier }.from(nil).to('production')
        end

        context 'when deployment was created by an external CD system' do
          before do
            deployment.update_column(:deployable_id, nil)
            deployment.reload
          end

          it 'guesses the deployment tier' do
            expect { subject.execute }
              .to change { environment.reset.tier }.from(nil).to('other')
          end
        end
      end
    end

    context 'when deployment tier is not specified' do
      let(:environment_name) { 'customer-portal' }
      let(:options) { { name: environment_name } }

      it 'guesses the deployment tier' do
        environment.update_column(:tier, nil)

        expect { subject.execute }
          .to change { environment.reset.tier }.from(nil).to('other')
      end
    end

    context 'when cluster agent is specified' do
      let(:agent) { create(:cluster_agent, project: project) }

      let(:options) { { name: environment_name, kubernetes: { agent: agent_path } } }

      context 'when the agent does not exist' do
        let(:agent_path) { "#{project.full_path}:non-existent-agent" }

        it 'does not assign a cluster agent' do
          expect { subject.execute }.not_to change { environment.cluster_agent }
        end
      end

      context 'when the agent exists' do
        let(:agent_path) { "#{project.full_path}:#{agent.name}" }

        context 'and the user no longer exists' do
          before do
            job.update!(user: nil)
          end

          it 'does not assign a cluster agent' do
            expect { subject.execute }.not_to change { environment.cluster_agent }
          end
        end

        context 'and the user is not authorized' do
          it 'does not assign a cluster agent' do
            expect { subject.execute }.not_to change { environment.cluster_agent }
          end
        end

        context 'and the user is authorized' do
          before do
            agent.user_access_project_authorizations.create!(project: project, config: {})
          end

          it 'assigns the cluster agent to the environment' do
            expect { subject.execute }.to change { environment.cluster_agent }.from(nil).to(agent)
          end

          context 'when the agent path contains variables' do
            let(:agent_path) { "$CI_PROJECT_PATH:#{agent.name}" }

            it 'expands variables and assigns the cluster agent to the environment' do
              expect { subject.execute }.to change { environment.cluster_agent }.from(nil).to(agent)
            end
          end
        end
      end
    end

    context 'when kubernetes namespace is specified' do
      let(:agent) { create(:cluster_agent, project: project) }
      let(:namespace) { 'my-namespace' }
      let(:options) { { name: environment_name, kubernetes: { agent: agent_path, namespace: namespace } } }

      context 'when the agent does not exist' do
        let(:agent_path) { "#{project.full_path}:non-existent-agent" }

        it 'does not assign a kubernetes namespace' do
          expect { subject.execute }.not_to change { environment.kubernetes_namespace }
        end
      end

      context 'when the agent exists' do
        let(:agent_path) { "#{project.full_path}:#{agent.name}" }

        context 'and the user no longer exists' do
          before do
            job.update!(user: nil)
          end

          it 'does not assign a kubernetes namespace' do
            expect { subject.execute }.not_to change { environment.kubernetes_namespace }
          end
        end

        context 'and the user is not authorized' do
          it 'does not assign a kubernetes namespace' do
            expect { subject.execute }.not_to change { environment.kubernetes_namespace }
          end
        end

        context 'and the user is authorized' do
          before do
            agent.user_access_project_authorizations.create!(project: project, config: {})
          end

          it 'assigns the kubernetes namespace to the environment' do
            expect { subject.execute }.to change { environment.kubernetes_namespace }.from(nil).to(namespace)
          end

          context 'when the agent path contains variables' do
            let(:agent_path) { "$CI_PROJECT_PATH:#{agent.name}" }

            it 'expands variables and assigns the kubernetes namespace to the environment' do
              expect { subject.execute }.to change { environment.kubernetes_namespace }.from(nil).to(namespace)
            end
          end
        end
      end
    end

    context 'when flux resource path is specified' do
      let(:agent) { create(:cluster_agent, project: project) }
      let(:namespace) { 'my-namespace' }
      let(:flux_resource_path) { 'path/to/flux/resource' }
      let(:options) do
        {
          name: environment_name,
          kubernetes: {
            agent: agent_path,
            namespace: namespace,
            flux_resource_path: flux_resource_path
          }
        }
      end

      context 'when the agent does not exist' do
        let(:agent_path) { "#{project.full_path}:non-existent-agent" }

        it 'does not assign a Flux resource path' do
          expect { subject.execute }.not_to change { environment.flux_resource_path }
        end
      end

      context 'when the kubernetes namespace is not specified' do
        let(:agent_path) { "#{project.full_path}:#{agent.name}" }
        let(:options) do
          {
            name: environment_name,
            kubernetes: {
              agent: agent_path,
              flux_resource_path: flux_resource_path
            }
          }
        end

        it 'does not assign a Flux resource path' do
          expect { subject.execute }.not_to change { environment.flux_resource_path }
        end
      end

      context 'when the agent exists' do
        let(:agent_path) { "#{project.full_path}:#{agent.name}" }

        context 'and the user no longer exists' do
          before do
            job.update!(user: nil)
          end

          it 'does not assign a Flux resource path' do
            expect { subject.execute }.not_to change { environment.flux_resource_path }
          end
        end

        context 'and the user is not authorized' do
          it 'does not assign a Flux resource path' do
            expect { subject.execute }.not_to change { environment.flux_resource_path }
          end
        end

        context 'and the user is authorized' do
          before do
            agent.user_access_project_authorizations.create!(project: project, config: {})
          end

          it 'assigns the kubernetes namespace to the environment' do
            expect { subject.execute }.to change { environment.flux_resource_path }.from(nil).to(flux_resource_path)
          end

          context 'when the agent path contains variables' do
            let(:agent_path) { "$CI_PROJECT_PATH:#{agent.name}" }

            it 'expands variables and assigns the kubernetes namespace to the environment' do
              expect { subject.execute }.to change { environment.flux_resource_path }.from(nil).to(flux_resource_path)
            end
          end
        end
      end
    end
  end

  describe '#expanded_environment_url' do
    subject { service.send(:expanded_environment_url) }

    context 'when yaml environment uses $CI_COMMIT_REF_NAME' do
      let(:job) do
        create(
          :ci_build,
          :with_deployment,
          pipeline: pipeline,
          ref: 'master',
          environment: 'production',
          project: project,
          options: { environment: { name: 'production', url: 'http://review/$CI_COMMIT_REF_NAME' } }
        )
      end

      it { is_expected.to eq('http://review/master') }
    end

    context 'when yaml environment uses $CI_ENVIRONMENT_SLUG' do
      let(:job) do
        create(
          :ci_build,
          :with_deployment,
          pipeline: pipeline,
          ref: 'master',
          environment: 'prod-slug',
          project: project,
          options: { environment: { name: 'prod-slug', url: 'http://review/$CI_ENVIRONMENT_SLUG' } }
        )
      end

      it { is_expected.to eq('http://review/prod-slug') }
    end

    context 'when yaml environment uses yaml_variables containing symbol keys' do
      let(:job) do
        create(
          :ci_build,
          :with_deployment,
          pipeline: pipeline,
          yaml_variables: [{ key: :APP_HOST, value: 'host' }],
          environment: 'production',
          project: project,
          options: { environment: { name: 'production', url: 'http://review/$APP_HOST' } }
        )
      end

      it { is_expected.to eq('http://review/host') }
    end

    context 'when job variables are generated during runtime' do
      let(:job) do
        create(
          :ci_build,
          :with_deployment,
          pipeline: pipeline,
          environment: 'review/$CI_COMMIT_REF_NAME',
          project: project,
          job_variables: [job_variable],
          options: { environment: { name: 'review/$CI_COMMIT_REF_NAME', url: 'http://$DYNAMIC_ENV_URL' } }
        )
      end

      let(:job_variable) do
        build(:ci_job_variable, :dotenv_source, key: 'DYNAMIC_ENV_URL', value: 'abc.test.com')
      end

      it 'expands the environment URL from the dynamic variable' do
        is_expected.to eq('http://abc.test.com')
      end
    end

    context 'when environment url uses a nested variable' do
      let(:yaml_variables) do
        [
          { key: 'MAIN_DOMAIN', value: '${STACK_NAME}.example.com' },
          { key: 'STACK_NAME', value: 'appname-${ENVIRONMENT_NAME}' },
          { key: 'ENVIRONMENT_NAME', value: '${CI_COMMIT_REF_SLUG}' }
        ]
      end

      let(:job) do
        create(
          :ci_build,
          :with_deployment,
          pipeline: pipeline,
          ref: 'master',
          environment: 'production',
          project: project,
          yaml_variables: yaml_variables,
          options: { environment: { name: 'production', url: 'http://$MAIN_DOMAIN' } }
        )
      end

      it { is_expected.to eq('http://appname-master.example.com') }
    end

    context 'when yaml environment does not have url' do
      let(:job) { create(:ci_build, :with_deployment, pipeline: pipeline, environment: 'staging', project: project) }

      it 'returns the external_url from persisted environment' do
        is_expected.to be_nil
      end
    end
  end

  describe "merge request metrics" do
    let(:merge_request) { create(:merge_request, target_branch: 'master', source_branch: 'feature', source_project: project) }

    context "while updating the 'first_deployed_to_production_at' time" do
      before do
        merge_request.metrics.update!(merged_at: 1.hour.ago)
      end

      context "for merge requests merged before the current deploy" do
        it "sets the time if the deploy's environment is 'production'" do
          service.execute

          expect(merge_request.reload.metrics.first_deployed_to_production_at).to be_like_time(deployment.finished_at)
        end

        context 'when job deploys to staging' do
          let(:job) do
            create(:ci_build,
              :with_deployment,
              pipeline: pipeline,
              ref: 'master',
              tag: false,
              environment: 'staging',
              options: { environment: { name: 'staging' } },
              project: project)
          end

          it "doesn't set the time if the deploy's environment is not 'production'" do
            service.execute

            expect(merge_request.reload.metrics.first_deployed_to_production_at).to be_nil
          end
        end

        it 'does not raise errors if the merge request does not have a metrics record' do
          merge_request.metrics.destroy!

          expect(merge_request.reload.metrics).to be_nil
          expect { service.execute }.not_to raise_error
        end
      end

      context "for merge requests merged before the previous deploy" do
        context "if the 'first_deployed_to_production_at' time is already set" do
          it "does not overwrite the older 'first_deployed_to_production_at' time" do
            # Previous deploy
            service.execute

            expect(merge_request.reload.metrics.first_deployed_to_production_at).to be_like_time(deployment.finished_at)

            # Current deploy
            travel_to(12.hours.from_now) do
              service.execute

              expect(merge_request.reload.metrics.first_deployed_to_production_at).to be_like_time(deployment.finished_at)
            end
          end
        end

        context "if the 'first_deployed_to_production_at' time is not already set" do
          it "does not overwrite the older 'first_deployed_to_production_at' time" do
            # Previous deploy
            time = 5.minutes.from_now
            travel_to(time) { service.execute }

            expect(merge_request.reload.metrics.merged_at).to be < merge_request.reload.metrics.first_deployed_to_production_at

            previous_time = merge_request.reload.metrics.first_deployed_to_production_at

            # Current deploy
            travel_to(time + 12.hours) { service.execute }

            expect(merge_request.reload.metrics.first_deployed_to_production_at).to eq(previous_time)
          end
        end
      end
    end
  end
end
