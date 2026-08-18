# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::Catalog::Resources::Bundle::CompileService, feature_category: :pipeline_composition do
  let_it_be(:publisher) { create(:user) }

  let_it_be_with_reload(:project) do
    create(:project, :custom_repo, files: {
      'templates/child.yml' => "child-job:\n  script: echo child",
      'templates/main.yml' => <<~YAML
        include:
          - local: templates/child.yml
        main-job:
          script: echo main
      YAML
    })
  end

  let_it_be(:release) do
    create(:release, project: project, sha: project.repository.root_ref_sha, author: publisher)
  end

  let_it_be_with_reload(:catalog_resource) { create(:ci_catalog_resource, project: project) }
  let_it_be(:version) do
    create(:ci_catalog_resource_version, release: release, catalog_resource: catalog_resource)
  end

  subject(:execute) { described_class.new(version).execute }

  describe '#execute' do
    it 'compiles every component into a self-contained document', :aggregate_failures do
      expect(execute).to be_success

      components = execute.payload[:components]
      expect(components.map { |component| component[:name] }).to match_array(%w[child main])

      main = components.find { |component| component[:name] == 'main' }[:content]
      expect(main).not_to include('include')
      expect(main).to include('child-job')
    end

    context 'when the version has no publisher' do
      before do
        allow(version).to receive(:published_by).and_return(nil)
      end

      it 'returns an error without compiling', :aggregate_failures do
        expect(execute).to be_error
        expect(execute.reason).to eq(:missing_publisher)
      end
    end

    context 'when a component cannot resolve extends' do
      let_it_be_with_reload(:project) do
        create(:project, :custom_repo, files: {
          'templates/main.yml' => <<~YAML
            main-job:
              extends: .missing
              script: echo main
          YAML
        })
      end

      let_it_be(:release) do
        create(:release, project: project, sha: project.repository.root_ref_sha, author: publisher)
      end

      let_it_be_with_reload(:catalog_resource) { create(:ci_catalog_resource, project: project) }
      let_it_be(:version) do
        create(:ci_catalog_resource_version, release: release, catalog_resource: catalog_resource)
      end

      it 'returns a compile_failed error rather than raising', :aggregate_failures do
        expect(execute).to be_error
        expect(execute.reason).to eq(:compile_failed)
        expect(execute.message).to match(/unknown keys in `extends`/)
      end
    end

    context 'with a private component dependency' do
      let_it_be(:private_project) { create(:project, :private, :repository) }

      let_it_be_with_reload(:project) do
        create(:project, :custom_repo, files: {
          'templates/main.yml' => <<~YAML
            include:
              - component: #{Gitlab.config.gitlab.host}/#{private_project.full_path}/secret@v1
            main-job:
              script: echo main
          YAML
        })
      end

      let_it_be(:release) do
        create(:release, project: project, sha: project.repository.root_ref_sha, author: publisher)
      end

      let_it_be_with_reload(:catalog_resource) { create(:ci_catalog_resource, project: project) }
      let_it_be(:version) do
        create(:ci_catalog_resource_version, release: release, catalog_resource: catalog_resource)
      end

      before_all do
        sha = private_project.repository.create_file(
          private_project.first_owner,
          'templates/secret/template.yml',
          "secret-job:\n  script: echo secret",
          message: 'Add secret component',
          branch_name: private_project.default_branch
        )
        private_project.repository.add_tag(private_project.first_owner, 'v1', sha)
      end

      context 'when the publisher can read it (positive control)' do
        before_all do
          private_project.add_developer(publisher)
        end

        it 'compiles and inlines the dependency', :aggregate_failures do
          expect(execute).to be_success
          expect(execute.payload[:components].first[:content]).to include('secret-job')
        end
      end

      context 'when the publisher cannot read it' do
        it 'fails on the access check and inlines nothing', :aggregate_failures do
          expect(execute).to be_error
          expect(execute.reason).to eq(:compile_failed)
          expect(execute.message).to match(/permission|does not exist/i)
          expect(execute.message).not_to include('content not found')
          expect(execute.payload[:components]).to be_nil
        end
      end
    end
  end
end
