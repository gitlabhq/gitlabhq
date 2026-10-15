# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Creating a pipeline that includes bundled CI components', feature_category: :pipeline_composition do
  context 'when a component resolves from a bundle' do
    let_it_be(:project, freeze: false) { create(:project, :small_repo) }
    let_it_be(:user, freeze: false) { project.first_owner }

    let_it_be(:components_project, freeze: false) do
      create(:project, :small_repo, creator: user, namespace: user.namespace)
    end

    let_it_be(:catalog_resource, freeze: false) do
      create(:ci_catalog_resource, :published, project: components_project)
    end

    let_it_be(:component_name) { 'my-component' }
    let_it_be(:component_version) { '0.1.1' }
    let_it_be(:component_file_path) { "templates/#{component_name}/template.yml" }

    let_it_be(:component_yaml) do
      <<~YAML
      spec:
        component: [name, sha, version, reference]
        inputs:
          job_prefix:
            default: nested
      ---
      include:
        - local: templates/#{component_name}/nested.yml
          inputs:
            job_name: $[[ inputs.job_prefix ]]-job
          rules:
            - if: $INCLUDE_NESTED == "true"
        - local: templates/#{component_name}/exists.yml
          rules:
            - exists:
                paths: [consumer-only.txt]
                project: $CI_PROJECT_PATH

      component-info:
        script: echo "$[[ component.name ]] / $[[ component.sha ]] / $[[ component.version ]] / $[[ component.reference ]]"
      YAML
    end

    let_it_be(:component_sha, freeze: false) do
      components_project.repository.create_file(
        user, component_file_path, component_yaml, message: 'Add component', branch_name: 'master'
      )
    end

    let(:bundle) do
      Gitlab::Ci::Catalog::Bundle::Contents.new(
        name: component_name,
        version: component_version,
        sha: component_sha,
        entry_path: component_file_path,
        files: {
          component_file_path => component_yaml,
          "templates/#{component_name}/nested.yml" => <<~YAML,
            spec:
              inputs:
                job_name:
            ---
            $[[ inputs.job_name ]]:
              script: echo nested
          YAML
          "templates/#{component_name}/exists.yml" => <<~YAML
            exists-job:
              script: echo exists
          YAML
        }
      )
    end

    let(:component_path) do
      "#{Gitlab.config.gitlab.host}/#{components_project.full_path}/#{component_name}@#{component_version}"
    end

    let(:project_ci_yaml) do
      <<~YAML
      include:
        - component: #{component_path}
          inputs:
            job_prefix: consumer
      YAML
    end

    let(:service) { Ci::CreatePipelineService.new(project, user, { ref: 'refs/heads/master' }) }

    subject(:pipeline) { service.execute(:push, content: project_ci_yaml).payload }

    before_all do
      components_project.repository.add_tag(user, component_version, component_sha)

      project.repository.create_file(
        user, 'consumer-only.txt', 'present', message: 'Add file', branch_name: 'master'
      )

      create(:release, :with_catalog_resource_version,
        tag: component_version, author: user, project: components_project, sha: component_sha
      )
    end

    before do
      allow_next_instance_of(::Ci::Components::FetchService) do |fetch_service|
        allow(fetch_service).to receive(:execute).and_wrap_original do |original|
          result = original.call

          ServiceResponse.success(payload: result.payload.except(:project, :sha).merge(bundle: bundle))
        end
      end
    end

    it 'renders the component context the same as the source path' do
      expect(pipeline).to be_created_successfully

      expect(pipeline.builds.find_by(name: 'component-info').options[:script]).to eq([
        "echo \"#{component_name} / #{component_sha} / #{component_version} / #{component_version}\""
      ])
    end

    context 'when the consumer variable matches the include rule' do
      before do
        create(:ci_variable, project: project, key: 'INCLUDE_NESTED', value: 'true')
      end

      it 'includes the nested file from the bundle with the consumer inputs' do
        expect(pipeline).to be_created_successfully
        expect(pipeline.builds.map(&:name)).to include('consumer-job')
      end
    end

    context 'when the consumer variable does not match the include rule' do
      it 'skips the nested file' do
        expect(pipeline).to be_created_successfully
        expect(pipeline.builds.map(&:name)).not_to include('consumer-job')
      end
    end

    it 'evaluates rules:exists against the consumer repository' do
      expect(pipeline).to be_created_successfully
      expect(pipeline.builds.map(&:name)).to include('exists-job')
    end
  end
end
