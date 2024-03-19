# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Components::InstancePath, feature_category: :pipeline_composition do
  let_it_be(:user) { create(:user) }

  let(:path) { described_class.new(address: address) }
  let(:settings) { GitlabSettings::Options.build({ 'component_fqdn' => component_fqdn }) }
  let(:component_fqdn) { 'acme.com' }
  let(:fqdn_prefix) { "#{component_fqdn}/" }

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

      shared_examples 'does not find the component' do
        it 'returns nil' do
          result = path.fetch_content!(current_user: user)
          expect(result).to be_nil
        end
      end

      shared_examples 'finds the component' do
        shared_examples 'fetches the component content' do
          it 'fetches the component content', :aggregate_failures do
            result = path.fetch_content!(current_user: user)
            expect(result.content).to eq(file_content)
            expect(result.path).to eq(file_path)
            expect(path.project).to eq(project)
            expect(path.sha).to eq(project.commit('master').id)
          end
        end

        it_behaves_like 'fetches the component content'

        context 'when the there is a redirect set for the project' do
          let!(:redirect_route) { project.redirect_routes.create!(path: 'another-group/new-project') }
          let(:project_path) { redirect_route.path }

          it_behaves_like 'fetches the component content'
        end
      end

      context 'when the component is simple (single file template)' do
        it_behaves_like 'finds the component' do
          let(:file_path) { 'templates/secret-detection.yml' }
          let(:file_content) { 'image: alpine_1' }
        end
      end

      context 'when the component is complex (directory-based template)' do
        let(:address) { "acme.com/#{project_path}/dast@#{version}" }

        it_behaves_like 'finds the component' do
          let(:file_path) { 'templates/dast/template.yml' }
          let(:file_content) { 'image: alpine_2' }
        end

        context 'when there is an invalid nested component folder' do
          let(:address) { "acme.com/#{project_path}/dast/another-folder@#{version}" }

          it_behaves_like 'does not find the component'
        end

        context 'when there is an invalid nested component path' do
          let(:address) { "acme.com/#{project_path}/dast/another-template@#{version}" }

          it_behaves_like 'does not find the component'
        end
      end

      context "when the project path starts with '/'" do
        let(:project_path) { "/#{project.full_path}" }

        it_behaves_like 'does not find the component'
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

        it 'returns the component content of the latest project release', :aggregate_failures do
          result = path.fetch_content!(current_user: user)
          expect(result.content).to eq('image: alpine_2')
          expect(result.path).to eq('templates/secret-detection.yml')
          expect(path.project).to eq(project)
          expect(path.sha).to eq(latest_sha)
        end

        context 'when the project is a catalog resource' do
          let_it_be(:resource) { create(:ci_catalog_resource, project: project) }

          before do
            project.releases.each do |release|
              create(:ci_catalog_resource_version, catalog_resource: resource, release: release)
            end
            project.catalog_resource.versions.first.update!(version: '1.0.0')
            project.catalog_resource.versions.last.update!(version: '2.0.0')
          end

          it 'returns the component content of the latest catalog resource version', :aggregate_failures do
            result = path.fetch_content!(current_user: user)
            expect(result.content).to eq('image: alpine_2')
            expect(result.path).to eq('templates/secret-detection.yml')
            expect(path.project).to eq(project)
            expect(path.sha).to eq(latest_sha)
          end
        end
      end

      context 'when version does not exist' do
        let(:version) { 'non-existent' }

        it 'returns nil', :aggregate_failures do
          expect(path.fetch_content!(current_user: user)).to be_nil
          expect(path.project).to eq(project)
          expect(path.sha).to be_nil
        end
      end

      context 'when current GitLab instance is installed on a relative URL' do
        let(:address) { "acme.com/gitlab/#{project_path}/secret-detection@#{version}" }
        let(:component_fqdn) { 'acme.com/gitlab' }

        it 'fetches the component content', :aggregate_failures do
          result = path.fetch_content!(current_user: user)
          expect(result.content).to eq('image: alpine_1')
          expect(result.path).to eq('templates/secret-detection.yml')
          expect(path.project).to eq(project)
          expect(path.sha).to eq(project.commit('master').id)
        end
      end

      describe '#sha' do
        let_it_be(:version) { '0.1.0' }
        let_it_be(:catalog_resource) { create(:ci_catalog_resource, :published, project: project) }
        let_it_be(:commit) { project.repository.commit }
        let_it_be(:tag) { project.repository.add_tag(user, version, commit.id) }

        before_all do
          project.add_maintainer(user)
          project.repository.rm_tag(user, version)
          project.repository.add_tag(user, version, commit.id)
        end

        context 'when project has a release' do
          context 'when version match' do
            let_it_be(:release) do
              create(
                :release, :with_catalog_resource_version,
                project: project, tag: version, author: user, sha: commit.id
              )
            end

            it 'returns the release sha' do
              result = path.fetch_content!(current_user: user)

              expect(path.sha).to eq(release.sha)

              expect(result.content).to eq('image: alpine_1')
              expect(result.path).to eq('templates/secret-detection.yml')
              expect(path.project).to eq(project)
            end
          end

          context 'when version does not match' do
            let_it_be(:release) do
              create(
                :release, :with_catalog_resource_version,
                project: project, tag: '0.2.0', author: user, sha: commit.id
              )
            end

            it 'returns project commit sha' do
              result = path.fetch_content!(current_user: user)

              expect(path.sha).to eq(project.commit(version).id)

              expect(result.content).to eq('image: alpine_1')
              expect(result.path).to eq('templates/secret-detection.yml')
              expect(path.project).to eq(project)
            end
          end
        end

        context 'when project does not have any releases' do
          it 'returns project commit sha' do
            result = path.fetch_content!(current_user: user)

            expect(path.sha).to eq(project.commit(version).id)

            expect(result.content).to eq('image: alpine_1')
            expect(result.path).to eq('templates/secret-detection.yml')
            expect(path.project).to eq(project)
          end
        end
      end
    end
  end

  describe '.match?' do
    subject(:match) { described_class.match?(address) }

    context 'when address is a valid path' do
      let(:address) { "#{fqdn_prefix}group/project@master" }

      it { is_expected.to be_truthy }
    end

    context 'when address is an invalid path' do
      let(:address) { 'group/project@master' }

      it { is_expected.to be_falsey }
    end
  end

  describe '.fqdn_prefix' do
    subject(:fqdn_prefix) { described_class.fqdn_prefix }

    it { is_expected.to eq("#{component_fqdn}/") }
  end
end
