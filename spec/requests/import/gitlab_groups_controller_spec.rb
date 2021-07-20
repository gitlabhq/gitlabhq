# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Import::GitlabGroupsController do
  include WorkhorseHelpers

  include_context 'workhorse headers'

  let_it_be(:user) { create(:user) }

  let(:import_path) { "#{Dir.tmpdir}/gitlab_groups_controller_spec" }

  before do
    allow_next_instance_of(Gitlab::ImportExport) do |import_export|
      expect(import_export).to receive(:storage_path).and_return(import_path)
    end

    allow(Gitlab::ApplicationRateLimiter).to receive(:throttled?).and_return(false)

    stub_uploads_object_storage(ImportExportUploader)
  end

  after do
    FileUtils.rm_rf(import_path, secure: true)
  end

  describe 'POST create' do
    subject(:import_request) { upload_archive(file_upload, workhorse_headers, request_params) }

    let(:file) { File.join('spec', %w[fixtures group_export.tar.gz]) }
    let(:file_upload) { fixture_file_upload(file) }

    before do
      login_as(user)
    end

    def upload_archive(file, headers = {}, params = {})
      workhorse_finalize(
        import_gitlab_group_path,
        method: :post,
        file_key: :file,
        params: params.merge(file: file),
        headers: headers,
        send_rewritten_field: true
      )
    end

    context 'when importing without a parent group' do
      let(:request_params) { { path: 'test-group-import', name: 'test-group-import' } }

      it 'successfully creates the group' do
        expect { import_request }.to change { Group.count }.by 1

        group = Group.find_by(name: 'test-group-import')

        expect(response).to have_gitlab_http_status(:found)
        expect(response).to redirect_to(group_path(group))
        expect(flash[:notice]).to include('is being imported')
      end

      it 'imports the group data', :sidekiq_inline do
        allow(GroupImportWorker).to receive(:perform_async).and_call_original

        import_request

        group = Group.find_by(name: 'test-group-import')

        expect(GroupImportWorker).to have_received(:perform_async).with(user.id, group.id)

        expect(group.description).to eq 'A voluptate non sequi temporibus quam at.'
        expect(group.visibility_level).to eq Gitlab::VisibilityLevel::PRIVATE
      end
    end

    context 'when importing to a parent group' do
      let(:request_params) { { path: 'test-group-import', name: 'test-group-import', parent_id: parent_group.id } }
      let(:parent_group) { create(:group) }

      before do
        parent_group.add_owner(user)
      end

      it 'creates a new group under the parent' do
        expect { import_request }
          .to change { parent_group.children.reload.size }.by 1

        expect(response).to have_gitlab_http_status(:found)
      end

      shared_examples 'is created with the parent visibility level' do |visibility_level|
        before do
          parent_group.update!(visibility_level: visibility_level)
        end

        it "imports a #{Gitlab::VisibilityLevel.level_name(visibility_level)} group" do
          import_request

          group = parent_group.children.find_by(name: 'test-group-import')
          expect(group.visibility_level).to eq visibility_level
        end
      end

      [
        Gitlab::VisibilityLevel::PUBLIC,
        Gitlab::VisibilityLevel::INTERNAL,
        Gitlab::VisibilityLevel::PRIVATE
      ].each do |visibility_level|
        context "when the parent is #{Gitlab::VisibilityLevel.level_name(visibility_level)}" do
          include_examples 'is created with the parent visibility level', visibility_level
        end
      end
    end

    context 'when supplied invalid params' do
      subject(:import_request) do
        upload_archive(
          file_upload,
          workhorse_headers,
          { path: '', name: '' }
        )
      end

      it 'responds with an error' do
        expect { import_request }.not_to change { Group.count }

        expect(flash[:alert])
          .to include('Group could not be imported', "Name can't be blank", 'Group URL is too short')
      end
    end

    context 'when the user is not authorized to create groups' do
      let(:request_params) { { path: 'test-group-import', name: 'test-group-import' } }
      let(:user) { create(:user, can_create_group: false) }

      it 'returns an error' do
        expect { import_request }.not_to change { Group.count }

        expect(flash[:alert]).to eq 'Group could not be imported: You don’t have permission to create groups.'
      end
    end

    context 'when the requests exceed the rate limit' do
      let(:request_params) { { path: 'test-group-import', name: 'test-group-import' } }

      before do
        allow(Gitlab::ApplicationRateLimiter).to receive(:throttled?).and_return(true)
      end

      it 'throttles the requests' do
        import_request

        expect(response).to have_gitlab_http_status(:found)
        expect(flash[:alert]).to eq 'This endpoint has been requested too many times. Try again later.'
      end
    end

    context 'when group import FF is disabled' do
      let(:request_params) { { path: 'test-group-import', name: 'test-group-import' } }

      before do
        stub_feature_flags(group_import_export: false)
      end

      it 'returns an error' do
        expect { import_request }.not_to change { Group.count }

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'when the parent group is invalid' do
      let(:request_params) { { path: 'test-group-import', name: 'test-group-import', parent_id: -1 } }

      it 'does not create a new group' do
        expect { import_request }.not_to change { Group.count }

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'when the user is not an owner of the parent group' do
      let(:request_params) { { path: 'test-group-import', name: 'test-group-import', parent_id: parent_group.id } }
      let(:parent_group) { create(:group) }

      it 'returns an error' do
        expect { import_request }.not_to change { parent_group.children.reload.count }

        expect(flash[:alert]).to include "You don’t have permission to create a subgroup in this group"
      end
    end
  end

  describe 'POST authorize' do
    it_behaves_like 'handle uploads authorize request' do
      let(:uploader_class) { ImportExportUploader }
      let(:maximum_size) { Gitlab::CurrentSettings.max_import_size.megabytes }

      subject { post authorize_import_gitlab_group_path, headers: workhorse_headers }
    end
  end
end
