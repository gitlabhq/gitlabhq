# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::MarkdownUploads, feature_category: :team_planning do
  let_it_be(:group) { create(:group, :private) }
  let_it_be(:group_maintainer) { create(:user, maintainer_of: group) }

  let_it_be(:project) { create(:project, :private) }
  let_it_be(:project_maintainer) { create(:user, maintainer_of: project) }

  let_it_be(:user) { create(:user, guest_of: [project, group]) }

  describe "POST /projects/:id/uploads/authorize" do
    include WorkhorseHelpers

    let(:headers) { workhorse_internal_api_request_header.merge({ 'HTTP_GITLAB_WORKHORSE' => 1 }) }
    let(:path) { "/projects/#{project.id}/uploads/authorize" }

    context 'with authorized user' do
      it "returns 200" do
        post api(path, user), headers: headers

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response['MaximumSize']).to eq(project.max_attachment_size)
      end
    end

    context 'with unauthorized user' do
      it "returns 404" do
        post api(path, create(:user)), headers: headers

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'with no Workhorse headers' do
      it "returns 403" do
        post api(path, user)

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end
  end

  describe "POST /projects/:id/uploads" do
    let(:file) { fixture_file_upload("spec/fixtures/dk.png", "image/png") }
    let(:path) { "/projects/#{project.id}/uploads" }

    before do
      project
    end

    it "uploads the file through the upload service and returns its info" do
      expect(UploadService).to receive(:new).with(project, anything, uploaded_by_user_id: user.id).and_call_original

      post api(path, user), params: { file: file }

      expect(response).to have_gitlab_http_status(:created)
      expect(json_response['id']).to eq(Upload.last.id)
      expect(json_response['alt']).to eq("dk")
      expect(json_response['url']).to start_with("/uploads/")
      expect(json_response['url']).to end_with("/dk.png")
      expect(json_response['full_path']).to start_with("/-/project/#{project.id}/uploads")
    end

    it "does not leave the temporary file in place after uploading, even when the tempfile reaper does not run" do
      tempfile = Tempfile.new('foo')
      path = tempfile.path

      # rubocop: disable RSpec/AnyInstanceOf -- allow_next_instance_of does not work here because TempfileReaper is a middleware that is initialized early
      allow_any_instance_of(Rack::TempfileReaper).to receive(:call) do |instance, env|
        instance.instance_variable_get(:@app).call(env)
      end
      # rubocop: enable RSpec/AnyInstanceOf

      expect(path).not_to be(nil)
      expect(Rack::Multipart::Parser::TEMPFILE_FACTORY).to receive(:call).and_return(tempfile)

      post api(path, user), params: { file: fixture_file_upload("spec/fixtures/dk.png", "image/png") }

      expect(tempfile.path).to be(nil)
      expect(File.exist?(path)).to be(false)
    end
  end

  shared_examples 'an unauthorized request' do
    it 'returns 403' do
      make_request

      expect(response).to have_gitlab_http_status(:forbidden)
    end
  end

  describe "GET /projects/:id/uploads" do
    let_it_be(:uploads) { create_list(:upload, 3, :issuable_upload, model: project) }
    let_it_be(:other_upload) { create(:upload, :issuable_upload, model: create(:project)) }

    let(:path) { "/projects/#{project.id}/uploads" }

    it 'returns uploads ordered by created_at' do
      get api(path, project_maintainer)

      expect_paginated_array_response(uploads.reverse.map(&:id))
    end

    it_behaves_like 'an unauthorized request' do
      subject(:make_request) { get api(path, user) }
    end
  end

  describe "GET /projects/:id/uploads/:upload_id" do
    let_it_be(:upload) { create(:upload, :issuable_upload, :with_file, model: project, filename: 'test.jpg') }

    let(:path) { "/projects/#{project.id}/uploads/#{upload.id}" }

    it 'returns the uploaded file' do
      get api(path, project_maintainer)

      expect(response).to have_gitlab_http_status(:ok)
      expect(response.headers['Content-Disposition'])
        .to eq(%(attachment; filename="test.jpg"; filename*=UTF-8''test.jpg))
    end

    context 'when the upload does not exist' do
      let(:path) { "/projects/#{project.id}/uploads/#{non_existing_record_id}" }

      it 'returns a 404' do
        get api(path, project_maintainer)

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    it_behaves_like 'an unauthorized request' do
      subject(:make_request) { get api(path, user) }
    end
  end

  describe "GET /projects/:id/uploads/:secret/:filename" do
    let_it_be(:upload) { create(:upload, :issuable_upload, :with_file, model: project, filename: 'test.jpg') }

    let(:path) { "/projects/#{project.id}/uploads/#{upload.secret}/#{upload.filename}" }

    it 'returns the uploaded file' do
      get api(path, project_maintainer)

      expect(response).to have_gitlab_http_status(:ok)
      expect(response.headers['Content-Disposition'])
        .to eq(%(attachment; filename="test.jpg"; filename*=UTF-8''test.jpg))
    end

    context 'when the secret does not match' do
      let(:path) { "/projects/#{project.id}/uploads/invalid_secret/#{upload.filename}" }

      it 'returns a 404' do
        get api(path, project_maintainer)

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'with a user that does not have access to the project' do
      it 'returns 404' do
        get api(path, create(:user))

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end

  describe "DELETE /projects/:id/uploads/:upload_id" do
    let_it_be(:upload) { create(:upload, :issuable_upload, model: project) }

    let(:path) { "/projects/#{project.id}/uploads/#{upload.id}" }

    it 'deletes the given upload' do
      expect do
        delete api(path, project_maintainer)
      end.to change { Upload.count }.by(-1)

      expect(response).to have_gitlab_http_status(:no_content)
    end

    it 'returns an error when deletion fails' do
      expect_next_instance_of(Banzai::UploadsFinder) do |finder|
        expect(finder).to receive(:find).with(upload.id).and_return(upload)
      end
      expect(upload).to receive(:destroy).and_return(false)

      delete api(path, project_maintainer)

      expect(response).to have_gitlab_http_status(:bad_request)
      expect(json_response['message']).to include(_('Upload could not be deleted.'))
    end

    it_behaves_like 'an unauthorized request' do
      subject(:make_request) { delete api(path, user) }
    end
  end

  describe "DELETE /projects/:id/uploads/:secret/:filename" do
    let_it_be(:upload) { create(:upload, :issuable_upload, model: project) }

    let(:path) { "/projects/#{project.id}/uploads/#{upload.secret}/#{upload.filename}" }

    it 'deletes the given upload' do
      expect do
        delete api(path, project_maintainer)
      end.to change { Upload.count }.by(-1)

      expect(response).to have_gitlab_http_status(:no_content)
    end

    it_behaves_like 'an unauthorized request' do
      subject(:make_request) { delete api(path, user) }
    end
  end

  describe "GET /groups/:id/uploads" do
    let_it_be(:uploads) { create_list(:upload, 3, :namespace_upload, model: group) }
    let_it_be(:other_upload) { create(:upload, :namespace_upload, model: create(:group)) }

    let(:path) { "/groups/#{group.id}/uploads" }

    it 'returns uploads ordered by created_at' do
      get api(path, group_maintainer)

      expect_paginated_array_response(uploads.reverse.map(&:id))
    end

    it_behaves_like 'an unauthorized request' do
      subject(:make_request) { get api(path, user) }
    end
  end

  describe "GET /groups/:id/uploads/:upload_id" do
    let_it_be(:upload) { create(:upload, :namespace_upload, :with_file, model: group, filename: 'test.jpg') }

    let(:path) { "/groups/#{group.id}/uploads/#{upload.id}" }

    it 'returns the uploaded file' do
      get api(path, group_maintainer)

      expect(response).to have_gitlab_http_status(:ok)
      expect(response.headers['Content-Disposition'])
        .to eq(%(attachment; filename="test.jpg"; filename*=UTF-8''test.jpg))
    end

    context 'when the upload does not exist' do
      let(:path) { "/groups/#{group.id}/uploads/#{non_existing_record_id}" }

      it 'returns a 404' do
        get api(path, group_maintainer)

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    it_behaves_like 'an unauthorized request' do
      subject(:make_request) { get api(path, user) }
    end
  end

  describe "GET /groups/:id/uploads/:secret/:filename" do
    let_it_be(:upload) { create(:upload, :namespace_upload, :with_file, model: group, filename: 'test.jpg') }

    let(:path) { "/groups/#{group.id}/uploads/#{upload.secret}/#{upload.filename}" }

    it 'returns the uploaded file' do
      get api(path, group_maintainer)

      expect(response).to have_gitlab_http_status(:ok)
      expect(response.headers['Content-Disposition'])
        .to eq(%(attachment; filename="test.jpg"; filename*=UTF-8''test.jpg))
    end

    context 'when the secret does not match' do
      let(:path) { "/groups/#{group.id}/uploads/invalid_secret/#{upload.filename}" }

      it 'returns a 404' do
        get api(path, group_maintainer)

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'with a user that does not have access to the group' do
      it 'returns 404' do
        get api(path, create(:user))

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end

  describe "DELETE /groups/:id/uploads/:upload_id" do
    let_it_be(:upload) { create(:upload, :namespace_upload, model: group) }

    let(:path) { "/groups/#{group.id}/uploads/#{upload.id}" }

    it 'deletes the given upload' do
      expect do
        delete api(path, group_maintainer)
      end.to change { Upload.count }.by(-1)

      expect(response).to have_gitlab_http_status(:no_content)
    end

    it 'returns an error when deletion fails' do
      expect_next_instance_of(Banzai::UploadsFinder) do |finder|
        expect(finder).to receive(:find).with(upload.id).and_return(upload)
      end
      expect(upload).to receive(:destroy).and_return(false)

      delete api(path, group_maintainer)

      expect(response).to have_gitlab_http_status(:bad_request)
      expect(json_response['message']).to include(_('Upload could not be deleted.'))
    end

    it_behaves_like 'an unauthorized request' do
      subject(:make_request) { delete api(path, user) }
    end
  end

  describe "DELETE /groups/:id/uploads/:secret/:filename" do
    let_it_be(:upload) { create(:upload, :namespace_upload, model: group) }

    let(:path) { "/groups/#{group.id}/uploads/#{upload.secret}/#{upload.filename}" }

    it 'deletes the given upload' do
      expect do
        delete api(path, group_maintainer)
      end.to change { Upload.count }.by(-1)

      expect(response).to have_gitlab_http_status(:no_content)
    end

    it_behaves_like 'an unauthorized request' do
      subject(:make_request) { delete api(path, user) }
    end
  end
end
