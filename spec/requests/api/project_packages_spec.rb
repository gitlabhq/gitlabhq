# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::ProjectPackages, feature_category: :package_registry do
  using RSpec::Parameterized::TableSyntax

  let_it_be_with_reload(:project) { create(:project, :public) }

  let_it_be(:user) { create(:user) }
  let!(:package1) { create(:npm_package, :last_downloaded_at, project: project, version: '3.1.0', name: "@#{project.root_namespace.path}/foo1") }
  let(:package_url) { "/projects/#{project.id}/packages/#{package1.id}" }
  let!(:package2) { create(:nuget_package, project: project, version: '2.0.4') }
  let!(:another_package) { create(:npm_package) }
  let(:no_package_url) { "/projects/#{project.id}/packages/0" }
  let(:wrong_package_url) { "/projects/#{project.id}/packages/#{another_package.id}" }
  let(:params) { {} }

  describe 'GET /projects/:id/packages' do
    let(:url) { "/projects/#{project.id}/packages" }
    let(:package_schema) { 'public_api/v4/packages/packages' }

    subject(:request) { get api(url), params: params }

    it_behaves_like 'enforcing job token policies', :read_packages do
      let(:params) { { job_token: target_job.token } }
    end

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

          it 'returns the terraform module package with the terraform module registry web_path' do
            subject
            expect(json_response).to include(a_hash_including('_links' => a_hash_including('web_path' => include('terraform_module_registry'))))
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

        context 'with JOB-TOKEN auth' do
          let(:job) { create(:ci_build, :running, user: user, project: project) }

          subject { get api(url, job_token: job.token) }

          it_behaves_like 'returns packages', :project, :maintainer
          it_behaves_like 'returns packages', :project, :developer
          it_behaves_like 'returns packages', :project, :reporter
          it_behaves_like 'returns packages', :project, :no_type
          it_behaves_like 'returns packages', :project, :guest
        end
      end

      context 'project is private' do
        let_it_be(:project) { create(:project, :private) }

        context 'for unauthenticated user' do
          it_behaves_like 'rejects packages access', :project, :no_type, :not_found
        end

        context 'for authenticated user' do
          subject { get api(url, user) }

          it_behaves_like 'returns packages', :project, :maintainer
          it_behaves_like 'returns packages', :project, :developer
          it_behaves_like 'returns packages', :project, :reporter
          it_behaves_like 'rejects packages access', :project, :no_type, :not_found
          it_behaves_like 'returns packages', :project, :guest

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

        context 'with JOB-TOKEN auth' do
          let(:job) { create(:ci_build, :running, user: user, project: project) }

          subject { get api(url, job_token: job.token) }

          it_behaves_like 'returns packages', :project, :maintainer
          it_behaves_like 'returns packages', :project, :developer
          it_behaves_like 'returns packages', :project, :reporter
          it_behaves_like 'rejects packages access', :project, :no_type, :forbidden
          # TODO uncomment when https://gitlab.com/gitlab-org/gitlab/-/issues/370998 is resolved
          # it_behaves_like 'rejects packages access', :project, :guest, :not_found
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

      context 'filtering on package_version' do
        include_context 'package filter context'

        it 'returns the versioned package' do
          url = package_filter_url(:version, '2.0.4')
          get api(url, user)

          expect(json_response.length).to eq(1)
          expect(json_response.first['version']).to eq(package2.version)
        end

        it 'include_versionless has no effect' do
          url = "/projects/#{project.id}/packages?package_version=2.0.4&include_versionless=true"
          get api(url, user)

          expect(json_response.length).to eq(1)
          expect(json_response.first['version']).to eq(package2.version)
        end
      end

      it_behaves_like 'with versionless packages'
      it_behaves_like 'with status param'
      it_behaves_like 'does not cause n^2 queries'
    end
  end

  describe 'GET /projects/:id/packages/:package_id' do
    let(:single_package_schema) { 'public_api/v4/packages/package' }

    subject { get api(package_url, user) }

    it_behaves_like 'enforcing job token policies', :read_packages do
      let(:request) { get api(package_url), params: { job_token: target_job.token } }
    end

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
      context 'without build info' do
        it 'does not include the pipeline attributes' do
          subject

          expect(json_response).not_to include('pipeline', 'pipelines')
        end
      end

      context 'with build info' do
        let_it_be(:package1) { create(:npm_package, :with_build, project: project) }

        it 'returns an empty array for the pipelines attribute' do
          subject

          expect(json_response['pipelines']).to be_empty
        end
      end

      context 'project is public' do
        it 'returns 200 and the package information' do
          subject

          expect(response).to have_gitlab_http_status(:ok)
          expect(response).to match_response_schema(single_package_schema)
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

        context 'with JOB-TOKEN auth' do
          let(:job) { create(:ci_build, :running, user: user, project: project) }

          subject { get api(package_url, job_token: job.token) }

          it_behaves_like 'returns package', :project, :maintainer
          it_behaves_like 'returns package', :project, :developer
          it_behaves_like 'returns package', :project, :reporter
          it_behaves_like 'returns package', :project, :no_type
          it_behaves_like 'returns package', :project, :guest
        end

        context 'with a package without last_downloaded_at' do
          let(:package_url) { "/projects/#{project.id}/packages/#{package2.id}" }

          it 'returns 200 and the package information' do
            subject

            expect(response).to have_gitlab_http_status(:ok)
            expect(response).to match_response_schema(single_package_schema)
          end
        end
      end

      context 'project is private' do
        let_it_be(:project) { create(:project, :private) }

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
            expect(response).to match_response_schema(single_package_schema)
          end

          it_behaves_like 'no destroy url'
        end

        context 'user is a maintainer' do
          before do
            project.add_maintainer(user)
          end

          it_behaves_like 'destroy url'
        end

        context 'with JOB-TOKEN auth' do
          let(:job) { create(:ci_build, :running, user: user, project: project) }

          subject { get api(package_url, job_token: job.token) }

          it_behaves_like 'returns package', :project, :maintainer
          it_behaves_like 'returns package', :project, :developer
          it_behaves_like 'returns package', :project, :reporter
          # TODO uncomment when https://gitlab.com/gitlab-org/gitlab/-/issues/370998 is resolved
          # it_behaves_like 'rejects packages access', :project, :guest, :not_found
          it_behaves_like 'rejects packages access', :project, :no_type, :forbidden
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

    context 'when package has no default status' do
      let!(:package1) { create(:npm_package, :error, project: project) }

      it 'returns 404' do
        subject

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end

  describe 'GET /projects/:id/packages/:package_id/pipelines' do
    let(:package_pipelines_url) { "/projects/#{project.id}/packages/#{package1.id}/pipelines" }

    let(:tokens) do
      {
        personal_access_token: personal_access_token.token,
        job_token: job.token
      }
    end

    let_it_be(:personal_access_token) { create(:personal_access_token) }
    let_it_be(:user) { personal_access_token.user }
    let_it_be(:job) { create(:ci_build, :running, user: user, project: project) }
    let(:headers) { {} }

    subject { get api(package_pipelines_url) }

    shared_examples 'returns package pipelines' do |expected_status|
      it 'returns the first page of package pipelines' do
        subject

        expect(response).to have_gitlab_http_status(expected_status)
        expect(response).to match_response_schema('public_api/v4/packages/pipelines')
        expect(json_response.length).to eq(3)
        expect(json_response.pluck('id')).to eq(pipelines.reverse.map(&:id))
      end
    end

    it_behaves_like 'enforcing job token policies', :read_packages do
      let(:request) { get api(package_pipelines_url), params: { job_token: target_job.token } }
    end

    context 'without the need for a license' do
      context 'when the package does not exist' do
        let(:package_pipelines_url) { "/projects/#{project.id}/packages/0/pipelines" }

        it_behaves_like 'returning response status', :not_found
      end

      context 'when there are no pipelines for the package' do
        let(:package_pipelines_url) { "/projects/#{project.id}/packages/#{package2.id}/pipelines" }

        it 'returns an empty response' do
          subject

          expect(response).to have_gitlab_http_status(:success)
          expect(response).to match_response_schema('public_api/v4/packages/pipelines')
          expect(json_response.length).to eq(0)
        end
      end

      context 'with valid package and pipelines' do
        let!(:pipelines) do
          create_list(:ci_pipeline, 3, user: user, project: project).each do |pipeline|
            create(:package_build_info, package: package1, pipeline: pipeline)
          end
        end

        where(:visibility, :user_role, :member, :token_type, :valid_token, :shared_examples_name, :expected_status) do
          :public  | :developer  | true  | :personal_access_token | true  | 'returns package pipelines' | :success
          :public  | :guest      | true  | :personal_access_token | true  | 'returns package pipelines' | :success
          :public  | :developer  | true  | :personal_access_token | false | 'returning response status' | :unauthorized
          :public  | :guest      | true  | :personal_access_token | false | 'returning response status' | :unauthorized
          :public  | :developer  | false | :personal_access_token | true  | 'returns package pipelines' | :success
          :public  | :guest      | false | :personal_access_token | true  | 'returns package pipelines' | :success
          :public  | :developer  | false | :personal_access_token | false | 'returning response status' | :unauthorized
          :public  | :guest      | false | :personal_access_token | false | 'returning response status' | :unauthorized
          :public  | :anonymous  | false | nil                    | true  | 'returns package pipelines' | :success
          :private | :developer  | true  | :personal_access_token | true  | 'returns package pipelines' | :success
          :private | :guest      | true  | :personal_access_token | true  | 'returns package pipelines' | :success
          :private | :developer  | true  | :personal_access_token | false | 'returning response status' | :unauthorized
          :private | :guest      | true  | :personal_access_token | false | 'returning response status' | :unauthorized
          :private | :developer  | false | :personal_access_token | true  | 'returning response status' | :not_found
          :private | :guest      | false | :personal_access_token | true  | 'returning response status' | :not_found
          :private | :developer  | false | :personal_access_token | false | 'returning response status' | :unauthorized
          :private | :guest      | false | :personal_access_token | false | 'returning response status' | :unauthorized
          :private | :anonymous  | false | nil                    | true  | 'returning response status' | :not_found
          :public  | :developer  | true  | :job_token             | true  | 'returns package pipelines' | :success
          :public  | :guest      | true  | :job_token             | true  | 'returns package pipelines' | :success
          :public  | :developer  | true  | :job_token             | false | 'returning response status' | :unauthorized
          :public  | :guest      | true  | :job_token             | false | 'returning response status' | :unauthorized
          :public  | :developer  | false | :job_token             | true  | 'returns package pipelines' | :success
          :public  | :guest      | false | :job_token             | true  | 'returns package pipelines' | :success
          :public  | :developer  | false | :job_token             | false | 'returning response status' | :unauthorized
          :public  | :guest      | false | :job_token             | false | 'returning response status' | :unauthorized
          :private | :developer  | true  | :job_token             | true  | 'returns package pipelines' | :success
          # TODO uncomment the spec below when https://gitlab.com/gitlab-org/gitlab/-/issues/370998 is resolved
          # :private | :guest      | true  | :job_token             | true  | 'returning response status' | :forbidden
          :private | :developer  | true  | :job_token             | false | 'returning response status' | :unauthorized
          :private | :guest      | true  | :job_token             | false | 'returning response status' | :unauthorized
          :private | :developer  | false | :job_token             | true  | 'returning response status' | :forbidden
          :private | :guest      | false | :job_token             | true  | 'returning response status' | :forbidden
          :private | :developer  | false | :job_token             | false | 'returning response status' | :unauthorized
          :private | :guest      | false | :job_token             | false | 'returning response status' | :unauthorized
        end

        with_them do
          subject { get api(package_pipelines_url), headers: headers }

          let(:invalid_token) { 'invalid-token123' }
          let(:token) { valid_token ? tokens[token_type] : invalid_token }
          let(:headers) do
            case token_type
            when :personal_access_token
              { Gitlab::Auth::AuthFinders::PRIVATE_TOKEN_HEADER => token }
            when :job_token
              { Gitlab::Auth::AuthFinders::JOB_TOKEN_HEADER => token }
            when nil
              {}
            end
          end

          before do
            project.update!(visibility: visibility.to_s)
            project.send("add_#{user_role}", user) if member && user_role != :anonymous
          end

          it_behaves_like params[:shared_examples_name], params[:expected_status]
        end
      end

      context 'pagination' do
        shared_context 'setup pipeline records' do
          let!(:pipelines) do
            create_list(:package_build_info, 21, :with_pipeline, package: package1)
          end
        end

        shared_examples 'returns the default number of pipelines' do
          it do
            subject

            expect(json_response.size).to eq(20)
          end
        end

        shared_examples 'returns an error about the invalid per_page value' do
          it do
            subject

            expect(response).to have_gitlab_http_status(:bad_request)
            expect(json_response['error']).to match(/per_page does not have a valid value/)
          end
        end

        context 'without pagination params' do
          include_context 'setup pipeline records'

          it_behaves_like 'returns the default number of pipelines'
        end

        context 'with valid per_page value' do
          let(:per_page) { 11 }

          subject { get api(package_pipelines_url, user), params: { per_page: per_page } }

          include_context 'setup pipeline records'

          it 'returns the correct number of pipelines' do
            subject

            expect(json_response.size).to eq(per_page)
          end
        end

        context 'with invalid pagination params' do
          subject { get api(package_pipelines_url, user), params: { per_page: per_page } }

          context 'with non-positive per_page' do
            let(:per_page) { -2 }

            it_behaves_like 'returns an error about the invalid per_page value'
          end

          context 'with a too high value for per_page' do
            let(:per_page) { 21 }

            it_behaves_like 'returns an error about the invalid per_page value'
          end
        end

        context 'with valid pagination params' do
          let_it_be(:package1) { create(:npm_package, :last_downloaded_at, project: project) }
          let_it_be(:build_info1) { create(:package_build_info, :with_pipeline, package: package1) }
          let_it_be(:build_info2) { create(:package_build_info, :with_pipeline, package: package1) }
          let_it_be(:build_info3) { create(:package_build_info, :with_pipeline, package: package1) }

          let(:pipeline1) { build_info1.pipeline }
          let(:pipeline2) { build_info2.pipeline }
          let(:pipeline3) { build_info3.pipeline }

          let(:per_page) { 2 }

          it_behaves_like 'an endpoint with keyset pagination' do
            let(:first_record) { pipeline3 }
            let(:second_record) { pipeline2 }
            let(:api_call) { api(package_pipelines_url, user) }
          end

          context 'with no cursor supplied' do
            subject { get api(package_pipelines_url, user), params: { per_page: per_page } }

            it 'returns first 2 pipelines' do
              subject

              expect(json_response.pluck('id')).to contain_exactly(pipeline3.id, pipeline2.id)
            end
          end

          context 'with a cursor parameter' do
            let(:cursor) { Base64.urlsafe_encode64(Gitlab::Json.dump(cursor_attributes)) }

            subject { get api(package_pipelines_url, user), params: { per_page: per_page, cursor: cursor } }

            before do
              subject
            end

            context 'with a cursor for the next page' do
              let(:cursor_attributes) { { "id" => build_info2.id, "_kd" => "n" } }

              it 'returns the next page of records' do
                expect(json_response.pluck('id')).to contain_exactly(pipeline1.id)
              end
            end

            context 'with a cursor for the previous page' do
              let(:cursor_attributes) { { "id" => build_info1.id, "_kd" => "p" } }

              it 'returns the previous page of records' do
                expect(json_response.pluck('id')).to contain_exactly(pipeline3.id, pipeline2.id)
              end
            end
          end
        end
      end
    end
  end

  describe 'DELETE /projects/:id/packages/:package_id' do
    it_behaves_like 'enforcing job token policies', :admin_packages do
      before_all do
        project.add_maintainer(user)
      end

      let(:request) { delete api(package_url), params: { job_token: target_job.token } }
    end

    context 'without the need for a license' do
      context 'project is public' do
        it 'returns 403 for non authenticated user' do
          expect { delete api(package_url) }.not_to change { ::Packages::Package.pending_destruction.count }

          expect(response).to have_gitlab_http_status(:forbidden)
        end

        it 'returns 403 for a user without access to the project' do
          expect { delete api(package_url, user) }.not_to change { ::Packages::Package.pending_destruction.count }

          expect(response).to have_gitlab_http_status(:forbidden)
        end
      end

      context 'project is private' do
        let_it_be(:project) { create(:project, :private) }

        before do
          expect(::Packages::Maven::Metadata::SyncWorker).not_to receive(:perform_async)
        end

        it 'returns 404 for non authenticated user' do
          expect { delete api(package_url) }.not_to change { ::Packages::Package.pending_destruction.count }

          expect(response).to have_gitlab_http_status(:not_found)
        end

        it 'returns 404 for a user without access to the project' do
          expect { delete api(package_url, user) }.not_to change { ::Packages::Package.pending_destruction.count }

          expect(response).to have_gitlab_http_status(:not_found)
        end

        it 'returns 404 when the package does not exist' do
          project.add_maintainer(user)

          expect { delete api(no_package_url, user) }.not_to change { ::Packages::Package.pending_destruction.count }

          expect(response).to have_gitlab_http_status(:not_found)
        end

        it 'returns 404 for the package from a different project' do
          project.add_maintainer(user)

          expect { delete api(wrong_package_url, user) }.not_to change { ::Packages::Package.pending_destruction.count }

          expect(response).to have_gitlab_http_status(:not_found)
        end

        it 'returns 403 for a user without enough permissions' do
          project.add_developer(user)

          expect { delete api(package_url, user) }.not_to change { ::Packages::Package.pending_destruction.count }

          expect(response).to have_gitlab_http_status(:forbidden)
        end

        it 'returns 204' do
          project.add_maintainer(user)

          expect { delete api(package_url, user) }.to change { ::Packages::Package.pending_destruction.count }.by(1)

          expect(response).to have_gitlab_http_status(:no_content)
        end

        it_behaves_like 'enqueue a worker to sync a metadata cache' do
          let(:package_name) { package1.name }

          subject { delete api(package_url, user) }
        end

        context 'with JOB-TOKEN auth' do
          let(:job) { create(:ci_build, :running, user: user, project: project) }

          it 'returns 403 for a user without enough permissions' do
            project.add_developer(user)

            expect { delete api(package_url, job_token: job.token) }.not_to change { ::Packages::Package.pending_destruction.count }

            expect(response).to have_gitlab_http_status(:forbidden)
          end

          it 'returns 204' do
            project.add_maintainer(user)

            expect { delete api(package_url, job_token: job.token) }.to change { ::Packages::Package.pending_destruction.count }.by(1)

            expect(response).to have_gitlab_http_status(:no_content)
          end
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

        it_behaves_like 'does not enqueue a worker to sync a metadata cache' do
          before do
            project.add_maintainer(user)
          end

          subject { delete api(package_url, user) }
        end
      end
    end
  end
end
