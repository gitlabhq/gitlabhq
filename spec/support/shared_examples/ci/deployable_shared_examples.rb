# frozen_string_literal: true

# rubocop:disable Layout/LineLength
# rubocop:disable RSpec/ContextWording
RSpec.shared_examples 'a deployable job' do
  it { is_expected.to have_one(:deployment) }

  shared_examples 'calling proper BuildFinishedWorker' do
    it 'calls Ci::BuildFinishedWorker' do
      skip unless described_class == ::Ci::Build

      expect(Ci::BuildFinishedWorker).to receive(:perform_async)

      subject
    end
  end

  describe '#has_outdated_deployment?' do
    subject { job.has_outdated_deployment? }

    let(:job) { create(factory_type, :created, :with_deployment, project: project, pipeline: pipeline, environment: 'production') }

    context 'when job has no environment' do
      let(:job) { create(factory_type, :created, pipeline: pipeline, environment: nil) }

      it { expect(subject).to be_falsey }
    end

    context 'when deployment is not persisted' do
      let_it_be(:project) { create(:project, :repository) }
      let_it_be(:commits) { project.repository.commits('master', limit: 2) }
      let_it_be(:environment) { create(:environment, project: project) }

      let(:unpersisted_deployment) do
        FactoryBot.build(
          :deployment,
          :success,
          project: project,
          environment: environment,
          finished_at: 1.year.ago,
          sha: nil # Required attribute, nil prevents the record from being persisted and getting an ID
        )
      end

      let!(:last_deployment) do
        create(:deployment, :success, project: project, environment: environment, sha: commits[1].sha)
      end

      it 'returns false to ignore the Build and not take any Deployment-related action' do
        expect(unpersisted_deployment.job.has_outdated_deployment?).to eq(false)
      end
    end

    context 'when project has forward deployment disabled' do
      before do
        project.ci_cd_settings.update!(forward_deployment_enabled: false)
      end

      it { expect(subject).to be_falsey }
    end

    context 'when job is not an outdated deployment' do
      before do
        allow(job.deployment).to receive(:older_than_last_successful_deployment?).and_return(false)
      end

      it { expect(subject).to be_falsey }
    end

    context 'when job is older than the latest deployment and still pending status' do
      before do
        allow(job.deployment).to receive(:older_than_last_successful_deployment?).and_return(true)
      end

      it { expect(subject).to be_truthy} # rubocop: disable Layout/SpaceInsideBlockBraces
    end

    context 'when job is older than the latest deployment but succeeded once' do
      let(:job) { create(factory_type, :success, :with_deployment, project: project, pipeline: pipeline, environment: 'production') }

      before do
        allow(job.deployment).to receive(:older_than_last_successful_deployment?).and_return(true)
      end

      it 'returns false for allowing rollback' do
        expect(subject).to be_falsey
      end

      context 'when forward_deployment_rollback_allowed option is disabled' do
        before do
          project.ci_cd_settings.update!(forward_deployment_rollback_allowed: false)
        end

        it 'returns true for disallowing rollback' do
          expect(subject).to eq(true)
        end
      end
    end
  end

  describe 'state transition as a deployable' do
    subject { job.send(event) }

    let!(:job) { create(factory_type, :with_deployment, :start_review_app, status: :pending, pipeline: pipeline) }
    let(:deployment) { job.deployment }
    let(:environment) { deployment.environment }

    before do
      allow(Deployments::LinkMergeRequestWorker).to receive(:perform_async)
      allow(Deployments::HooksWorker).to receive(:perform_async)
    end

    it 'has deployments record with created status' do
      expect(deployment).to be_created
      expect(environment.name).to eq('review/master')
    end

    shared_examples_for 'avoid deadlock' do
      it 'executes UPDATE in the right order' do
        recorded = with_cross_database_modification_prevented do
          ActiveRecord::QueryRecorder.new { subject }
        end

        index_for_build = recorded.log.index { |l| l.include?("UPDATE #{described_class.quoted_table_name}") }
        index_for_deployment = recorded.log.index { |l| l.include?("UPDATE \"deployments\"") }

        expect(index_for_build).to be < index_for_deployment
      end
    end

    context 'when transits to running' do
      let(:event) { :run! }

      it_behaves_like 'avoid deadlock'

      it 'transits deployment status to running' do
        with_cross_database_modification_prevented do
          subject
        end

        expect(deployment).to be_running
      end

      context 'when deployment is already running state' do
        before do
          job.deployment.success!
        end

        it 'does not change deployment status and tracks an error' do
          expect(Gitlab::ErrorTracking)
            .to receive(:track_exception).with(
              instance_of(Deployment::StatusSyncError), deployment_id: deployment.id, job_id: job.id)

          with_cross_database_modification_prevented do
            expect { subject }.not_to change { deployment.reload.status }
          end
        end
      end
    end

    context 'when transits to success' do
      let(:event) { :success! }

      before do
        allow(Deployments::UpdateEnvironmentWorker).to receive(:perform_async)
        allow(Deployments::HooksWorker).to receive(:perform_async)
      end

      it_behaves_like 'avoid deadlock'
      it_behaves_like 'calling proper BuildFinishedWorker'

      it 'queues relevant workers' do
        expect(Environments::StopJobSuccessWorker).to receive(:perform_async).with(job.id)
        expect(Environments::RecalculateAutoStopWorker).to receive(:perform_async).with(job.id)

        subject
      end

      it 'transits deployment status to success' do
        with_cross_database_modification_prevented do
          subject
        end

        expect(deployment).to be_success
      end
    end

    context 'when transits to failed' do
      let(:event) { :drop! }

      it_behaves_like 'avoid deadlock'
      it_behaves_like 'calling proper BuildFinishedWorker'

      it 'transits deployment status to failed' do
        with_cross_database_modification_prevented do
          subject
        end

        expect(deployment).to be_failed
      end
    end

    context 'when transits to skipped' do
      let(:event) { :skip! }

      it_behaves_like 'avoid deadlock'

      it 'transits deployment status to skipped' do
        with_cross_database_modification_prevented do
          subject
        end

        expect(deployment).to be_skipped
      end
    end

    context 'when transits to canceled' do
      let(:event) { :cancel! }

      it_behaves_like 'avoid deadlock'
      it_behaves_like 'calling proper BuildFinishedWorker'

      it 'transits deployment status to canceled' do
        with_cross_database_modification_prevented do
          subject
        end

        expect(deployment).to be_canceled
      end
    end

    # Mimic playing a manual job that needs another job.
    # `needs + when:manual` scenario, see: https://gitlab.com/gitlab-org/gitlab/-/issues/347502
    context 'when transits from skipped to created to running' do
      before do
        job.skip!
      end

      context 'during skipped to created' do
        let(:event) { :process! }

        it 'transitions to created' do
          subject

          expect(deployment).to be_created
        end
      end

      context 'during created to running' do
        let(:event) { :run! }

        before do
          job.process!
          job.enqueue!
        end

        it 'transitions to running and calls webhook' do
          freeze_time do
            expect(Deployments::HooksWorker)
              .to receive(:perform_async).with(hash_including({ 'deployment_id' => deployment.id, 'status' => 'running', 'status_changed_at' => Time.current.to_s }))

            subject
          end

          expect(deployment).to be_running
        end
      end
    end
  end

  describe '#on_stop' do
    subject { job.on_stop }

    context 'when a job has a specification that it can be stopped from the other job' do
      let(:job) { create(factory_type, :start_review_app, pipeline: pipeline) }

      it 'returns the other job name' do
        is_expected.to eq('stop_review_app')
      end
    end

    context 'when a job does not have environment information' do
      let(:job) { create(factory_type, pipeline: pipeline) }

      it 'returns nil' do
        is_expected.to be_nil
      end
    end
  end

  describe "#expanded_deployment_tier" do
    subject { job.expanded_deployment_tier }

    context 'when options does not include deployment_tier' do
      let(:options) { { environment: { name: 'production' } } }
      let(:job) { create(factory_type, options: options, pipeline: pipeline) }

      it { is_expected.to be_nil }
    end

    context 'when deployment_tier is a variable' do
      let(:options) do
        {
          environment: {
            name: 'production',
            deployment_tier: '$DEPLOYMENT_TIER'
          }
        }
      end

      let(:job) { create(factory_type, environment: 'production', options: options, pipeline: pipeline, yaml_variables: yaml_variables) }

      context 'when the value is valid' do
        let(:yaml_variables) do
          [
            { key: 'DEPLOYMENT_TIER', value: 'production' }
          ]
        end

        it 'returns the expanded value' do
          is_expected.to eq('production')
        end
      end

      context 'when the value is invalid' do
        let(:yaml_variables) do
          [
            { key: 'DEPLOYMENT_TIER', value: 'invalid' }
          ]
        end

        it 'returns the expanded value' do
          is_expected.to eq('invalid')
        end
      end

      context 'when the value is not set' do
        let(:yaml_variables) { [] }

        it { is_expected.to be_empty }
      end
    end
  end

  describe '#environment_permanent_metadata' do
    let_it_be(:environment) { create(:environment, name: 'production') }

    let(:options) { { script: 'script', environment: { name: 'production', action: 'prepare' } } }
    let(:job) { create(factory_type, project: project, environment: 'production', options: options) }

    subject { job.environment_permanent_metadata }

    it { is_expected.to eq(job.environment_options_for_permanent_storage) }

    context 'when a job environment record is present' do
      before do
        job.link_to_environment(environment)

        # Artificially change the stored options to prove the result comes from
        # the correct source.
        job.job_environment.update!(options: { deployment_tier: 'production' })
      end

      it 'returns options from the job environment' do
        expect(subject).to eq(job.job_environment.options)
      end
    end
  end

  describe '#environment_options_for_permanent_storage' do
    subject { job.environment_options_for_permanent_storage }

    let(:job) { FactoryBot.build(factory_type, options: options) }
    let(:options) do
      {
        script: 'script',
        environment: {
          name: 'production',
          deployment_tier: 'production',
          action: 'prepare',
          kubernetes: {
            agent: 'agent',
            namespace: 'namespace'
          }
        }
      }
    end

    it { is_expected.to eq({ deployment_tier: 'production', action: 'prepare', kubernetes: { namespace: 'namespace' } }) }

    context 'when there are kubernetes options other than namespace' do
      let(:options) { { environment: { deployment_tier: 'production', kubernetes: { agent: 'agent' } } } }

      it { is_expected.to eq({ deployment_tier: 'production' }) }
    end

    context 'when options is empty' do
      let(:options) { nil }

      it { is_expected.to eq({}) }
    end

    context 'when options is present but has no environment keyword' do
      let(:options) { { image: 'image', script: 'script' } }

      it { is_expected.to eq({}) }
    end
  end

  describe '#link_to_environment' do
    let_it_be(:environment) { create(:environment, name: 'production', project: project) }

    let(:job) { create(factory_type, environment: environment.name, project: project) }

    subject { job.link_to_environment(environment) }

    it 'creates a new job_environment record' do
      subject

      expect(job.job_environment).to be_present
      expect(job.job_environment).to have_attributes(
        project: project,
        environment: environment,
        pipeline: job.pipeline,
        expanded_environment_name: environment.name,
        options: job.environment_options_for_permanent_storage.deep_stringify_keys
      )
    end

    context 'the job_environment record fails to save' do
      before do
        environment.name = 'a' * 300 # Will cause a validation error due to length
      end

      it 'tracks an exception without raising' do
        expect(Gitlab::ErrorTracking).to receive(:track_and_raise_for_dev_exception).with(
          instance_of(ActiveRecord::RecordInvalid),
          job_id: job.id
        )

        expect { subject }.not_to raise_error
      end
    end

    context 'the job has not yet been saved' do
      let(:job) { FactoryBot.build(factory_type, environment: environment.name, project: project) }

      it 'does not save the job_environment record' do
        subject

        expect(job).not_to be_persisted
        expect(job.job_environment).to be_present
        expect(job.job_environment).not_to be_persisted
        expect(job.job_environment).to have_attributes(
          project: project,
          environment: environment,
          pipeline: job.pipeline,
          expanded_environment_name: environment.name,
          options: job.environment_options_for_permanent_storage.deep_stringify_keys
        )
      end
    end
  end

  describe '#environment_tier' do
    subject { job.environment_tier }

    let!(:environment) { create(:environment, name: 'production', tier: 'development', project: project) }

    context 'when options includes deployment_tier' do
      let(:options) { { environment: { deployment_tier: 'production' } } }
      let(:job) { create(factory_type, options: options, environment: 'production', project: project) }

      it { is_expected.to eq('production') }
    end

    context 'when deployment_tier is a variable' do
      let(:options) do
        {
          environment: {
            name: 'production',
            deployment_tier: '$DEPLOYMENT_TIER'
          }
        }
      end

      let(:yaml_variables) do
        [
          { key: 'DEPLOYMENT_TIER', value: 'production' }
        ]
      end

      let(:job) { create(factory_type, options: options, environment: 'production', project: project, yaml_variables: yaml_variables) }

      it 'returns the expanded value' do
        is_expected.to eq('production')
      end
    end

    context 'when options does not include deployment_tier' do
      let(:options) { { environment: { name: 'production' } } }
      let(:job) { FactoryBot.build(factory_type, options: options, environment: 'production', project: project) }

      it 'uses tier from environment' do
        is_expected.to eq('development')
      end

      context 'when persisted environment is absent' do
        let(:environment) { nil }

        it { is_expected.to be_nil }
      end
    end
  end

  describe '#environment_url' do
    subject { job.environment_url }

    let!(:job) { create(factory_type, :with_deployment, :deploy_to_production, pipeline: pipeline) }

    it { is_expected.to eq('http://prd.example.com/$CI_JOB_NAME') }

    context 'when options does not include url' do
      let(:options) { { environment: { url: nil } } }

      before do
        stub_ci_job_definition(job, options: options)
        job.persisted_environment.update!(external_url: 'http://prd.example.com/$CI_JOB_NAME')
      end

      it 'fetches from the persisted environment' do
        expect_any_instance_of(::Environment) do |environment|
          expect(environment).to receive(:external_url).once
        end

        is_expected.to eq('http://prd.example.com/$CI_JOB_NAME')
      end

      context 'when persisted environment is absent' do
        before do
          job.clear_memoization(:persisted_environment)
          job.persisted_environment = nil
        end

        it { is_expected.to be_nil }
      end
    end
  end

  describe '#environment_slug' do
    subject { job.environment_slug }

    let!(:job) { create(factory_type, :with_deployment, :start_review_app, pipeline: pipeline) }

    it { is_expected.to eq('review-master-8dyme2') }

    context 'when persisted environment is absent' do
      let!(:job) { create(factory_type, :start_review_app, pipeline: pipeline) }

      it { is_expected.to be_nil }
    end
  end

  describe 'environment' do
    describe '#has_environment_keyword?' do
      subject { job.has_environment_keyword? }

      context 'when environment is defined' do
        before do
          job.update!(environment: 'review')
        end

        it { is_expected.to be_truthy }
      end

      context 'when environment is not defined' do
        before do
          job.update!(environment: nil)
        end

        it { is_expected.to be_falsey }
      end
    end

    describe '#expanded_environment_name' do
      subject { job.expanded_environment_name }

      context 'when environment uses $CI_COMMIT_REF_NAME' do
        let(:job) do
          create(
            factory_type,
            ref: 'master',
            environment: 'review/$CI_COMMIT_REF_NAME',
            pipeline: pipeline
          )
        end

        it { is_expected.to eq('review/master') }
      end

      context 'when environment uses yaml_variables containing symbol keys' do
        let(:job) do
          create(
            factory_type,
            yaml_variables: [{ key: :APP_HOST, value: 'host' }],
            environment: 'review/$APP_HOST',
            pipeline: pipeline
          )
        end

        it 'returns an expanded environment name with a list of variables' do
          is_expected.to eq('review/host')
        end

        context 'when job metadata has already persisted the expanded environment name' do
          before do
            create(:ci_build_metadata, build: job, expanded_environment_name: 'review/foo')
            job.reload_metadata
          end

          it 'returns a persisted expanded environment name without a list of variables' do
            expect(job).not_to receive(:simple_variables)

            is_expected.to eq('review/foo')
          end
        end
      end

      context 'when using persisted variables' do
        let(:job) do
          create(factory_type, environment: 'review/x$CI_JOB_ID', pipeline: pipeline)
        end

        it { is_expected.to eq('review/x') }
      end

      context 'when environment name uses a nested variable' do
        let(:yaml_variables) do
          [
            { key: 'ENVIRONMENT_NAME', value: '${CI_COMMIT_REF_NAME}' }
          ]
        end

        let(:job) do
          create(
            factory_type,
            ref: 'master',
            yaml_variables: yaml_variables,
            environment: 'review/$ENVIRONMENT_NAME',
            pipeline: pipeline
          )
        end

        it { is_expected.to eq('review/master') }
      end

      context 'when there is an associated job environment record' do
        let(:job) do
          create(
            factory_type,
            ref: 'example-feature',
            environment: 'review/example-feature',
            pipeline: pipeline
          )
        end

        let!(:job_environment) do
          create(:job_environment, project: project, pipeline: pipeline, job: job,
            expanded_environment_name: 'name-from-job-env')
        end

        it { is_expected.to eq('name-from-job-env') }

        context 'when the job metadata has the namespace persisted' do
          before do
            create(:ci_build_metadata, build: job, expanded_environment_name: 'name-from-metadata')
          end

          it { is_expected.to eq('name-from-job-env') }
        end

        context 'when the job metadata does not exist' do
          before do
            job.metadata&.destroy!
          end

          it { is_expected.to eq('name-from-job-env') }
        end
      end
    end

    describe '#expanded_kubernetes_namespace' do
      let(:job) { create(factory_type, environment: environment, options: options, pipeline: pipeline) }

      subject { job.expanded_kubernetes_namespace }

      context 'environment and namespace are not set' do
        let(:environment) { nil }
        let(:options) { nil }

        it { is_expected.to be_nil }
      end

      context 'environment is specified' do
        let(:environment) { 'production' }

        context 'namespace is not set' do
          let(:options) { nil }

          it { is_expected.to be_nil }
        end

        context 'namespace is provided' do
          let(:options) do
            {
              environment: {
                name: environment,
                kubernetes: {
                  namespace: namespace
                }
              }
            }
          end

          context 'with a static value' do
            let(:namespace) { 'production' }

            it { is_expected.to eq namespace }
          end

          context 'with a dynamic value' do
            let(:namespace) { 'deploy-$CI_COMMIT_REF_NAME' }

            it { is_expected.to eq 'deploy-master' }
          end
        end
      end
    end

    describe '#environment_auto_stop_in' do
      subject { job.environment_auto_stop_in }

      let(:job) { create(factory_type, options: options) }
      let(:options) { { environment: { auto_stop_in: '1 week' } } }

      it { is_expected.to eq('1 week') }

      context 'when options does not include auto_stop_in' do
        let(:options) { { environment: { name: 'production' } } }

        it { is_expected.to be_nil }
      end
    end

    describe '#expanded_auto_stop_in' do
      let(:job) { create(factory_type, environment: 'environment', options: options, pipeline: pipeline) }
      let(:options) do
        {
          environment: {
            name: 'production',
            auto_stop_in: auto_stop_in
          }
        }
      end

      subject { job.expanded_auto_stop_in }

      context 'when auto_stop_in is not set' do
        let(:auto_stop_in) { nil }

        it { is_expected.to be_nil }
      end

      context 'when auto_stop_in is set' do
        let(:auto_stop_in) { '1 day' }

        it { is_expected.to eq('1 day') }
      end

      context 'when auto_stop_in is set to a variable' do
        let(:auto_stop_in) { '$TTL' }
        let(:yaml_variables) do
          [
            { key: "TTL", value: '2 days', public: true }
          ]
        end

        before do
          stub_ci_job_definition(job, yaml_variables: yaml_variables)
        end

        it { is_expected.to eq('2 days') }
      end
    end

    shared_examples 'environment actions' do
      before do
        stub_ci_job_definition(job, options: options) if try(:options)
      end

      context 'when environment is defined' do
        before do
          job.update!(environment: 'review')
        end

        context 'no action is defined' do
          it 'uses start as the default action' do
            if action == 'start'
              is_expected.to be_truthy
            else
              is_expected.to be_falsey
            end
          end
        end

        context 'action is defined' do
          let(:options) { { environment: { action: action } } }

          it { is_expected.to be_truthy }
        end
      end

      context 'when environment is not defined' do
        before do
          job.update!(environment: nil)
        end

        it { is_expected.to be_falsey }
      end
    end

    describe '#deployment_job?' do
      let(:action) { 'start' }

      subject { job.deployment_job? }

      include_examples 'environment actions'
    end

    describe '#accesses_environment?' do
      let(:action) { 'access' }

      subject { job.accesses_environment? }

      include_examples 'environment actions'
    end

    describe '#prepares_environment?' do
      let(:action) { 'prepare' }

      subject { job.prepares_environment? }

      include_examples 'environment actions'
    end

    describe '#verifies_environment' do
      let(:action) { 'verify' }

      subject { job.verifies_environment? }

      include_examples 'environment actions'
    end

    describe '#stops_environment?' do
      before do
        stub_ci_job_definition(job, options: options) if try(:options)
      end

      subject { job.stops_environment? }

      context 'when environment is defined' do
        before do
          job.update!(environment: 'review')
        end

        context 'no action is defined' do
          it { is_expected.to be_falsey }
        end

        context 'and stop action is defined' do
          let(:options) { { environment: { action: 'stop' } } }

          it { is_expected.to be_truthy }
        end
      end

      context 'when environment is not defined' do
        before do
          job.update!(environment: nil)
        end

        it { is_expected.to be_falsey }
      end
    end
  end

  describe '#persisted_environment' do
    let!(:environment) do
      create(:environment, project: project, name: "foo-#{project.default_branch}")
    end

    subject { job.persisted_environment }

    context 'when referenced literally' do
      let(:job) do
        create(factory_type, pipeline: pipeline, environment: "foo-#{project.default_branch}")
      end

      it { is_expected.to eq(environment) }
    end

    context 'when referenced with a variable' do
      let(:job) do
        create(factory_type, pipeline: pipeline, environment: "foo-$CI_COMMIT_REF_NAME")
      end

      it { is_expected.to eq(environment) }
    end

    context 'when there is no environment' do
      it { is_expected.to be_nil }
    end

    context 'when job has a stop environment' do
      let(:job) { create(factory_type, :stop_review_app, pipeline: pipeline, environment: "foo-#{project.default_branch}") }

      it 'expands environment name' do
        expect(job).to receive(:expanded_environment_name).and_call_original

        is_expected.to eq(environment)
      end
    end
  end

  describe '#deployment_status' do
    context 'when job is a last deployment' do
      let(:job) { create(factory_type, :success, environment: 'production', pipeline: pipeline) }
      let(:environment) { create(:environment, name: 'production', project: job.project) }
      let!(:deployment) { create(:deployment, :success, environment: environment, project: environment.project, deployable: job) }

      it { expect(job.deployment_status).to eq(:last) }
    end

    context 'when there is a newer job with deployment' do
      let(:job) { create(factory_type, :success, environment: 'production', pipeline: pipeline) }
      let(:environment) { create(:environment, name: 'production', project: job.project) }
      let!(:deployment) { create(:deployment, :success, environment: environment, project: environment.project, deployable: job) }
      let!(:last_deployment) { create(:deployment, :success, environment: environment, project: environment.project) }

      it { expect(job.deployment_status).to eq(:out_of_date) }
    end

    context 'when job with deployment has failed' do
      let(:job) { create(factory_type, :failed, environment: 'production', pipeline: pipeline) }
      let(:environment) { create(:environment, name: 'production', project: job.project) }
      let!(:deployment) { create(:deployment, :success, environment: environment, project: environment.project, deployable: job) }

      it { expect(job.deployment_status).to eq(:failed) }
    end

    context 'when job with deployment is running' do
      let(:job) { create(factory_type, environment: 'production', pipeline: pipeline) }
      let(:environment) { create(:environment, name: 'production', project: job.project) }
      let!(:deployment) { create(:deployment, :success, environment: environment, project: environment.project, deployable: job) }

      it { expect(job.deployment_status).to eq(:creating) }
    end
  end

  def factory_type
    ::Gitlab::Utils.param_key(described_class)
  end
end
# rubocop:enable Layout/LineLength
# rubocop:enable RSpec/ContextWording
