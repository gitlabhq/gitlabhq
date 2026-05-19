# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::CreatePipelineService, feature_category: :pipeline_composition do
  context 'for spec:component' do
    let_it_be(:project) { create(:project, :small_repo) }
    let_it_be(:user)    { project.first_owner }

    let_it_be(:components_project) do
      create(:project, :small_repo, creator: user, namespace: user.namespace)
    end

    let_it_be(:catalog_resource) { create(:ci_catalog_resource, :published, project: components_project) }

    let_it_be(:component_name) { 'my-component' }
    let_it_be(:component_version) { '0.1.1' }
    let_it_be(:component_file_path) { "templates/#{component_name}/template.yml" }

    let_it_be(:component_yaml) do
      <<~YAML
      spec:
        component: [name, sha, version, reference]
        inputs:
          compiler:
            default: gcc
          optimization_level:
            type: number
            default: 2

      ---

      test:
        script:
          - echo "Building with $[[ inputs.compiler ]] and optimization level $[[ inputs.optimization_level ]]"
          - echo "Component $[[ component.name ]] / $[[ component.sha ]] / $[[ component.version ]] / $[[ component.reference ]]"
      YAML
    end

    let_it_be(:component_sha) do
      components_project.repository.create_file(
        user, component_file_path, component_yaml, message: 'Add my first CI component', branch_name: 'master'
      )
    end

    let(:service) { described_class.new(project, user, { ref: 'refs/heads/master' }) }

    subject(:execute) { service.execute(:push, content: project_ci_yaml) }

    before_all do
      components_project.repository.add_tag(user, component_version, component_sha)

      create(:release, :with_catalog_resource_version,
        tag: component_version, author: user, project: components_project, sha: component_sha
      )
    end

    context 'when the component file is included as include:component' do
      let(:project_ci_yaml) do
        <<~YAML
        include:
          - component: #{component_path}
        YAML
      end

      context 'when the component path is with a full version' do
        let_it_be(:component_path) do
          "#{Gitlab.config.gitlab.host}/#{components_project.full_path}/#{component_name}@#{component_version}"
        end

        it 'creates a pipeline with correct jobs' do
          response = execute
          pipeline = response.payload

          expect(response).to be_success
          expect(pipeline).to be_created_successfully

          expect(pipeline.builds.map(&:name)).to contain_exactly('test')

          test_job = pipeline.builds.find { |build| build.name == 'test' }
          expect(test_job.options[:script]).to eq([
            'echo "Building with gcc and optimization level 2"',
            "echo \"Component #{component_name} / #{component_sha} / #{component_version} / #{component_version}\""
          ])
        end
      end

      context 'when the component path is with a partial version' do
        let_it_be(:component_path) do
          "#{Gitlab.config.gitlab.host}/#{components_project.full_path}/#{component_name}@0.1"
        end

        it 'creates a pipeline with correct jobs' do
          response = execute
          pipeline = response.payload

          expect(response).to be_success
          expect(pipeline).to be_created_successfully

          expect(pipeline.builds.map(&:name)).to contain_exactly('test')

          test_job = pipeline.builds.find { |build| build.name == 'test' }
          expect(test_job.options[:script]).to eq([
            'echo "Building with gcc and optimization level 2"',
            "echo \"Component #{component_name} / #{component_sha} / #{component_version} / 0.1\""
          ])
        end
      end

      context 'when the component path is with latest' do
        let_it_be(:component_path) do
          "#{Gitlab.config.gitlab.host}/#{components_project.full_path}/#{component_name}@~latest"
        end

        it 'creates a pipeline with correct jobs' do
          response = execute
          pipeline = response.payload

          expect(response).to be_success
          expect(pipeline).to be_created_successfully

          expect(pipeline.builds.map(&:name)).to contain_exactly('test')

          test_job = pipeline.builds.find { |build| build.name == 'test' }
          expect(test_job.options[:script]).to eq([
            'echo "Building with gcc and optimization level 2"',
            "echo \"Component #{component_name} / #{component_sha} / #{component_version} / ~latest\""
          ])
        end
      end

      context 'when the component path is with sha' do
        let_it_be(:component_path) do
          "#{Gitlab.config.gitlab.host}/#{components_project.full_path}/#{component_name}@#{component_sha}"
        end

        it 'creates a pipeline with correct jobs without version' do
          response = execute
          pipeline = response.payload

          expect(response).to be_success
          expect(pipeline).to be_created_successfully

          expect(pipeline.builds.map(&:name)).to contain_exactly('test')

          test_job = pipeline.builds.find { |build| build.name == 'test' }
          expect(test_job.options[:script]).to eq([
            'echo "Building with gcc and optimization level 2"',
            "echo \"Component #{component_name} / #{component_sha} /  / #{component_sha}\""
          ])
        end
      end
    end

    context 'when the component includes nested local files that uses component context' do
      let_it_be(:component_name) { 'parent-component' }
      let_it_be(:component_file_path) { "templates/#{component_name}/template.yml" }
      let_it_be(:local_file_path) { 'templates/local.yml' }
      let_it_be(:nested_local_file_path) { 'templates/nested-local.yml' }

      let(:component_path) do
        "#{Gitlab.config.gitlab.host}/#{components_project.full_path}/#{component_name}@#{component_version}"
      end

      let(:project_ci_yaml) do
        <<~YAML
        include:
          - component: #{component_path}
        YAML
      end

      let_it_be(:component_yaml) do
        <<~YAML
        spec:
          component: [name, sha, version, reference]
        ---
        include:
          - local: '/templates/local.yml'

        component-job:
          script:
            - echo "component $[[ component.name ]]"
        YAML
      end

      let_it_be(:local_yaml) do
        <<~YAML
        spec:
          component: [name, sha]
        ---
        include:
          - local: '/templates/nested-local.yml'

        local-job:
          script:
            - echo "local using component $[[ component.name ]] at $[[ component.sha ]]"
        YAML
      end

      let_it_be(:nested_local_yaml) do
        <<~YAML
        spec:
          component: [name, sha]
        ---
        nested-job:
          script:
            - echo "nested local using component $[[ component.name ]] at $[[ component.sha ]]"
        YAML
      end

      let_it_be(:parent_component_sha) do
        components_project.repository.create_file(
          user, nested_local_file_path, nested_local_yaml,
          message: 'Add nested local file', branch_name: 'master'
        )
        components_project.repository.create_file(
          user, local_file_path, local_yaml,
          message: 'Add local file', branch_name: 'master'
        )
        components_project.repository.create_file(
          user, component_file_path, component_yaml,
          message: 'Add component', branch_name: 'master'
        )
      end

      let_it_be(:component_version) { '0.2.0' }

      before_all do
        components_project.repository.add_tag(user, component_version, parent_component_sha)

        create(:release, :with_catalog_resource_version,
          tag: component_version, author: user, project: components_project, sha: parent_component_sha
        )
      end

      it 'propagates component context to local includes' do
        response = execute
        pipeline = response.payload

        expect(response).to be_success
        expect(pipeline).to be_created_successfully

        expect(pipeline.builds.map(&:name)).to contain_exactly('component-job', 'local-job', 'nested-job')

        parent_job = pipeline.builds.find { |build| build.name == 'component-job' }
        expect(parent_job.options[:script]).to eq([
          "echo \"component #{component_name}\""
        ])

        local_job = pipeline.builds.find { |build| build.name == 'local-job' }
        expect(local_job.options[:script]).to eq([
          "echo \"local using component #{component_name} at #{parent_component_sha}\""
        ])

        nested_job = pipeline.builds.find { |build| build.name == 'nested-job' }
        expect(nested_job.options[:script]).to eq([
          "echo \"nested local using component #{component_name} at #{parent_component_sha}\""
        ])
      end
    end

    context 'when the component file is included as include:project:file' do
      let(:project_ci_yaml) do
        <<~YAML
        include:
          - project: #{components_project.full_path}
            file: #{component_file_path}
        YAML
      end

      it 'does not interpolate and returns errors' do
        response = execute
        pipeline = response.payload

        expect(response).not_to be_success
        expect(pipeline).not_to be_created_successfully

        expect(response.message).to eq(
          "`templates/my-component/template.yml`: unknown interpolation provided: `name` in `component.name`"
        )
      end
    end

    context 'when component include times out', :clean_gitlab_redis_repository_cache do
      let(:component_path) do
        "#{Gitlab.config.gitlab.host}/#{components_project.full_path}/#{component_name}@#{component_version}"
      end

      let(:project_ci_yaml) do
        <<~YAML
        include:
          - component: #{component_path}
        job:
          script: exit 0
        YAML
      end

      context 'when timeout occurs' do
        before do
          stub_const('Gitlab::Ci::Config::GITALY_TIMEOUT_SECONDS', 0.1)
          stub_feature_flags(ci_cache_component_includes: false)

          allow_next_instance_of(Repository) do |instance|
            allow(instance).to receive(:blobs_at).and_raise(
                      GRPC::DeadlineExceeded.new('deadline exceeded')
                    )
          end
        end

        it 'fails with timeout error' do
          expect(Gitlab::ErrorTracking).to receive(:track_exception).and_call_original

          response = execute
          pipeline = response.payload

          expect(pipeline).to be_persisted
          pipeline.reload

          expect(pipeline.error_messages.map(&:content)).to include(
            'CI configuration fetch from Gitaly timed out. This may indicate Gitaly service slowness or an outage.'
          )
        end
      end
    end
  end
end
