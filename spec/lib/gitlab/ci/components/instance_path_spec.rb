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
    let(:version) { 'master' }
    let(:project_path) { project.full_path }
    let(:address) { "acme.com/#{project_path}/secret-detection@#{version}" }

    context 'when the project repository contains a templates directory' do
      let_it_be(:project) do
        create(
          :project, :custom_repo,
          files: {
            'templates/secret-detection.yml' => 'image: alpine_1',
            'templates/dast/template.yml' => 'image: alpine_2',
            'templates/dast/another-template.yml' => 'image: alpine_3',
            'templates/dast/another-folder/template.yml' => 'image: alpine_4'
          }
        )
      end

      before do
        project.add_developer(user)
      end

      context 'when user does not have permissions' do
        it 'raises an error when fetching the content' do
          expect { path.fetch_content!(current_user: build(:user)) }
            .to raise_error(Gitlab::Access::AccessDeniedError)
        end
      end

      context 'when the component is simple (single file template)' do
        it 'fetches the component content', :aggregate_failures do
          expect(path.fetch_content!(current_user: user)).to eq('image: alpine_1')
          expect(path.host).to eq(current_host)
          expect(path.project_file_path).to eq('templates/secret-detection.yml')
          expect(path.project).to eq(project)
          expect(path.sha).to eq(project.commit('master').id)
        end
      end

      context 'when the component is complex (directory-based template)' do
        let(:address) { "acme.com/#{project_path}/dast@#{version}" }

        it 'fetches the component content', :aggregate_failures do
          expect(path.fetch_content!(current_user: user)).to eq('image: alpine_2')
          expect(path.host).to eq(current_host)
          expect(path.project_file_path).to eq('templates/dast/template.yml')
          expect(path.project).to eq(project)
          expect(path.sha).to eq(project.commit('master').id)
        end

        context 'when there is an invalid nested component folder' do
          let(:address) { "acme.com/#{project_path}/dast/another-folder@#{version}" }

          it 'returns nil' do
            expect(path.fetch_content!(current_user: user)).to be_nil
          end
        end

        context 'when there is an invalid nested component path' do
          let(:address) { "acme.com/#{project_path}/dast/another-template@#{version}" }

          it 'returns nil' do
            expect(path.fetch_content!(current_user: user)).to be_nil
          end
        end
      end

      context 'when fetching the latest version of a component' do
        let_it_be(:project) do
          create(
            :project, :custom_repo,
            files: {
              'templates/secret-detection.yml' => 'image: alpine_1'
            }
          )
        end

        let(:version) { '~latest' }

        let(:latest_sha) do
          project.repository.commit('master').id
        end

        before do
          create(:release, project: project, sha: project.repository.root_ref_sha,
            released_at: Time.zone.now - 1.day)

          project.repository.update_file(
            user, 'templates/secret-detection.yml', 'image: alpine_2',
            message: 'Updates image', branch_name: project.default_branch
          )

          create(:release, project: project, sha: latest_sha,
            released_at: Time.zone.now)
        end

        it 'fetches the component content', :aggregate_failures do
          expect(path.fetch_content!(current_user: user)).to eq('image: alpine_2')
          expect(path.host).to eq(current_host)
          expect(path.project_file_path).to eq('templates/secret-detection.yml')
          expect(path.project).to eq(project)
          expect(path.sha).to eq(latest_sha)
        end
      end

      context 'when version does not exist' do
        let(:version) { 'non-existent' }

        it 'returns nil', :aggregate_failures do
          expect(path.fetch_content!(current_user: user)).to be_nil
          expect(path.host).to eq(current_host)
          expect(path.project_file_path).to be_nil
          expect(path.project).to eq(project)
          expect(path.sha).to be_nil
        end
      end

      context 'when current GitLab instance is installed on a relative URL' do
        let(:address) { "acme.com/gitlab/#{project_path}/secret-detection@#{version}" }
        let(:current_host) { 'acme.com/gitlab/' }

        it 'fetches the component content', :aggregate_failures do
          expect(path.fetch_content!(current_user: user)).to eq('image: alpine_1')
          expect(path.host).to eq(current_host)
          expect(path.project_file_path).to eq('templates/secret-detection.yml')
          expect(path.project).to eq(project)
          expect(path.sha).to eq(project.commit('master').id)
        end
      end
    end

    # All the following tests are for deprecated code and will be removed
    # in https://gitlab.com/gitlab-org/gitlab/-/issues/415855
    context 'when the project does not contain a templates directory' do
      let(:project_path) { project.full_path }
      let(:address) { "acme.com/#{project_path}/component@#{version}" }

      let_it_be(:project) do
        create(
          :project, :custom_repo,
          files: {
            'component/template.yml' => 'image: alpine'
          }
        )
      end

      before do
        project.add_developer(user)
      end

      it 'fetches the component content', :aggregate_failures do
        expect(path.fetch_content!(current_user: user)).to eq('image: alpine')
        expect(path.host).to eq(current_host)
        expect(path.project_file_path).to eq('component/template.yml')
        expect(path.project).to eq(project)
        expect(path.sha).to eq(project.commit('master').id)
      end

      context 'when project path is nested under a subgroup' do
        let_it_be(:group) { create(:group, :nested) }
        let_it_be(:project) do
          create(
            :project, :custom_repo,
            files: {
              'component/template.yml' => 'image: alpine'
            },
            group: group
          )
        end

        it 'fetches the component content', :aggregate_failures do
          expect(path.fetch_content!(current_user: user)).to eq('image: alpine')
          expect(path.host).to eq(current_host)
          expect(path.project_file_path).to eq('component/template.yml')
          expect(path.project).to eq(project)
          expect(path.sha).to eq(project.commit('master').id)
        end
      end

      context 'when current GitLab instance is installed on a relative URL' do
        let(:address) { "acme.com/gitlab/#{project_path}/component@#{version}" }
        let(:current_host) { 'acme.com/gitlab/' }

        it 'fetches the component content', :aggregate_failures do
          expect(path.fetch_content!(current_user: user)).to eq('image: alpine')
          expect(path.host).to eq(current_host)
          expect(path.project_file_path).to eq('component/template.yml')
          expect(path.project).to eq(project)
          expect(path.sha).to eq(project.commit('master').id)
        end
      end

      context 'when version does not exist' do
        let(:version) { 'non-existent' }

        it 'returns nil', :aggregate_failures do
          expect(path.fetch_content!(current_user: user)).to be_nil
          expect(path.host).to eq(current_host)
          expect(path.project_file_path).to be_nil
          expect(path.project).to eq(project)
          expect(path.sha).to be_nil
        end
      end

      context 'when user does not have permissions' do
        it 'raises an error when fetching the content' do
          expect { path.fetch_content!(current_user: build(:user)) }
            .to raise_error(Gitlab::Access::AccessDeniedError)
        end
      end
    end
  end
end
