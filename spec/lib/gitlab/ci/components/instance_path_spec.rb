# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Components::InstancePath, feature_category: :pipeline_composition do
  let_it_be(:user) { create(:user) }

  let(:path) { described_class.new(address: address) }
  let(:settings) { GitlabSettings::Options.build({ 'server_fqdn' => server_fqdn }) }
  let(:server_fqdn) { 'acme.com' }
  let(:fqdn_prefix) { "#{server_fqdn}/" }

  before do
    allow(::Settings).to receive(:gitlab_ci).and_return(settings)
  end

  describe '#fetch_content!' do
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

      context 'when fetching the latest release' do
        let(:version) { '~latest' }

        context 'when there is no project' do
          it_behaves_like 'does not find the component'
        end

        context 'when the project is not a catalog resource' do
          let_it_be(:project) { create(:project, :repository) }

          it_behaves_like 'does not find the component'
        end

        context 'when the project is a catalog resource' do
          let_it_be(:project) do
            create(
              :project, :custom_repo,
              files: {
                'templates/secret-detection.yml' => 'image: alpine_1'
              }
            )
          end

          let_it_be(:resource) { create(:ci_catalog_resource, project: project) }

          let_it_be(:v2_6_0) do
            sha = project.repository.commit('master').id
            release = create(:release, project: project, tag: '2.6.0', sha: sha, released_at: Date.yesterday)

            create(:ci_catalog_resource_version, catalog_resource: resource, release: release, semver: '2.6.0')
          end

          let_it_be(:v1_1_2) do
            sha = project.repository.update_file(
              user, 'templates/secret-detection.yml', 'image: alpine_2',
              message: 'Updates image', branch_name: project.default_branch
            )
            release = create(:release, project: project, tag: '1.1.2', sha: sha, released_at: Date.today)

            create(:ci_catalog_resource_version, catalog_resource: resource, release: release, semver: '1.1.2')
          end

          let_it_be(:v6_0_0_pre) do
            sha = project.repository.update_file(
              user, 'templates/secret-detection.yml', 'image: alpine_6',
              message: 'Updates release', branch_name: project.default_branch
            )
            release = create(:release, project: project, tag: '6.0.0-pre', sha: sha, released_at: Date.today)

            create(:ci_catalog_resource_version, catalog_resource: resource, release: release, semver: '6.0.0-pre')
          end

          it 'returns the component content of the latest semantic version', :aggregate_failures do
            result = path.fetch_content!(current_user: user)

            expect(result.content).to eq('image: alpine_1')
            expect(result.path).to eq('templates/secret-detection.yml')
            expect(path.project).to eq(project)
            expect(path.sha).to eq(v2_6_0.sha)
          end

          context 'when fetching the version with shorthand' do
            context 'when it is one digit' do
              let(:version) { '1' }

              it 'returns the component content of the latest for that version', :aggregate_failures do
                result = path.fetch_content!(current_user: user)

                expect(result.content).to eq('image: alpine_2')
              end
            end

            context 'when it is two digits' do
              let(:version) { '2.6' }

              it 'returns the component content of the latest for that version', :aggregate_failures do
                result = path.fetch_content!(current_user: user)

                expect(result.content).to eq('image: alpine_1')
              end
            end

            context 'when the version does not match' do
              let(:version) { '3' }

              it 'returns nil' do
                result = path.fetch_content!(current_user: user)
                expect(result).to be_nil
              end
            end

            context 'when the version matches a pre-release' do
              let(:version) { '6' }

              it 'returns nil as shorthand should not fetch pre-release versions' do
                result = path.fetch_content!(current_user: user)
                expect(result).to be_nil
              end
            end
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
        let(:server_fqdn) { 'acme.com/gitlab' }

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

        context 'when there is a release' do
          context 'when the version matches' do
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

        context 'when there are no releases' do
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

  describe '#invalid_usage_for_latest?' do
    let_it_be(:project) { create(:project) }
    let(:project_path) { project.full_path }
    let(:address) { "acme.com/#{project_path}/secret-detection@#{version}" }

    context 'when the version is ~latest and the project is not a catalog resource' do
      let(:version) { '~latest' }

      it 'returns true and therefore is valid' do
        expect(path.invalid_usage_for_latest?).to be_truthy
      end
    end

    context 'when the version is not ~latest' do
      let(:version) { '1.0.0' }

      it 'returns false' do
        expect(path.invalid_usage_for_latest?).to be_falsey
      end
    end

    context 'when the project is a catalog resource' do
      let(:version) { '~latest' }
      let!(:catalog_resource) { create(:ci_catalog_resource, project: project) }

      it 'returns false' do
        expect(path.invalid_usage_for_latest?).to be_falsey
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

    it { is_expected.to eq("#{server_fqdn}/") }
  end
end
