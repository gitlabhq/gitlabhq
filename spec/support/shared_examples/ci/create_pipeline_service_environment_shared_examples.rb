# frozen_string_literal: true

RSpec.shared_examples 'creating a pipeline with environment keyword' do
  context 'with environment' do
    let(:config) do
      YAML.dump(
        deploy: {
          environment: { name: "review/$CI_COMMIT_REF_NAME" },
          **base_config
        })
    end

    it 'creates the environment', :sidekiq_inline do
      result = execute_service.payload

      expect(result).to be_persisted
      expect(Environment.find_by(name: "review/master")).to be_present
      expect(result.all_jobs.first.deployment).to be_persisted
      expect(result.all_jobs.first.deployment.deployable).to be_a(expected_deployable_class)
    end

    it 'sets tags when build job' do
      skip unless expected_deployable_class == Ci::Build

      result = execute_service.payload

      expect(result).to be_persisted
      expect(result.all_jobs.first.tag_list).to match_array(expected_tag_names)
    end
  end

  context 'with environment with auto_stop_in' do
    let(:config) do
      YAML.dump(
        deploy: {
          environment: { name: "review/$CI_COMMIT_REF_NAME", auto_stop_in: '1 day' },
          **base_config
        })
    end

    it 'creates the environment with auto stop in' do
      result = execute_service.payload

      expect(result).to be_persisted
      expect(result.all_jobs.first.options[:environment][:auto_stop_in]).to eq('1 day')
    end
  end

  context 'with environment name including persisted variables' do
    let(:config) do
      YAML.dump(
        deploy: {
          environment: { name: "review/id1$CI_PIPELINE_ID/id2$CI_JOB_ID" },
          **base_config
        }
      )
    end

    it 'skips persisted variables in environment name' do
      result = execute_service.payload

      expect(result).to be_persisted
      expect(Environment.find_by(name: "review/id1/id2")).to be_present
    end
  end

  context 'when environment with Kubernetes configuration' do
    let(:kubernetes_namespace) { 'custom-namespace' }
    let(:config) do
      YAML.dump(
        deploy: {
          environment: {
            name: "environment-name",
            kubernetes: { namespace: kubernetes_namespace }
          },
          **base_config
        }
      )
    end

    it 'stores the requested namespace' do
      result = execute_service.payload
      job = result.all_jobs.first

      expect(result).to be_persisted
      expect(job.options.dig(:environment, :kubernetes, :namespace)).to eq(kubernetes_namespace)
    end
  end

  context 'when environment with invalid name' do
    let(:config) do
      YAML.dump(deploy: { environment: { name: 'name,with,commas' }, **base_config })
    end

    it 'does not create an environment' do
      expect do
        result = execute_service.payload

        expect(result).to be_persisted
      end.not_to change { Environment.count }
    end
  end

  context 'when environment with duplicate names' do
    let(:config) do
      YAML.dump({
        deploy: { environment: { name: 'production' }, **base_config },
        deploy_2: { environment: { name: 'production' }, **base_config }
      })
    end

    it 'creates a pipeline with the environment', :sidekiq_inline do
      result = execute_service.payload

      expect(result).to be_persisted
      expect(Environment.find_by(name: 'production')).to be_present
      expect(result.all_jobs.first.deployment).to be_persisted
      expect(result.all_jobs.first.deployment.deployable).to be_a(expected_deployable_class)
    end
  end

  context 'when pipeline has a job with environment' do
    let(:pipeline) { execute_service.payload }

    context 'when environment name is valid' do
      let(:config) do
        YAML.dump({
          review_app: {
            environment: {
              name: 'review/${CI_COMMIT_REF_NAME}',
              url: 'http://${CI_COMMIT_REF_SLUG}-staging.example.com'
            },
            **base_config
          }
        })
      end

      it 'has a job with environment', :sidekiq_inline do
        expect(pipeline.all_jobs.count).to eq(1)
        expect(pipeline.all_jobs.first.persisted_environment.name).to eq('review/master')
        expect(pipeline.all_jobs.first.deployment.status).to eq(expected_deployment_status)
        expect(pipeline.all_jobs.first.status).to eq(expected_job_status)
      end
    end

    context 'when environment name is invalid' do
      let(:config) do
        YAML.dump({
          'job:deploy-to-test-site': {
            environment: {
              name: '${CI_JOB_NAME}',
              url: 'https://$APP_URL'
            },
            **base_config
          }
        })
      end

      it 'has a job without environment' do
        expect(pipeline.all_jobs.count).to eq(1)
        expect(pipeline.all_jobs.first.persisted_environment).to be_nil
        expect(pipeline.all_jobs.first.deployment).to be_nil
      end
    end
  end
end
