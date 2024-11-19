# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::GroupImport, :with_current_organization, feature_category: :importers do
  include WorkhorseHelpers

  include_context 'workhorse headers'

  let_it_be(:user) { create(:user, organizations: [current_organization]) }
  let_it_be(:group) { create(:group, organization: current_organization) }

  let(:path) { '/groups/import' }
  let(:file) { File.join('spec', 'fixtures', 'group_export.tar.gz') }
  let(:export_path) { "#{Dir.tmpdir}/group_export_spec" }

  before do
    allow_next_instance_of(Gitlab::ImportExport) do |import_export|
      expect(import_export).to receive(:storage_path).and_return(export_path)
    end

    stub_uploads_object_storage(ImportExportUploader)
  end

  after do
    FileUtils.rm_rf(export_path, secure: true)
  end

  describe 'POST /groups/import' do
    let(:file_upload) { fixture_file_upload(file) }
    let(:base_params) do
      {
        path: 'test-import-group',
        name: 'test-import-group',
        file: fixture_file_upload(file)
      }
    end

    let(:params) { base_params }

    subject { upload_archive(file_upload, workhorse_headers, params) }

    shared_examples 'when all params are correct' do
      context 'when user is authorized to create new group' do
        it 'creates new group and accepts request' do
          subject

          expect(response).to have_gitlab_http_status(:accepted)
        end

        it 'creates private group' do
          expect { subject }.to change { Group.count }.by(1)

          group = Group.find_by(name: 'test-import-group')

          expect(group.visibility_level).to eq(Gitlab::VisibilityLevel::PRIVATE)
        end

        context 'when importing to a parent group' do
          before do
            group.add_owner(user)
          end

          it 'creates new group and accepts request' do
            params[:parent_id] = group.id

            subject

            expect(response).to have_gitlab_http_status(:accepted)
            expect(group.children.count).to eq(1)
          end

          context 'when parent group is private or internal' do
            let(:public_parent_group) { create(:group, :public, organization: current_organization) }
            let(:internal_parent_group) { create(:group, :internal, organization: current_organization) }

            before do
              public_parent_group.add_owner(user)
              internal_parent_group.add_owner(user)
            end

            it 'imports public group' do
              params[:parent_id] = public_parent_group.id

              subject

              expect(response).to have_gitlab_http_status(:accepted)
              expect(public_parent_group.children.first.visibility_level).to eq(Gitlab::VisibilityLevel::PUBLIC)
            end

            it 'imports internal group' do
              params[:parent_id] = internal_parent_group.id

              subject

              expect(response).to have_gitlab_http_status(:accepted)
              expect(internal_parent_group.children.first.visibility_level).to eq(Gitlab::VisibilityLevel::INTERNAL)
            end
          end

          context 'when parent group is invalid' do
            it 'returns 404 and does not create new group' do
              params[:parent_id] = non_existing_record_id

              expect { subject }.not_to change { Group.count }

              expect(response).to have_gitlab_http_status(:not_found)
              expect(json_response['message']).to eq('404 Group Not Found')
            end

            context 'when user is not an owner of parent group' do
              it 'returns 403 Forbidden HTTP status' do
                params[:parent_id] = create(:group, organization: current_organization).id

                subject

                expect(response).to have_gitlab_http_status(:forbidden)
                expect(json_response['message']).to eq('403 Forbidden')
              end
            end
          end
        end

        context 'when group creation failed' do
          before do
            allow_next_instance_of(Group) do |group|
              allow(group).to receive(:persisted?).and_return(false)
              allow(group).to receive(:save).and_return(false)
            end
          end

          it 'returns 400 HTTP status' do
            subject

            expect(response).to have_gitlab_http_status(:bad_request)
          end
        end
      end

      context 'when user is not authorized to create new group' do
        let(:user) { create(:user, can_create_group: false) }

        it 'forbids the request' do
          subject

          expect(response).to have_gitlab_http_status(:forbidden)
        end
      end
    end

    shared_examples 'when some params are missing' do
      context 'when required params are missing' do
        shared_examples 'missing parameter' do |params, error_message|
          it 'returns 400 HTTP status' do
            params[:file] = file_upload

            expect do
              upload_archive(file_upload, workhorse_headers, params)
            end.not_to change { Group.count }.from(1)

            expect(response).to have_gitlab_http_status(:bad_request)
            expect(json_response['error']).to eq(error_message)
          end
        end

        include_examples 'missing parameter', { name: 'test' }, 'path is missing'
        include_examples 'missing parameter', { path: 'test' }, 'name is missing'
      end
    end

    context 'with object storage disabled' do
      before do
        stub_uploads_object_storage(ImportExportUploader, enabled: false)
      end

      context 'without a file from workhorse' do
        it 'rejects the request' do
          upload_archive(nil, workhorse_headers, params)

          expect(response).to have_gitlab_http_status(:bad_request)
        end
      end

      context 'without a workhorse header' do
        it 'rejects request without a workhorse header' do
          upload_archive(file_upload, {}, params)

          expect(response).to have_gitlab_http_status(:forbidden)
        end
      end

      context 'when params from workhorse are correct' do
        let(:params) do
          {
            path: 'test-import-group',
            name: 'test-import-group'
          }
        end

        include_examples 'when all params are correct'
        include_examples 'when some params are missing'
      end
    end

    context 'with object storage enabled' do
      before do
        stub_uploads_object_storage(ImportExportUploader, enabled: true)

        allow(ImportExportUploader).to receive(:workhorse_upload_path).and_return('/')
      end

      context 'with direct upload enabled' do
        let(:file_name) { 'group_export.tar.gz' }
        let!(:fog_connection) do
          stub_uploads_object_storage(ImportExportUploader, direct_upload: true)
        end

        # rubocop:disable Rails/SaveBang
        let(:tmp_object) do
          fog_connection.directories.new(key: 'uploads').files.create(
            key: "tmp/uploads/#{file_name}",
            body: file_upload
          )
        end
        # rubocop:enable Rails/SaveBang

        let(:fog_file) { fog_to_uploaded_file(tmp_object) }
        let(:params) do
          {
            path: 'test-import-group',
            name: 'test-import-group',
            file: fog_file
          }
        end

        it 'accepts the request and stores the file' do
          expect { subject }.to change { Group.count }.by(1)

          expect(response).to have_gitlab_http_status(:accepted)
        end

        include_examples 'when all params are correct'
        include_examples 'when some params are missing'
      end
    end

    context 'when organization_id is missing' do
      context 'and current organization is defined' do
        it 'assigns current organization' do
          subject

          expect(Group.last.organization_id).to eq(current_organization.id)
        end

        context 'when importing to a parent group' do
          let_it_be(:group) { create(:group, organization: current_organization) }

          before do
            group.add_owner(user)
          end

          it 'creates new group and accepts request' do
            params[:parent_id] = group.id

            subject

            expect(response).to have_gitlab_http_status(:accepted)
            expect(group.children.count).to eq(1)
          end
        end
      end
    end

    context 'when organization_id param is different than parent group organization' do
      let!(:other_organization) { create(:organization, name: 'different organization', users: [user]) }
      let(:params) { base_params.merge(organization_id: other_organization.id) }

      before do
        group.add_owner(user)
      end

      it 'rejects the request' do
        params[:parent_id] = group.id

        subject

        error_message = "You can't create a group in a different organization than the parent group."
        expect(response).to have_gitlab_http_status(:bad_request)
        expect(json_response["message"]).to include(error_message)
      end
    end

    def upload_archive(file, headers = {}, params = {})
      workhorse_finalize(
        api('/groups/import', user),
        method: :post,
        file_key: :file,
        params: params.merge(file: file),
        headers: headers,
        send_rewritten_field: true
      )
    end
  end

  describe 'POST /groups/import/authorize' do
    subject { post api('/groups/import/authorize', user), headers: workhorse_headers }

    it 'authorizes importing group with workhorse header' do
      subject

      expect(response).to have_gitlab_http_status(:ok)
      expect(response.media_type.to_s).to eq(Gitlab::Workhorse::INTERNAL_API_CONTENT_TYPE)
    end

    it 'rejects requests that bypassed gitlab-workhorse' do
      workhorse_headers.delete(Gitlab::Workhorse::INTERNAL_API_REQUEST_HEADER)

      subject

      expect(response).to have_gitlab_http_status(:forbidden)
    end

    context 'when using remote storage' do
      context 'when direct upload is enabled' do
        before do
          stub_uploads_object_storage(ImportExportUploader, enabled: true, direct_upload: true)
        end

        it 'responds with status 200, location of file remote store and object details' do
          subject

          expect(response).to have_gitlab_http_status(:ok)
          expect(response.media_type.to_s).to eq(Gitlab::Workhorse::INTERNAL_API_CONTENT_TYPE)
          expect(json_response).not_to have_key('TempPath')
          expect(json_response['RemoteObject']).to have_key('ID')
          expect(json_response['RemoteObject']).to have_key('GetURL')
          expect(json_response['RemoteObject']).to have_key('StoreURL')
          expect(json_response['RemoteObject']).to have_key('DeleteURL')
          expect(json_response['RemoteObject']).to have_key('MultipartUpload')
        end
      end

      context 'when direct upload is disabled' do
        before do
          stub_uploads_object_storage(ImportExportUploader, enabled: true, direct_upload: false)
        end

        it 'handles as a local file' do
          subject

          expect(response).to have_gitlab_http_status(:ok)
          expect(response.media_type.to_s).to eq(Gitlab::Workhorse::INTERNAL_API_CONTENT_TYPE)
          expect(json_response['TempPath']).to eq(ImportExportUploader.workhorse_local_upload_path)
          expect(json_response['RemoteObject']).to be_nil
        end
      end
    end
  end
end
