# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::Components::FetchService, feature_category: :pipeline_composition do
  let_it_be(:project) { create(:project, :repository, create_tag: 'v1.0') }
  let_it_be(:user) { create(:user) }
  let_it_be(:current_user) { user }
  let_it_be(:current_host) { Gitlab.config.gitlab.host }

  let(:service) do
    described_class.new(address: address, current_user: current_user)
  end

  before do
    project.add_developer(user)
  end

  describe '#execute', :aggregate_failures do
    subject(:result) { service.execute }

    shared_examples 'an external component' do
      shared_examples 'component address' do
        context 'when content exists' do
          let(:sha) { project.commit(version).id }

          let(:content) do
            <<~COMPONENT
            job:
              script: echo
            COMPONENT
          end

          before do
            stub_project_blob(sha, component_yaml_path, content)
          end

          it 'returns the content' do
            expect(result).to be_success
            expect(result.payload[:content]).to eq(content)
          end
        end

        context 'when content does not exist' do
          it 'returns an error' do
            expect(result).to be_error
            expect(result.reason).to eq(:content_not_found)
          end
        end
      end

      context 'when user does not have permissions to read the code' do
        let(:version) { 'master' }
        let(:current_user) { create(:user) }

        it 'returns an error' do
          expect(result).to be_error
          expect(result.reason).to eq(:not_allowed)
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

      context 'when component path is the full path to a project' do
        let(:component_path) { project.full_path }
        let(:component_yaml_path) { 'template.yml' }

        it_behaves_like 'an external component'
      end

      context 'when component path points to a directory in a project' do
        let(:component_path) { "#{project.full_path}/my-component" }
        let(:component_yaml_path) { 'my-component/template.yml' }

        it_behaves_like 'an external component'
      end

      context 'when component path points to a nested directory in a project' do
        let(:component_path) { "#{project.full_path}/my-dir/my-component" }
        let(:component_yaml_path) { 'my-dir/my-component/template.yml' }

        it_behaves_like 'an external component'
      end
    end
  end

  def stub_project_blob(ref, path, content)
    allow_next_instance_of(Repository) do |instance|
      allow(instance).to receive(:blob_data_at).with(ref, path).and_return(content)
    end
  end
end
