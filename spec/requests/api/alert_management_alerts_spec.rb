# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::AlertManagementAlerts, feature_category: :incident_management do
  let_it_be(:creator) { create(:user) }
  let_it_be(:project) do
    create(:project, :public, creator_id: creator.id, namespace: creator.namespace)
  end

  let_it_be(:user) { create(:user) }
  let_it_be(:alert) { create(:alert_management_alert, project: project) }

  describe 'PUT /projects/:id/alert_management_alerts/:alert_iid/metric_images/authorize' do
    include_context 'workhorse headers'

    before do
      project.add_developer(user)
    end

    subject do
      post api("/projects/#{project.id}/alert_management_alerts/#{alert.iid}/metric_images/authorize", user),
        headers: workhorse_headers
    end

    it 'authorizes uploading with workhorse header' do
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
          stub_uploads_object_storage(MetricImageUploader, enabled: true, direct_upload: true)
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
          stub_uploads_object_storage(MetricImageUploader, enabled: true, direct_upload: false)
        end

        it 'handles as a local file' do
          subject

          expect(response).to have_gitlab_http_status(:ok)
          expect(response.media_type.to_s).to eq(Gitlab::Workhorse::INTERNAL_API_CONTENT_TYPE)
          expect(json_response['TempPath']).to eq(MetricImageUploader.workhorse_local_upload_path)
          expect(json_response['RemoteObject']).to be_nil
        end
      end
    end
  end

  describe 'POST /projects/:id/alert_management_alerts/:alert_iid/metric_images' do
    include WorkhorseHelpers
    using RSpec::Parameterized::TableSyntax

    include_context 'workhorse headers'

    let(:file) { fixture_file_upload('spec/fixtures/rails_sample.jpg', 'image/jpg') }
    let(:file_name) { 'rails_sample.jpg' }
    let(:url) { 'http://gitlab.com' }
    let(:url_text) { 'GitLab' }

    let(:params) { { url: url, url_text: url_text } }

    subject do
      workhorse_finalize(
        api("/projects/#{project.id}/alert_management_alerts/#{alert.iid}/metric_images", user),
        method: :post,
        file_key: :file,
        params: params.merge(file: file),
        headers: workhorse_headers,
        send_rewritten_field: true
      )
    end

    shared_examples 'can_upload_metric_image' do
      it 'creates a new metric image' do
        subject

        expect(response).to have_gitlab_http_status(:created)
        expect(json_response['filename']).to eq(file_name)
        expect(json_response['url']).to eq(url)
        expect(json_response['url_text']).to eq(url_text)
        expect(json_response['created_at']).not_to be_nil
        expect(json_response['id']).not_to be_nil
        file_path_regex = %r{/uploads/-/system/alert_management_metric_image/file/\d+/#{file_name}}
        expect(json_response['file_path']).to match(file_path_regex)
      end
    end

    shared_examples 'unauthorized_upload' do
      it 'disallows the upload' do
        subject

        expect(response).to have_gitlab_http_status(:forbidden)
        expect(json_response['message']).to eq('403 Forbidden')
      end
    end

    where(:user_role, :expected_status) do
      :guest     | :unauthorized_upload
      :reporter  | :unauthorized_upload
      :developer | :can_upload_metric_image
    end

    with_them do
      before do
        # Local storage
        stub_uploads_object_storage(MetricImageUploader, enabled: false)
        allow_next_instance_of(MetricImageUploader) do |uploader|
          allow(uploader).to receive(:file_storage?).and_return(true)
        end

        project.send("add_#{user_role}", user)
      end

      it_behaves_like params[:expected_status].to_s
    end

    context 'file size too large' do
      before do
        allow_next_instance_of(UploadedFile) do |upload_file|
          allow(upload_file).to receive(:size).and_return(AlertManagement::MetricImage::MAX_FILE_SIZE + 1)
        end
      end

      it 'returns an error' do
        subject

        expect(response).to have_gitlab_http_status(:bad_request)
        expect(response.body).to match(/File is too large/)
      end
    end

    context 'error when saving' do
      before do
        project.add_developer(user)

        allow_next_instance_of(::AlertManagement::MetricImages::UploadService) do |service|
          error = instance_double(ServiceResponse, success?: false, message: 'some error', http_status: :bad_request)
          allow(service).to receive(:execute).and_return(error)
        end
      end

      it 'returns an error' do
        subject

        expect(response).to have_gitlab_http_status(:bad_request)
        expect(response.body).to match(/some error/)
      end
    end

    context 'object storage enabled' do
      before do
        # Object storage
        stub_uploads_object_storage(MetricImageUploader)

        allow_next_instance_of(MetricImageUploader) do |uploader|
          allow(uploader).to receive(:file_storage?).and_return(true)
        end
        project.add_developer(user)
      end

      it_behaves_like 'can_upload_metric_image'

      it 'uploads to remote storage' do
        subject

        last_upload = AlertManagement::MetricImage.last.uploads.last
        expect(last_upload.store).to eq(::ObjectStorage::Store::REMOTE)
      end
    end
  end

  describe 'GET /projects/:id/alert_management_alerts/:alert_iid/metric_images' do
    using RSpec::Parameterized::TableSyntax

    let!(:image) { create(:alert_metric_image, alert: alert) }

    subject { get api("/projects/#{project.id}/alert_management_alerts/#{alert.iid}/metric_images", user) }

    shared_examples 'can_read_metric_image' do
      it 'can read the metric images' do
        subject

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response.first).to match(
          {
            id: image.id,
            created_at: image.created_at.strftime('%Y-%m-%dT%H:%M:%S.%LZ'),
            filename: image.filename,
            file_path: image.file_path,
            url: image.url,
            url_text: nil
          }.with_indifferent_access
        )
      end
    end

    shared_examples 'unauthorized_read' do
      it 'cannot read the metric images' do
        subject

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    where(:user_role, :public_project, :expected_status) do
      :not_member | false | :unauthorized_read
      :not_member | true  | :unauthorized_read
      :guest      | false | :unauthorized_read
      :reporter   | false | :unauthorized_read
      :developer  | false | :can_read_metric_image
    end

    with_them do
      before do
        project.send("add_#{user_role}", user) unless user_role == :not_member
        project.update!(visibility_level: Gitlab::VisibilityLevel::PRIVATE) unless public_project
      end

      it_behaves_like params[:expected_status].to_s
    end
  end

  describe 'PUT /projects/:id/alert_management_alerts/:alert_iid/metric_images/:metric_image_id' do
    using RSpec::Parameterized::TableSyntax

    let!(:image) { create(:alert_metric_image, alert: alert) }
    let(:params) { { url: 'http://test.example.com', url_text: 'Example website 123' } }

    subject do
      put api("/projects/#{project.id}/alert_management_alerts/#{alert.iid}/metric_images/#{image.id}", user),
        params: params
    end

    shared_examples 'can_update_metric_image' do
      it 'can update the metric images' do
        subject

        expect(response).to have_gitlab_http_status(:success)
        expect(json_response['url']).to eq(params[:url])
        expect(json_response['url_text']).to eq(params[:url_text])
      end
    end

    shared_examples 'unauthorized_update' do
      it 'cannot update the metric image' do
        subject

        expect(response).to have_gitlab_http_status(:forbidden)
        expect(image.reload).to eq(image)
      end
    end

    where(:user_role, :public_project, :expected_status) do
      :not_member | false | :unauthorized_update
      :not_member | true  | :unauthorized_update
      :guest      | false | :unauthorized_update
      :reporter   | false | :unauthorized_update
      :developer  | false | :can_update_metric_image
    end

    with_them do
      before do
        project.send("add_#{user_role}", user) unless user_role == :not_member
        project.update!(visibility_level: Gitlab::VisibilityLevel::PRIVATE) unless public_project
      end

      it_behaves_like params[:expected_status].to_s
    end

    context 'when user has access' do
      before do
        project.add_developer(user)
      end

      context 'and metric image not found' do
        subject do
          put api(
            "/projects/#{project.id}/alert_management_alerts/#{alert.iid}/metric_images/#{non_existing_record_id}", user
          )
        end

        it 'returns an error' do
          subject

          expect(response).to have_gitlab_http_status(:not_found)
          expect(json_response['message']).to eq('Metric image not found')
        end
      end

      context 'metric image cannot be updated' do
        let(:params) { { url_text: 'something_long' * 100 } }

        it 'returns an error' do
          subject

          expect(response).to have_gitlab_http_status(:unprocessable_entity)
          expect(json_response['message']).to eq('Metric image could not be updated')
        end
      end
    end
  end

  describe 'DELETE /projects/:id/alert_management_alerts/:alert_iid/metric_images/:metric_image_id' do
    using RSpec::Parameterized::TableSyntax

    let!(:image) { create(:alert_metric_image, alert: alert) }

    subject do
      delete api("/projects/#{project.id}/alert_management_alerts/#{alert.iid}/metric_images/#{image.id}", user)
    end

    shared_examples 'can delete metric image successfully' do
      it 'can delete the metric images' do
        subject

        expect(response).to have_gitlab_http_status(:no_content)
        expect { image.reload }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    shared_examples 'unauthorized delete' do
      it 'cannot delete the metric image' do
        subject

        expect(response).to have_gitlab_http_status(:forbidden)
        expect(image.reload).to eq(image)
      end
    end

    where(:user_role, :public_project, :expected_status) do
      :not_member | false | 'unauthorized delete'
      :not_member | true  | 'unauthorized delete'
      :guest      | false | 'unauthorized delete'
      :reporter   | false | 'unauthorized delete'
      :developer  | false | 'can delete metric image successfully'
    end

    with_them do
      before do
        project.send("add_#{user_role}", user) unless user_role == :not_member
        project.update!(visibility_level: Gitlab::VisibilityLevel::PRIVATE) unless public_project
      end

      it_behaves_like params[:expected_status].to_s
    end

    context 'when user has access' do
      before do
        project.add_developer(user)
      end

      context 'when metric image not found' do
        subject do
          delete api(
            "/projects/#{project.id}/alert_management_alerts/#{alert.iid}/metric_images/#{non_existing_record_id}", user
          )
        end

        it 'returns an error' do
          subject

          expect(response).to have_gitlab_http_status(:not_found)
          expect(json_response['message']).to eq('Metric image not found')
        end
      end

      context 'when error when deleting' do
        before do
          allow_next_instance_of(AlertManagement::AlertsFinder) do |finder|
            allow(finder).to receive(:execute).and_return([alert])
          end

          allow(alert).to receive_message_chain('metric_images.find_by_id') { image }
          allow(image).to receive(:destroy).and_return(false)
        end

        it 'returns an error' do
          subject

          expect(response).to have_gitlab_http_status(:unprocessable_entity)
          expect(json_response['message']).to eq('Metric image could not be deleted')
        end
      end
    end
  end
end
