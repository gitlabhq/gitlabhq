# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::NpmProjectPackages do
  include_context 'npm api setup'

  describe 'GET /api/v4/projects/:id/packages/npm/*package_name' do
    it_behaves_like 'handling get metadata requests', scope: :project do
      let(:url) { api("/projects/#{project.id}/packages/npm/#{package_name}") }
    end
  end

  describe 'GET /api/v4/projects/:id/packages/npm/-/package/*package_name/dist-tags' do
    it_behaves_like 'handling get dist tags requests', scope: :project do
      let(:url) { api("/projects/#{project.id}/packages/npm/-/package/#{package_name}/dist-tags") }
    end
  end

  describe 'PUT /api/v4/projects/:id/packages/npm/-/package/*package_name/dist-tags/:tag' do
    it_behaves_like 'handling create dist tag requests', scope: :project do
      let(:url) { api("/projects/#{project.id}/packages/npm/-/package/#{package_name}/dist-tags/#{tag_name}") }
    end
  end

  describe 'DELETE /api/v4/projects/:id/packages/npm/-/package/*package_name/dist-tags/:tag' do
    it_behaves_like 'handling delete dist tag requests', scope: :project do
      let(:url) { api("/projects/#{project.id}/packages/npm/-/package/#{package_name}/dist-tags/#{tag_name}") }
    end
  end

  describe 'GET /api/v4/projects/:id/packages/npm/*package_name/-/*file_name' do
    let(:package_file) { package.package_files.first }

    let(:headers) { {} }
    let(:url) { api("/projects/#{project.id}/packages/npm/#{package.name}/-/#{package_file.file_name}") }

    subject { get(url, headers: headers) }

    before do
      project.add_developer(user)
    end

    shared_examples 'successfully downloads the file' do
      it 'returns the file' do
        subject

        expect(response).to have_gitlab_http_status(:ok)
        expect(response.media_type).to eq('application/octet-stream')
      end
    end

    shared_examples 'a package file that requires auth' do
      it 'denies download with no token' do
        subject

        expect(response).to have_gitlab_http_status(:not_found)
      end

      context 'with access token' do
        let(:headers) { build_token_auth_header(token.token) }

        it_behaves_like 'successfully downloads the file'
      end

      context 'with job token' do
        let(:headers) { build_token_auth_header(job.token) }

        it_behaves_like 'successfully downloads the file'
      end
    end

    context 'a public project' do
      let(:snowplow_gitlab_standard_context) { { project: project, namespace: project.namespace } }

      it_behaves_like 'successfully downloads the file'
      it_behaves_like 'a package tracking event', 'API::NpmPackages', 'pull_package'

      context 'with a job token for a different user' do
        let_it_be(:other_user) { create(:user) }
        let_it_be_with_reload(:other_job) { create(:ci_build, :running, user: other_user, project: project) }

        let(:headers) { build_token_auth_header(other_job.token) }

        it_behaves_like 'successfully downloads the file'
      end
    end

    context 'private project' do
      before do
        project.update!(visibility_level: Gitlab::VisibilityLevel::PRIVATE)
      end

      it_behaves_like 'a package file that requires auth'

      context 'with guest' do
        let(:headers) { build_token_auth_header(token.token) }

        it 'denies download when not enough permissions' do
          project.add_guest(user)

          subject

          expect(response).to have_gitlab_http_status(:forbidden)
        end
      end
    end

    context 'internal project' do
      before do
        project.update!(visibility_level: Gitlab::VisibilityLevel::INTERNAL)
      end

      it_behaves_like 'a package file that requires auth'
    end
  end

  describe 'PUT /api/v4/projects/:id/packages/npm/:package_name' do
    before do
      project.add_developer(user)
    end

    shared_examples 'handling invalid record with 400 error' do
      it 'handles an ActiveRecord::RecordInvalid exception with 400 error' do
        expect { upload_package_with_token(package_name, params) }
          .not_to change { project.packages.count }

        expect(response).to have_gitlab_http_status(:bad_request)
      end
    end

    context 'when params are correct' do
      context 'invalid package record' do
        context 'invalid package name' do
          let(:package_name) { "@#{group.path}/my_inv@@lid_package_name" }
          let(:params) { upload_params(package_name: package_name) }

          it_behaves_like 'handling invalid record with 400 error'
        end

        context 'invalid package version' do
          using RSpec::Parameterized::TableSyntax

          let(:package_name) { "@#{group.path}/my_package_name" }

          where(:version) do
            [
              '1',
              '1.2',
              '1./2.3',
              '../../../../../1.2.3',
              '%2e%2e%2f1.2.3'
            ]
          end

          with_them do
            let(:params) { upload_params(package_name: package_name, package_version: version) }

            it_behaves_like 'handling invalid record with 400 error'
          end
        end
      end

      context 'valid package record' do
        let(:params) { upload_params(package_name: package_name) }
        let(:snowplow_gitlab_standard_context) { { project: project, namespace: project.namespace, user: user } }

        shared_examples 'handling upload with different authentications' do
          context 'with access token' do
            subject { upload_package_with_token(package_name, params) }

            it_behaves_like 'a package tracking event', 'API::NpmPackages', 'push_package'

            it 'creates npm package with file' do
              expect { subject }
                .to change { project.packages.count }.by(1)
                .and change { Packages::PackageFile.count }.by(1)
                .and change { Packages::Tag.count }.by(1)

              expect(response).to have_gitlab_http_status(:ok)
            end
          end

          it 'creates npm package with file with job token' do
            expect { upload_package_with_job_token(package_name, params) }
              .to change { project.packages.count }.by(1)
              .and change { Packages::PackageFile.count }.by(1)

            expect(response).to have_gitlab_http_status(:ok)
          end

          context 'with an authenticated job token' do
            let!(:job) { create(:ci_build, user: user) }

            before do
              Grape::Endpoint.before_each do |endpoint|
                expect(endpoint).to receive(:current_authenticated_job) { job }
              end
            end

            after do
              Grape::Endpoint.before_each nil
            end

            it 'creates the package metadata' do
              upload_package_with_token(package_name, params)

              expect(response).to have_gitlab_http_status(:ok)
              expect(project.reload.packages.find(json_response['id']).original_build_info.pipeline).to eq job.pipeline
            end
          end
        end

        context 'with a scoped name' do
          let(:package_name) { "@#{group.path}/my_package_name" }

          it_behaves_like 'handling upload with different authentications'
        end

        context 'with any scoped name' do
          let(:package_name) { "@any_scope/my_package_name" }

          it_behaves_like 'handling upload with different authentications'
        end

        context 'with an unscoped name' do
          let(:package_name) { "my_unscoped_package_name" }

          it_behaves_like 'handling upload with different authentications'
        end
      end

      context 'package creation fails' do
        let(:package_name) { "@#{group.path}/my_package_name" }
        let(:params) { upload_params(package_name: package_name) }

        it 'returns an error if the package already exists' do
          create(:npm_package, project: project, version: '1.0.1', name: "@#{group.path}/my_package_name")
          expect { upload_package_with_token(package_name, params) }
            .not_to change { project.packages.count }

          expect(response).to have_gitlab_http_status(:forbidden)
        end
      end

      context 'with dependencies' do
        let(:package_name) { "@#{group.path}/my_package_name" }
        let(:params) { upload_params(package_name: package_name, file: 'npm/payload_with_duplicated_packages.json') }

        it 'creates npm package with file and dependencies' do
          expect { upload_package_with_token(package_name, params) }
            .to change { project.packages.count }.by(1)
            .and change { Packages::PackageFile.count }.by(1)
            .and change { Packages::Dependency.count}.by(4)
            .and change { Packages::DependencyLink.count}.by(6)

          expect(response).to have_gitlab_http_status(:ok)
        end

        context 'with existing dependencies' do
          before do
            name = "@#{group.path}/existing_package"
            upload_package_with_token(name, upload_params(package_name: name, file: 'npm/payload_with_duplicated_packages.json'))
          end

          it 'reuses them' do
            expect { upload_package_with_token(package_name, params) }
              .to change { project.packages.count }.by(1)
              .and change { Packages::PackageFile.count }.by(1)
              .and not_change { Packages::Dependency.count}
              .and change { Packages::DependencyLink.count}.by(6)
          end
        end
      end
    end

    def upload_package(package_name, params = {})
      token = params.delete(:access_token) || params.delete(:job_token)
      headers = build_token_auth_header(token)
      put api("/projects/#{project.id}/packages/npm/#{package_name.sub('/', '%2f')}"), params: params, headers: headers
    end

    def upload_package_with_token(package_name, params = {})
      upload_package(package_name, params.merge(access_token: token.token))
    end

    def upload_package_with_job_token(package_name, params = {})
      upload_package(package_name, params.merge(job_token: job.token))
    end

    def upload_params(package_name:, package_version: '1.0.1', file: 'npm/payload.json')
      Gitlab::Json.parse(fixture_file("packages/#{file}")
          .gsub('@root/npm-test', package_name)
          .gsub('1.0.1', package_version))
    end
  end
end
