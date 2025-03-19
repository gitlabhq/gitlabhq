# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::PackageFiles, feature_category: :package_registry do
  let_it_be(:user) { create(:user) }
  let_it_be_with_reload(:project) { create(:project, :public) }
  let_it_be(:package) { create(:maven_package, project: project) }

  describe 'GET /projects/:id/packages/:package_id/package_files' do
    let(:url) { "/projects/#{project.id}/packages/#{package.id}/package_files" }

    shared_examples 'handling job token and returning' do |status:|
      it "returns status #{status}" do
        get api(url, job_token: job.token)

        expect(response).to have_gitlab_http_status(status)
        expect(response).to match_response_schema('public_api/v4/packages/package_files') if status == :ok
      end
    end

    before_all do
      project.add_developer(user)
    end

    it_behaves_like 'enforcing job token policies', :read_packages,
      allow_public_access_for_enabled_project_features: :package_registry do
      let(:request) { get api(url), params: { job_token: target_job.token } }
    end

    context 'without the need for a license' do
      context 'when project is public' do
        it 'returns 200' do
          get api(url)

          expect(response).to have_gitlab_http_status(:ok)
        end

        it 'returns 404 if package does not exist' do
          get api("/projects/#{project.id}/packages/0/package_files")

          expect(response).to have_gitlab_http_status(:not_found)
        end

        context 'with JOB-TOKEN auth' do
          let(:job) { create(:ci_build, :running, user: user, project: project) }

          it_behaves_like 'handling job token and returning', status: :ok
        end
      end

      context 'when project is private' do
        before_all do
          project.update!(visibility_level: ::Gitlab::VisibilityLevel::PRIVATE)
        end

        it 'returns 404 for non authenticated user' do
          get api(url)

          expect(response).to have_gitlab_http_status(:not_found)
        end

        it 'returns 404 for a user without access to the project', :sidekiq_inline do
          project.team.truncate

          get api(url, user)

          expect(response).to have_gitlab_http_status(:not_found)
        end

        it 'returns 200 and valid response schema' do
          get api(url, user)

          expect(response).to have_gitlab_http_status(:ok)
          expect(response).to match_response_schema('public_api/v4/packages/package_files')
        end

        context 'with JOB-TOKEN auth' do
          let(:job) { create(:ci_build, :running, user: user, project: project) }

          context 'when a non authenticated user' do
            let(:user) { nil }

            it_behaves_like 'handling job token and returning', status: :not_found
          end

          context 'when a user without access to the project', :sidekiq_inline do
            before do
              project.team.truncate
            end

            it_behaves_like 'handling job token and returning', status: :forbidden
          end

          context 'when a user with access to the project' do
            it_behaves_like 'handling job token and returning', status: :ok
          end
        end
      end

      context 'with pagination params' do
        let(:per_page) { 2 }
        let(:package_files) { package.package_files.order(:id) }
        let(:package_file_1) { package_files[0] }
        let(:package_file_2) { package_files[1] }
        let(:package_file_3) { package_files[2] }

        context 'when viewing the first page' do
          it 'returns first 2 packages' do
            get api(url, user), params: { page: 1, per_page: per_page }

            expect_paginated_array_response([package_file_1.id, package_file_2.id])
          end
        end

        context 'when viewing the second page' do
          it 'returns the last package' do
            get api(url, user), params: { page: 2, per_page: per_page }

            expect_paginated_array_response([package_file_3.id])
          end
        end
      end

      context 'with sorting params' do
        using RSpec::Parameterized::TableSyntax

        let_it_be(:package) { create(:generic_package, project:) }
        let_it_be(:file1) { create(:package_file, package: package, file_name: 'beta.txt', created_at: 2.days.ago) }
        let_it_be(:file2) { create(:package_file, package: package, file_name: 'alpha.txt', created_at: 1.day.ago) }
        let_it_be(:file3) { create(:package_file, package: package, file_name: 'gamma.txt', created_at: 3.days.ago) }

        where(:order_by, :sort, :expected_order) do
          'id'         | 'asc'  | ->(files) { [files[0].id, files[1].id, files[2].id] }
          'id'         | 'desc' | ->(files) { [files[2].id, files[1].id, files[0].id] }
          'file_name'  | 'asc'  | ->(files) { [files[1].id, files[0].id, files[2].id] } # alpha, beta, gamma
          'file_name'  | 'desc' | ->(files) { [files[2].id, files[0].id, files[1].id] } # gamma, beta, alpha
          'created_at' | 'asc'  | ->(files) { [files[2].id, files[0].id, files[1].id] } # oldest to newest
          'created_at' | 'desc' | ->(files) { [files[1].id, files[0].id, files[2].id] } # newest to oldest
        end

        with_them do
          it 'returns packages sorted by the specified order' do
            get api(url, user), params: { order_by: order_by, sort: sort }

            expect_paginated_array_response(expected_order.call([file1, file2, file3]))
          end
        end
      end

      context 'with package files pending destruction' do
        let!(:package_file_pending_destruction) { create(:package_file, :pending_destruction, package: package) }

        let(:package_file_ids) { json_response.pluck('id') }

        it 'does not return them' do
          get api(url, user)

          expect(package_file_ids).not_to include(package_file_pending_destruction.id)
        end
      end
    end
  end

  describe 'DELETE /projects/:id/packages/:package_id/package_files/:package_file_id' do
    let(:package_file_id) { package.package_files.first.id }
    let(:url) { "/projects/#{project.id}/packages/#{package.id}/package_files/#{package_file_id}" }

    subject(:api_request) { delete api(url, user) }

    shared_examples 'handling job token and returning' do |status:|
      it "returns status #{status}", :aggregate_failures do
        expect { api_request }.to change {
          package.package_files.pending_destruction.count
        }.by(status == :no_content ? 1 : 0)

        expect(response).to have_gitlab_http_status(status)
      end
    end

    it_behaves_like 'enforcing job token policies', :admin_packages do
      before do
        source_project.add_maintainer(user)
      end

      let(:request) { delete api(url), params: { job_token: target_job.token } }
    end

    context 'when project is public' do
      context 'without user' do
        let(:user) { nil }

        it 'returns 403 for non authenticated user', :aggregate_failures do
          expect { api_request }.not_to change { package.package_files.pending_destruction.count }

          expect(response).to have_gitlab_http_status(:forbidden)
        end
      end

      context 'with JOB-TOKEN auth' do
        subject(:api_request) { delete api(url, job_token: job.token) }

        let(:job) { create(:ci_build, :running, user: user, project: project) }

        it_behaves_like 'handling job token and returning', status: :forbidden
      end

      it 'returns 403 for a user without access to the project', :aggregate_failures do
        expect { api_request }.not_to change { package.package_files.pending_destruction.count }

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end

    context 'when project is private' do
      before_all do
        project.update!(visibility_level: ::Gitlab::VisibilityLevel::PRIVATE)
      end

      it 'returns 404 for a user without access to the project', :aggregate_failures do
        expect { api_request }.not_to change { package.package_files.pending_destruction.count }

        expect(response).to have_gitlab_http_status(:not_found)
      end

      it 'returns 403 for a user without enough permissions', :aggregate_failures do
        project.add_developer(user)

        expect { api_request }.not_to change { package.package_files.pending_destruction.count }

        expect(response).to have_gitlab_http_status(:forbidden)
      end

      it 'returns 204', :aggregate_failures do
        project.add_maintainer(user)

        expect { api_request }.to change { package.package_files.pending_destruction.count }.by(1)

        expect(response).to have_gitlab_http_status(:no_content)
      end

      context 'without user' do
        let(:user) { nil }

        it 'returns 404 for non authenticated user', :aggregate_failures do
          expect { api_request }.not_to change { package.package_files.pending_destruction.count }

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end

      context 'when invalid file' do
        let(:url) { "/projects/#{project.id}/packages/#{package.id}/package_files/999999" }

        it 'returns 404 when the package file does not exist', :aggregate_failures do
          project.add_maintainer(user)

          expect { api_request }.not_to change { package.package_files.pending_destruction.count }

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end

      context 'with package file pending destruction' do
        let!(:package_file_id) { create(:package_file, :pending_destruction, package: package).id }

        before_all do
          project.add_maintainer(user)
        end

        it 'can not be accessed', :aggregate_failures do
          expect { api_request }.not_to change { package.package_files.pending_destruction.count }

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end

      context 'with JOB-TOKEN auth' do
        subject(:api_request) { delete api(url, job_token: job.token) }

        let_it_be(:job) { create(:ci_build, :running, user: user, project: project) }

        context 'when a user without access to the project' do
          it_behaves_like 'handling job token and returning', status: :forbidden
        end

        context 'when a user without enough permissions' do
          before_all do
            project.add_developer(user)
          end

          it_behaves_like 'handling job token and returning', status: :forbidden
        end

        context 'when a user with the right permissions' do
          before_all do
            project.add_maintainer(user)
          end

          it_behaves_like 'handling job token and returning', status: :no_content
        end
      end
    end

    context 'with package protection rule for different roles and package_name_patterns', :enable_admin_mode do
      using RSpec::Parameterized::TableSyntax

      let_it_be(:pat_project_maintainer) do
        create(:personal_access_token, user: create(:user, maintainer_of: [project]))
      end

      let_it_be(:pat_project_owner) { create(:personal_access_token, user: create(:user, owner_of: [project])) }
      let_it_be(:pat_instance_admin) { create(:personal_access_token, :admin_mode, user: create(:admin)) }
      let_it_be(:headers_pat_project_maintainer) do
        { Gitlab::Auth::AuthFinders::PRIVATE_TOKEN_HEADER => pat_project_maintainer.token }
      end

      let_it_be(:headers_pat_project_owner) do
        { Gitlab::Auth::AuthFinders::PRIVATE_TOKEN_HEADER => pat_project_owner.token }
      end

      let_it_be(:headers_pat_instance_admin) do
        { Gitlab::Auth::AuthFinders::PRIVATE_TOKEN_HEADER => pat_instance_admin.token }
      end

      let_it_be(:job_from_project_maintainer) do
        create(:ci_build, :running, user: pat_project_maintainer.user, project: project)
      end

      let_it_be(:job_from_project_owner) { create(:ci_build, :running, user: pat_project_owner.user, project: project) }
      let(:headers_job_token_from_maintainer) do
        { Gitlab::Auth::AuthFinders::JOB_TOKEN_HEADER => job_from_project_maintainer.token }
      end

      let(:headers_job_token_from_owner) do
        { Gitlab::Auth::AuthFinders::JOB_TOKEN_HEADER => job_from_project_owner.token }
      end

      let(:package_protection_rule) { create(:package_protection_rule, project: project) }

      let(:package_name) { package.name }
      let(:package_name_no_match) { "#{package_name}_no_match" }

      subject do
        delete api(url), headers: headers
        response
      end

      shared_examples 'deleting package protected' do
        it_behaves_like 'returning response status', :forbidden
        it 'responds with correct error message' do
          subject

          expect(json_response).to include('message' => "403 Forbidden - Package is deletion protected.")
        end

        it { expect { subject }.not_to change { ::Packages::Package.pending_destruction.count } }

        context 'when feature flag :packages_protected_packages_delete disabled' do
          before do
            stub_feature_flags(packages_protected_packages_delete: false)
          end

          it_behaves_like 'deleting package'
        end
      end

      shared_examples 'deleting package' do
        it_behaves_like 'returning response status', :no_content
        it { expect { subject }.to change { package.package_files.pending_destruction.count }.by(1) }
      end

      where(:package_name_pattern, :minimum_access_level_for_delete, :headers, :shared_examples_name) do
        ref(:package_name)          | :owner | ref(:headers_job_token_from_maintainer) | 'deleting package protected'
        ref(:package_name)          | :owner | ref(:headers_job_token_from_owner)      | 'deleting package'
        ref(:package_name)          | :owner | ref(:headers_pat_project_maintainer)    | 'deleting package protected'
        ref(:package_name)          | :owner | ref(:headers_pat_project_owner)         | 'deleting package'
        ref(:package_name)          | :owner | ref(:headers_pat_instance_admin)        | 'deleting package'

        ref(:package_name)          | :admin | ref(:headers_pat_project_maintainer)    | 'deleting package protected'
        ref(:package_name)          | :admin | ref(:headers_pat_project_owner)         | 'deleting package protected'
        ref(:package_name)          | :admin | ref(:headers_job_token_from_owner)      | 'deleting package protected'
        ref(:package_name)          | :admin | ref(:headers_pat_instance_admin)        | 'deleting package'

        ref(:package_name_no_match) | :owner | ref(:headers_pat_project_owner)         | 'deleting package'
      end

      with_them do
        before do
          package_protection_rule.update!(
            package_name_pattern: package_name_pattern,
            package_type: package.package_type,
            minimum_access_level_for_delete: minimum_access_level_for_delete
          )
        end

        it_behaves_like params[:shared_examples_name]
      end

      context 'for package with unsupported package type for package protection rule' do
        let_it_be(:nuget_package) { create(:nuget_package, project: project) }

        let(:package) { nuget_package }
        let(:package_file_id) { nuget_package.package_files.first.id }

        let(:headers) { headers_pat_project_maintainer }

        it_behaves_like 'deleting package'
      end
    end
  end
end
