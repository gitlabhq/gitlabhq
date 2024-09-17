# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::Components::FetchService, feature_category: :pipeline_composition do
  let_it_be(:user) { create(:user) }
  let_it_be(:current_user) { user }
  let_it_be(:current_host) { Gitlab.config.gitlab.host }
  let_it_be(:content) do
    <<~COMPONENT
    job:
      script: echo
    COMPONENT
  end

  let(:service) do
    described_class.new(address: address, current_user: current_user)
  end

  let_it_be(:project) do
    project = create(
      :project, :custom_repo,
      files: {
        'templates/first-component.yml' => content,
        'templates/second-component/template.yml' => content
      }
    )

    project.repository.add_tag(project.creator, 'v0.1', project.repository.commit.sha)

    create(:release, project: project, tag: 'v0.1', sha: project.repository.commit.sha)
    create(:ci_catalog_resource, project: project)

    project
  end

  before do
    project.add_developer(user)
  end

  describe '#execute', :aggregate_failures do
    subject(:result) { service.execute }

    shared_examples 'an external component' do
      shared_examples 'component address' do
        context 'when content exists' do
          it 'returns the content' do
            expect(result).to be_success
            expect(result.payload[:content]).to eq(content)
          end
        end

        context 'when content does not exist' do
          let(:address) { "#{current_host}/#{component_path}@~version-does-not-exist" }

          it 'returns an error' do
            expect(result).to be_error
            expect(result.reason).to eq(:content_not_found)
          end
        end
      end

      context 'when user does not have permissions to read the code' do
        let(:version) { 'master' }
        let(:current_user) { create(:user) }

        it 'returns a generic error response' do
          expect(result).to be_error
          expect(result.reason).to eq(:not_allowed)
          expect(result.message)
            .to eq(
              "Component '#{address}' - " \
              "project does not exist or you don't have sufficient permissions"
            )
        end

        context 'when the user is external and the project is internal' do
          let(:current_user) { create(:user, :external) }
          let(:project) do
            project = create(
              :project, :custom_repo, :internal,
              files: {
                'templates/component/template.yml' => content
              }
            )
            project.repository.add_tag(project.creator, 'v0.1', project.repository.commit.sha)

            create(:release, project: project, tag: 'v0.1', sha: project.repository.commit.sha)
            create(:ci_catalog_resource, project: project)

            project
          end

          it 'returns an error response for external user accessing internal project' do
            expect(result).to be_error
            expect(result.reason).to eq(:not_allowed)
            expect(result.message)
              .to eq(
                "Component '#{address}' - " \
                "project is `Internal`, it cannot be accessed by an External User"
              )
          end
        end
      end

      context 'when version is a branch name' do
        it_behaves_like 'component address' do
          let(:version) { project.default_branch }
        end
      end

      context 'when version is a tag name' do
        it_behaves_like 'component address' do
          let(:version) { project.repository.tags.first.name }
        end
      end

      context 'when version is a commit sha' do
        it_behaves_like 'component address' do
          let(:version) { project.repository.tags.first.id }
        end
      end

      context 'when version is not provided' do
        let(:version) { nil }

        it 'returns an error' do
          expect(result).to be_error
          expect(result.reason).to eq(:content_not_found)
        end
      end

      context 'when version is ~latest' do
        let(:version) { '~latest' }
        let_it_be(:project) { create(:project) }

        context 'and the project is not a catalog resource' do
          it 'returns an error' do
            expect(result).to be_error
            expect(result.message).to eq(
              "Component '#{current_host}/#{component_path}@~latest' - " \
              'The ~latest version reference is not supported for non-catalog resources. ' \
              'Use a tag, branch, or commit SHA instead.'
            )
            expect(result.reason).to eq(:invalid_usage)
          end
        end

        context 'and the project does not exist' do
          let(:component_path) { 'unknown' }

          it 'returns an error' do
            expect(result).to be_error
            expect(result.reason).to eq(:content_not_found)
          end
        end
      end

      context 'when project does not exist' do
        let(:component_path) { 'unknown/component' }
        let(:version) { '1.0' }

        it 'returns an error' do
          expect(result).to be_error
          expect(result.reason).to eq(:content_not_found)
        end
      end

      context 'when host is different than the current instance host' do
        let(:current_host) { 'another-host.com' }
        let(:version) { '1.0' }

        it 'returns an error' do
          expect(result).to be_error
          expect(result.reason).to eq(:unsupported_path)
        end
      end
    end

    context 'when address points to an external component' do
      let(:address) { "#{current_host}/#{component_path}@#{version}" }

      context 'when component path points to a template file in a project' do
        let(:component_path) { "#{project.full_path}/first-component" }

        it_behaves_like 'an external component'
      end

      context 'when component path points to a template directory in a project' do
        let(:component_path) { "#{project.full_path}/second-component" }

        it_behaves_like 'an external component'
      end

      context 'when the project exists but the component does not' do
        let(:component_path) { "#{project.full_path}/unknown-component" }
        let(:version) { '~latest' }

        it 'returns a content not found error' do
          expect(result).to be_error
          expect(result.reason).to eq(:content_not_found)
        end
      end
    end
  end
end
