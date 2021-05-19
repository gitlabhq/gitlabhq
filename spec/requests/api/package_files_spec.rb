# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::PackageFiles do
  let(:user) { create(:user) }
  let(:project) { create(:project, :public) }
  let(:package) { create(:maven_package, project: project) }

  describe 'GET /projects/:id/packages/:package_id/package_files' do
    let(:url) { "/projects/#{project.id}/packages/#{package.id}/package_files" }

    before do
      project.add_developer(user)
    end

    context 'without the need for a license' do
      context 'project is public' do
        it 'returns 200' do
          get api(url)

          expect(response).to have_gitlab_http_status(:ok)
        end

        it 'returns 404 if package does not exist' do
          get api("/projects/#{project.id}/packages/0/package_files")

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end

      context 'project is private' do
        let(:project) { create(:project, :private) }

        it 'returns 404 for non authenticated user' do
          get api(url)

          expect(response).to have_gitlab_http_status(:not_found)
        end

        it 'returns 404 for a user without access to the project' do
          project.team.truncate

          get api(url, user)

          expect(response).to have_gitlab_http_status(:not_found)
        end

        it 'returns 200 and valid response schema' do
          get api(url, user)

          expect(response).to have_gitlab_http_status(:ok)
          expect(response).to match_response_schema('public_api/v4/packages/package_files')
        end
      end

      context 'with pagination params' do
        let(:per_page) { 2 }
        let!(:package_file_1) { package.package_files[0] }
        let!(:package_file_2) { package.package_files[1] }
        let!(:package_file_3) { package.package_files[2] }

        context 'when viewing the first page' do
          it 'returns first 2 packages' do
            get api(url, user), params: { page: 1, per_page: per_page }

            expect_paginated_array_response([package_file_1.id, package_file_2.id])
          end
        end

        context 'viewing the second page' do
          it 'returns the last package' do
            get api(url, user), params: { page: 2, per_page: per_page }

            expect_paginated_array_response([package_file_3.id])
          end
        end
      end
    end
  end

  describe 'DELETE /projects/:id/packages/:package_id/package_files/:package_file_id' do
    let(:package_file_id) { package.package_files.first.id }
    let(:url) { "/projects/#{project.id}/packages/#{package.id}/package_files/#{package_file_id}" }

    subject(:api_request) { delete api(url, user) }

    context 'project is public' do
      context 'without user' do
        let(:user) { nil }

        it 'returns 403 for non authenticated user', :aggregate_failures do
          expect { api_request }.not_to change { package.package_files.count }

          expect(response).to have_gitlab_http_status(:forbidden)
        end
      end

      it 'returns 403 for a user without access to the project', :aggregate_failures do
        expect { api_request }.not_to change { package.package_files.count }

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end

    context 'project is private' do
      let_it_be_with_refind(:project) { create(:project, :private) }

      it 'returns 404 for a user without access to the project', :aggregate_failures do
        expect { api_request }.not_to change { package.package_files.count }

        expect(response).to have_gitlab_http_status(:not_found)
      end

      it 'returns 403 for a user without enough permissions', :aggregate_failures do
        project.add_developer(user)

        expect { api_request }.not_to change { package.package_files.count }

        expect(response).to have_gitlab_http_status(:forbidden)
      end

      it 'returns 204', :aggregate_failures do
        project.add_maintainer(user)

        expect { api_request }.to change { package.package_files.count }.by(-1)

        expect(response).to have_gitlab_http_status(:no_content)
      end

      context 'without user' do
        let(:user) { nil }

        it 'returns 404 for non authenticated user', :aggregate_failures do
          expect { api_request }.not_to change { package.package_files.count }

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end

      context 'invalid file' do
        let(:url) { "/projects/#{project.id}/packages/#{package.id}/package_files/999999" }

        it 'returns 404 when the package file does not exist', :aggregate_failures do
          project.add_maintainer(user)

          expect { api_request }.not_to change { package.package_files.count }

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end
    end
  end
end
