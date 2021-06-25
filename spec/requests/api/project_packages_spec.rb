# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::ProjectPackages do
  let_it_be(:project) { create(:project, :public) }

  let(:user) { create(:user) }
  let!(:package1) { create(:npm_package, project: project, version: '3.1.0', name: "@#{project.root_namespace.path}/foo1") }
  let(:package_url) { "/projects/#{project.id}/packages/#{package1.id}" }
  let!(:package2) { create(:nuget_package, project: project, version: '2.0.4') }
  let!(:another_package) { create(:npm_package) }
  let(:no_package_url) { "/projects/#{project.id}/packages/0" }
  let(:wrong_package_url) { "/projects/#{project.id}/packages/#{another_package.id}" }
  let(:params) { {} }

  describe 'GET /projects/:id/packages' do
    let(:url) { "/projects/#{project.id}/packages" }
    let(:package_schema) { 'public_api/v4/packages/packages' }

    subject { get api(url), params: params }

    context 'without the need for a license' do
      context 'project is public' do
        it_behaves_like 'returns packages', :project, :no_type
      end

      context 'with conan package' do
        let!(:conan_package) { create(:conan_package, project: project) }

        it 'uses the conan recipe as the package name' do
          subject

          response_conan_package = json_response.find { |package| package['id'] == conan_package.id }

          expect(response_conan_package['name']).to eq(conan_package.conan_recipe)
          expect(response_conan_package['conan_package_name']).to eq(conan_package.name)
        end
      end

      context 'with terraform module package' do
        let_it_be(:terraform_module_package) { create(:terraform_module_package, project: project) }

        context 'when no package_type filter is set' do
          let(:params) { {} }

          it 'filters out terraform module packages' do
            subject

            expect(json_response).not_to include(a_hash_including('package_type' => 'terraform_module'))
          end

          it 'returns packages with the package registry web_path' do
            subject

            expect(json_response).to include(a_hash_including('_links' => a_hash_including('web_path' => include('packages'))))
          end
        end

        context 'when package_type filter is set to terraform_module' do
          let(:params) { { package_type: :terraform_module } }

          it 'returns the terraform module package' do
            subject

            expect(json_response).to include(a_hash_including('package_type' => 'terraform_module'))
          end

          it 'returns the terraform module package with the infrastructure registry web_path' do
            subject

            expect(json_response).to include(a_hash_including('_links' => a_hash_including('web_path' => include('infrastructure_registry'))))
          end
        end

        context 'in nested group' do
          let_it_be(:nested_project) { create(:project, :public, :in_subgroup) }
          let_it_be(:nested_terraform_module_package) { create(:terraform_module_package, project: nested_project) }

          let(:params) { { package_type: :terraform_module } }
          let(:url) { "/projects/#{nested_project.id}/packages" }

          it 'returns the nested terraform module package with the correct web_path' do
            subject

            expect(json_response).to include(a_hash_including('_links' => a_hash_including('web_path' => include(nested_project.namespace.full_path))))
          end
        end
      end

      context 'project is private' do
        let(:project) { create(:project, :private) }

        context 'for unauthenticated user' do
          it_behaves_like 'rejects packages access', :project, :no_type, :not_found
        end

        context 'for authenticated user' do
          subject { get api(url, user) }

          it_behaves_like 'returns packages', :project, :maintainer
          it_behaves_like 'returns packages', :project, :developer
          it_behaves_like 'returns packages', :project, :reporter
          it_behaves_like 'rejects packages access', :project, :no_type, :not_found
          it_behaves_like 'rejects packages access', :project, :guest, :forbidden

          context 'user is a maintainer' do
            before do
              project.add_maintainer(user)
            end

            it 'returns the destroy url' do
              subject

              expect(json_response.first['_links']).to include('delete_api_path')
            end
          end
        end
      end

      context 'with pagination params' do
        let!(:package3) { create(:maven_package, project: project) }
        let!(:package4) { create(:maven_package, project: project) }

        context 'with pagination params' do
          let!(:package3) { create(:npm_package, project: project) }
          let!(:package4) { create(:npm_package, project: project) }

          it_behaves_like 'returns paginated packages'
        end
      end

      context 'with sorting' do
        let(:package3) { create(:maven_package, project: project, version: '1.1.1', name: 'zzz') }

        before do
          travel_to(1.day.ago) do
            package3
          end
        end

        it_behaves_like 'package sorting', 'name' do
          let(:packages) { [package1, package2, package3] }
        end

        it_behaves_like 'package sorting', 'created_at' do
          let(:packages) { [package3, package1, package2] }
        end

        it_behaves_like 'package sorting', 'version' do
          let(:packages) { [package3, package2, package1] }
        end

        it_behaves_like 'package sorting', 'type' do
          let(:packages) { [package3, package1, package2] }
        end
      end

      it_behaves_like 'filters on each package_type', is_project: true

      context 'filtering on package_name' do
        include_context 'package filter context'

        it 'returns the named package' do
          url = package_filter_url(:name, 'nuget')
          get api(url, user)

          expect(json_response.length).to eq(1)
          expect(json_response.first['name']).to include(package2.name)
        end
      end

      it_behaves_like 'with versionless packages'
      it_behaves_like 'with status param'
      it_behaves_like 'does not cause n^2 queries'
    end
  end

  describe 'GET /projects/:id/packages/:package_id' do
    subject { get api(package_url, user) }

    shared_examples 'no destroy url' do
      it 'returns no destroy url' do
        subject

        expect(json_response['_links']).not_to include('delete_api_path')
      end
    end

    shared_examples 'destroy url' do
      it 'returns destroy url' do
        subject

        expect(json_response['_links']['delete_api_path']).to be_present
      end
    end

    context 'without the need for a license' do
      context 'with build info' do
        it 'does not result in additional queries' do
          control = ActiveRecord::QueryRecorder.new do
            get api(package_url, user)
          end

          pipeline = create(:ci_pipeline, user: user)
          create(:ci_build, user: user, pipeline: pipeline)
          create(:package_build_info, package: package1, pipeline: pipeline)

          expect do
            get api(package_url, user)
          end.not_to exceed_query_limit(control)
        end
      end

      context 'project is public' do
        it 'returns 200 and the package information' do
          subject

          expect(response).to have_gitlab_http_status(:ok)
          expect(response).to match_response_schema('public_api/v4/packages/package')
        end

        it 'returns 404 when the package does not exist' do
          get api(no_package_url, user)

          expect(response).to have_gitlab_http_status(:not_found)
        end

        it 'returns 404 for the package from a different project' do
          get api(wrong_package_url, user)

          expect(response).to have_gitlab_http_status(:not_found)
        end

        it_behaves_like 'no destroy url'
      end

      context 'project is private' do
        let(:project) { create(:project, :private) }

        it 'returns 404 for non authenticated user' do
          get api(package_url)

          expect(response).to have_gitlab_http_status(:not_found)
        end

        it 'returns 404 for a user without access to the project' do
          subject

          expect(response).to have_gitlab_http_status(:not_found)
        end

        context 'user is a developer' do
          before do
            project.add_developer(user)
          end

          it 'returns 200 and the package information' do
            subject

            expect(response).to have_gitlab_http_status(:ok)
            expect(response).to match_response_schema('public_api/v4/packages/package')
          end

          it_behaves_like 'no destroy url'
        end

        context 'user is a maintainer' do
          before do
            project.add_maintainer(user)
          end

          it_behaves_like 'destroy url'
        end

        context 'with pipeline' do
          let!(:package1) { create(:npm_package, :with_build, project: project) }

          it 'returns the pipeline info' do
            project.add_developer(user)

            get api(package_url, user)

            expect(response).to have_gitlab_http_status(:ok)
            expect(response).to match_response_schema('public_api/v4/packages/package_with_build')
          end
        end
      end
    end
  end

  describe 'DELETE /projects/:id/packages/:package_id' do
    context 'without the need for a license' do
      context 'project is public' do
        it 'returns 403 for non authenticated user' do
          delete api(package_url)

          expect(response).to have_gitlab_http_status(:forbidden)
        end

        it 'returns 403 for a user without access to the project' do
          delete api(package_url, user)

          expect(response).to have_gitlab_http_status(:forbidden)
        end
      end

      context 'project is private' do
        let(:project) { create(:project, :private) }

        before do
          expect(::Packages::Maven::Metadata::SyncWorker).not_to receive(:perform_async)
        end

        it 'returns 404 for non authenticated user' do
          delete api(package_url)

          expect(response).to have_gitlab_http_status(:not_found)
        end

        it 'returns 404 for a user without access to the project' do
          delete api(package_url, user)

          expect(response).to have_gitlab_http_status(:not_found)
        end

        it 'returns 404 when the package does not exist' do
          project.add_maintainer(user)

          delete api(no_package_url, user)

          expect(response).to have_gitlab_http_status(:not_found)
        end

        it 'returns 404 for the package from a different project' do
          project.add_maintainer(user)

          delete api(wrong_package_url, user)

          expect(response).to have_gitlab_http_status(:not_found)
        end

        it 'returns 403 for a user without enough permissions' do
          project.add_developer(user)

          delete api(package_url, user)

          expect(response).to have_gitlab_http_status(:forbidden)
        end

        it 'returns 204' do
          project.add_maintainer(user)

          delete api(package_url, user)

          expect(response).to have_gitlab_http_status(:no_content)
        end
      end

      context 'with a maven package' do
        let_it_be(:package1) { create(:maven_package, project: project) }

        it 'enqueues a sync worker job' do
          project.add_maintainer(user)

          expect(::Packages::Maven::Metadata::SyncWorker)
            .to receive(:perform_async).with(user.id, project.id, package1.name)

          delete api(package_url, user)
        end
      end
    end
  end
end
