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

    context 'when the project repository contains a templates directory' do
      let_it_be(:existing_project) do
        create(
          :project, :custom_repo,
          files: {
            'templates/file.yml' => 'image: alpine_1',
            'templates/dir/template.yml' => 'image: alpine_2'
          }
        )
      end

      let(:project_path) { existing_project.full_path }
      let(:address) { "acme.com/#{project_path}/file@#{version}" }

      before do
        existing_project.add_developer(user)
      end

      context 'when user does not have permissions' do
        it 'raises an error when fetching the content' do
          expect { path.fetch_content!(current_user: build(:user)) }
            .to raise_error(Gitlab::Access::AccessDeniedError)
        end
      end

      context 'when templates directory is top level' do
        it 'fetches the content' do
          expect(path.fetch_content!(current_user: user)).to eq('image: alpine_1')
        end

        it 'provides the expected attributes', :aggregate_failures do
          expect(path.host).to eq(current_host)
          expect(path.project_file_path).to eq('file/template.yml')
          expect(path.project).to eq(existing_project)
          expect(path.sha).to eq(existing_project.commit('master').id)
        end

        context 'when file name is `template.yml`' do
          let(:address) { "acme.com/#{project_path}/dir@#{version}" }

          it 'fetches the content' do
            expect(path.fetch_content!(current_user: user)).to eq('image: alpine_2')
          end

          it 'provides the expected attributes', :aggregate_failures do
            expect(path.host).to eq(current_host)
            expect(path.project_file_path).to eq('dir/template.yml')
            expect(path.project).to eq(existing_project)
            expect(path.sha).to eq(existing_project.commit('master').id)
          end
        end
      end

      context 'when the project is nested under a subgroup' do
        let_it_be(:existing_group) { create(:group, :nested) }
        let_it_be(:existing_project) do
          create(
            :project, :custom_repo,
            files: {
              'templates/file.yml' => 'image: alpine_1'
            },
            group: existing_group
          )
        end

        it 'fetches the content' do
          expect(path.fetch_content!(current_user: user)).to eq('image: alpine_1')
        end

        it 'provides the expected attributes', :aggregate_failures do
          expect(path.host).to eq(current_host)
          expect(path.project_file_path).to eq('file/template.yml')
          expect(path.project).to eq(existing_project)
          expect(path.sha).to eq(existing_project.commit('master').id)
        end
      end

      context 'when fetching the latest version' do
        let_it_be(:existing_project) do
          create(
            :project, :custom_repo,
            files: {
              'templates/file.yml' => 'image: alpine_1'
            }
          )
        end

        let(:version) { '~latest' }

        let(:latest_sha) do
          existing_project.repository.find_commits_by_message('Updates image').commits.last.sha
        end

        before do
          create(:release, project: existing_project, sha: existing_project.repository.root_ref_sha,
            released_at: Time.zone.now - 1.day)

          existing_project.repository.update_file(
            user, 'templates/file.yml', 'image: alpine_2',
            message: 'Updates image', branch_name: existing_project.default_branch
          )

          create(:release, project: existing_project, sha: latest_sha,
            released_at: Time.zone.now)
        end

        it 'fetches the content' do
          expect(path.fetch_content!(current_user: user)).to eq('image: alpine_2')
        end

        it 'provides the expected attributes', :aggregate_failures do
          expect(path.host).to eq(current_host)
          expect(path.project_file_path).to eq('file/template.yml')
          expect(path.project).to eq(existing_project)
          expect(path.sha).to eq(latest_sha)
        end
      end

      context 'when version does not exist' do
        let(:version) { 'non-existent' }

        it 'returns nil when fetching the content' do
          expect(path.fetch_content!(current_user: user)).to be_nil
        end

        it 'provides the expected attributes', :aggregate_failures do
          expect(path.host).to eq(current_host)
          expect(path.project_file_path).to eq('file/template.yml')
          expect(path.project).to eq(existing_project)
          expect(path.sha).to be_nil
        end
      end

      context 'when current GitLab instance is installed on a relative URL' do
        let(:address) { "acme.com/gitlab/#{project_path}/file@#{version}" }
        let(:current_host) { 'acme.com/gitlab/' }

        it 'fetches the content' do
          expect(path.fetch_content!(current_user: user)).to eq('image: alpine_1')
        end

        it 'provides the expected attributes', :aggregate_failures do
          expect(path.host).to eq(current_host)
          expect(path.project_file_path).to eq('file/template.yml')
          expect(path.project).to eq(existing_project)
          expect(path.sha).to eq(existing_project.commit('master').id)
        end
      end
    end

    # All the following tests are for deprecated code and will be removed
    # in https://gitlab.com/gitlab-org/gitlab/-/issues/415855
    context 'when the project does not contain a templates directory' do
      let(:project_path) { existing_project.full_path }
      let(:address) { "acme.com/#{project_path}/component@#{version}" }

      let_it_be(:existing_project) do
        create(
          :project, :custom_repo,
          files: {
            'component/template.yml' => 'image: alpine'
          }
        )
      end

      before do
        existing_project.add_developer(user)
      end

      it 'fetches the content' do
        expect(path.fetch_content!(current_user: user)).to eq('image: alpine')
      end

      it 'provides the expected attributes', :aggregate_failures do
        expect(path.host).to eq(current_host)
        expect(path.project_file_path).to eq('component/template.yml')
        expect(path.project).to eq(existing_project)
        expect(path.sha).to eq(existing_project.commit('master').id)
      end

      context 'when project path is nested under a subgroup' do
        let_it_be(:existing_group) { create(:group, :nested) }
        let_it_be(:existing_project) do
          create(
            :project, :custom_repo,
            files: {
              'component/template.yml' => 'image: alpine'
            },
            group: existing_group
          )
        end

        it 'fetches the content' do
          expect(path.fetch_content!(current_user: user)).to eq('image: alpine')
        end

        it 'provides the expected attributes', :aggregate_failures do
          expect(path.host).to eq(current_host)
          expect(path.project_file_path).to eq('component/template.yml')
          expect(path.project).to eq(existing_project)
          expect(path.sha).to eq(existing_project.commit('master').id)
        end
      end

      context 'when current GitLab instance is installed on a relative URL' do
        let(:address) { "acme.com/gitlab/#{project_path}/component@#{version}" }
        let(:current_host) { 'acme.com/gitlab/' }

        it 'fetches the content' do
          expect(path.fetch_content!(current_user: user)).to eq('image: alpine')
        end

        it 'provides the expected attributes', :aggregate_failures do
          expect(path.host).to eq(current_host)
          expect(path.project_file_path).to eq('component/template.yml')
          expect(path.project).to eq(existing_project)
          expect(path.sha).to eq(existing_project.commit('master').id)
        end
      end

      context 'when version does not exist' do
        let(:version) { 'non-existent' }

        it 'returns nil when fetching the content' do
          expect(path.fetch_content!(current_user: user)).to be_nil
        end

        it 'provides the expected attributes', :aggregate_failures do
          expect(path.host).to eq(current_host)
          expect(path.project_file_path).to eq('component/template.yml')
          expect(path.project).to eq(existing_project)
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
