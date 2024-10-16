# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Banzai::UploadsController, feature_category: :markdown do
  describe '#show' do
    let_it_be(:user) { create(:user) }

    let(:txt_upload) { fixture_file_upload('spec/fixtures/doc_sample.txt', 'text/plain') }
    let(:jpg_upload) { fixture_file_upload('spec/fixtures/rails_sample.jpg', 'image/jpg') }
    let(:secret) { FileUploader.generate_secret }

    context 'with project upload' do
      let_it_be(:project, reload: true) { create(:project, :private) }

      before_all do
        project.add_guest(user)
      end

      before do
        allow(FileUploader).to receive(:generate_secret).and_return(secret)
      end

      context 'with non-media uploads' do
        before do
          UploadService.new(project, txt_upload, FileUploader).execute
        end

        it 'returns 200 when user has access' do
          sign_in(user)

          get "/-/project/#{project.id}/uploads/#{secret}/doc_sample.txt"

          expect(response).to have_gitlab_http_status(:ok)
        end

        it 'returns 404 when user does not have access' do
          get "/-/project/#{project.id}/uploads/#{secret}/doc_sample.txt"

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end

      context 'with media uploads' do
        before do
          UploadService.new(project, jpg_upload, FileUploader).execute
        end

        context 'when enforce_auth_checks_on_uploads is disabled' do
          before do
            project.update!(enforce_auth_checks_on_uploads: false)
          end

          it 'returns 200 even when user has no access' do
            get "/-/project/#{project.id}/uploads/#{secret}/rails_sample.jpg"

            expect(response).to have_gitlab_http_status(:ok)
          end
        end

        context 'when enforce_auth_checks_on_uploads is enabled' do
          before do
            project.update!(enforce_auth_checks_on_uploads: true)
          end

          it 'returns 404 when user does not have access' do
            get "/-/project/#{project.id}/uploads/#{secret}/rails_sample.jpg"

            expect(response).to have_gitlab_http_status(:not_found)
          end
        end
      end
    end

    context 'with group upload' do
      let_it_be(:group) { create(:group, :private) }

      before_all do
        group.add_guest(user)
      end

      before do
        allow(NamespaceFileUploader).to receive(:generate_secret).and_return(secret)
      end

      context 'with non-media uploads' do
        before do
          UploadService.new(group, txt_upload, NamespaceFileUploader).execute
        end

        it 'returns 200 when user has access' do
          sign_in(user)

          get "/-/group/#{group.id}/uploads/#{secret}/doc_sample.txt"

          expect(response).to have_gitlab_http_status(:ok)
        end

        it 'returns 404 when user does not have access' do
          get "/-/group/#{group.id}/uploads/#{secret}/doc_sample.txt"

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end

      context 'with media uploads' do
        before do
          UploadService.new(group, jpg_upload, NamespaceFileUploader).execute
        end

        it 'returns 200 even when user has no access' do
          get "/-/group/#{group.id}/uploads/#{secret}/rails_sample.jpg"

          expect(response).to have_gitlab_http_status(:ok)
        end
      end
    end
  end
end
