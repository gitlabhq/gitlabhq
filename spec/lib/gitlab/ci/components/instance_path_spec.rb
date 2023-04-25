# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Components::InstancePath, feature_category: :pipeline_composition do
  let_it_be(:user) { create(:user) }

  let(:path) { described_class.new(address: address, content_filename: 'template.yml') }
  let(:settings) { GitlabSettings::Options.build({ 'component_fqdn' => current_host }) }
  let(:current_host) { 'acme.com/' }

  before do
    allow(::Settings).to receive(:gitlab_ci).and_return(settings)
  end

  describe 'FQDN path' do
    let_it_be(:existing_project) { create(:project, :repository) }

    let(:project_path) { existing_project.full_path }
    let(:address) { "acme.com/#{project_path}/component@#{version}" }
    let(:version) { 'master' }

    context 'when project exists' do
      it 'provides the expected attributes', :aggregate_failures do
        expect(path.project).to eq(existing_project)
        expect(path.host).to eq(current_host)
        expect(path.sha).to eq(existing_project.commit('master').id)
        expect(path.project_file_path).to eq('component/template.yml')
      end

      context 'when content exists' do
        let(:content) { 'image: alpine' }

        before do
          allow_next_instance_of(Repository) do |instance|
            allow(instance)
              .to receive(:blob_data_at)
              .with(existing_project.commit('master').id, 'component/template.yml')
              .and_return(content)
          end
        end

        context 'when user has permissions to read code' do
          before do
            existing_project.add_developer(user)
          end

          it 'fetches the content' do
            expect(path.fetch_content!(current_user: user)).to eq(content)
          end
        end

        context 'when user does not have permissions to download code' do
          it 'raises an error when fetching the content' do
            expect { path.fetch_content!(current_user: user) }
              .to raise_error(Gitlab::Access::AccessDeniedError)
          end
        end
      end
    end

    context 'when project path is nested under a subgroup' do
      let(:existing_group) { create(:group, :nested) }
      let(:existing_project) { create(:project, :repository, group: existing_group) }

      it 'provides the expected attributes', :aggregate_failures do
        expect(path.project).to eq(existing_project)
        expect(path.host).to eq(current_host)
        expect(path.sha).to eq(existing_project.commit('master').id)
        expect(path.project_file_path).to eq('component/template.yml')
      end
    end

    context 'when current GitLab instance is installed on a relative URL' do
      let(:address) { "acme.com/gitlab/#{project_path}/component@#{version}" }
      let(:current_host) { 'acme.com/gitlab/' }

      it 'provides the expected attributes', :aggregate_failures do
        expect(path.project).to eq(existing_project)
        expect(path.host).to eq(current_host)
        expect(path.sha).to eq(existing_project.commit('master').id)
        expect(path.project_file_path).to eq('component/template.yml')
      end
    end

    context 'when version does not exist' do
      let(:version) { 'non-existent' }

      it 'provides the expected attributes', :aggregate_failures do
        expect(path.project).to eq(existing_project)
        expect(path.host).to eq(current_host)
        expect(path.sha).to be_nil
        expect(path.project_file_path).to eq('component/template.yml')
      end

      it 'returns nil when fetching the content' do
        expect(path.fetch_content!(current_user: user)).to be_nil
      end
    end

    context 'when version is `~latest`' do
      let(:version) { '~latest' }

      context 'when project is a catalog resource' do
        before do
          create(:catalog_resource, project: existing_project)
        end

        context 'when project has releases' do
          let_it_be(:releases) do
            [
              create(:release, project: existing_project, sha: 'sha-1', released_at: Time.zone.now - 1.day),
              create(:release, project: existing_project, sha: 'sha-2', released_at: Time.zone.now)
            ]
          end

          it 'returns the sha of the latest release' do
            expect(path.sha).to eq(releases.last.sha)
          end
        end

        context 'when project does not have releases' do
          it { expect(path.sha).to be_nil }
        end
      end

      context 'when project is not a catalog resource' do
        it { expect(path.sha).to be_nil }
      end
    end

    context 'when project does not exist' do
      let(:project_path) { 'non-existent/project' }

      it 'provides the expected attributes', :aggregate_failures do
        expect(path.project).to be_nil
        expect(path.host).to eq(current_host)
        expect(path.sha).to be_nil
        expect(path.project_file_path).to be_nil
      end

      it 'returns nil when fetching the content' do
        expect(path.fetch_content!(current_user: user)).to be_nil
      end
    end
  end
end
