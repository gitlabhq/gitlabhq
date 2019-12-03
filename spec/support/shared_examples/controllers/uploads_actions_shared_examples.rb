# frozen_string_literal: true

shared_examples 'handle uploads' do
  let(:user)  { create(:user) }
  let(:jpg)   { fixture_file_upload('spec/fixtures/rails_sample.jpg', 'image/jpg') }
  let(:txt)   { fixture_file_upload('spec/fixtures/doc_sample.txt', 'text/plain') }
  let(:secret) { FileUploader.generate_secret }
  let(:uploader_class) { FileUploader }

  it_behaves_like 'handle uploads authorize'

  describe "POST #create" do
    context 'when a user is not authorized to upload a file' do
      it 'returns 404 status' do
        post :create, params: params.merge(file: jpg), format: :json
        expect(response.status).to eq(404)
      end
    end

    context 'when a user can upload a file' do
      before do
        sign_in(user)
        model.add_developer(user)
      end

      context "without params['file']" do
        it "returns an error" do
          post :create, params: params, format: :json

          expect(response).to have_gitlab_http_status(422)
        end
      end

      context 'with valid image' do
        before do
          post :create, params: params.merge(file: jpg), format: :json
        end

        it 'returns a content with original filename, new link, and correct type.' do
          expect(response.body).to match '\"alt\":\"rails_sample\"'
          expect(response.body).to match "\"url\":\"/uploads"
        end

        # NOTE: This is as close as we're getting to an Integration test for this
        # behavior. We're avoiding a proper Feature test because those should be
        # testing things entirely user-facing, which the Upload model is very much
        # not.
        it 'creates a corresponding Upload record' do
          upload = Upload.last

          aggregate_failures do
            expect(upload).to exist
            expect(upload.model).to eq(model)
          end
        end
      end

      context 'with valid non-image file' do
        before do
          post :create, params: params.merge(file: txt), format: :json
        end

        it 'returns a content with original filename, new link, and correct type.' do
          expect(response.body).to match '\"alt\":\"doc_sample.txt\"'
          expect(response.body).to match "\"url\":\"/uploads"
        end
      end
    end
  end

  describe "GET #show" do
    let(:show_upload) do
      get :show, params: params.merge(secret: secret, filename: "rails_sample.jpg")
    end

    before do
      allow(FileUploader).to receive(:generate_secret).and_return(secret)
      UploadService.new(model, jpg, uploader_class).execute
    end

    context 'when accessing a specific upload via different model' do
      it 'responds with status 404' do
        params.merge!(other_params)

        show_upload

        expect(response).to have_gitlab_http_status(404)
      end
    end

    context 'when the upload does not have a MIME type that Rails knows' do
      let(:po) { fixture_file_upload('spec/fixtures/missing_metadata.po', 'text/plain') }

      it 'falls back to the null type' do
        UploadService.new(model, po, uploader_class).execute

        get :show, params: params.merge(secret: secret, filename: 'missing_metadata.po')

        expect(response.headers['Content-Type']).to eq('application/octet-stream')
      end
    end

    context "when the model is public" do
      before do
        model.update_attribute(:visibility_level, Gitlab::VisibilityLevel::PUBLIC)
      end

      context "when not signed in" do
        context "when the file exists" do
          it "responds with status 200" do
            show_upload

            expect(response).to have_gitlab_http_status(200)
          end
        end

        context "when neither the uploader nor the model exists" do
          before do
            allow_any_instance_of(Upload).to receive(:retrieve_uploader).and_return(nil)
            allow(controller).to receive(:find_model).and_return(nil)
          end

          it "responds with status 404" do
            show_upload

            expect(response).to have_gitlab_http_status(404)
          end
        end

        context "when the file doesn't exist" do
          before do
            allow_any_instance_of(FileUploader).to receive(:exists?).and_return(false)
          end

          it "responds with status 404" do
            show_upload

            expect(response).to have_gitlab_http_status(404)
          end
        end
      end

      context "when signed in" do
        before do
          sign_in(user)
        end

        context "when the file exists" do
          it "responds with status 200" do
            show_upload

            expect(response).to have_gitlab_http_status(200)
          end
        end

        context "when the file doesn't exist" do
          before do
            allow_any_instance_of(FileUploader).to receive(:exists?).and_return(false)
          end

          it "responds with status 404" do
            show_upload

            expect(response).to have_gitlab_http_status(404)
          end
        end
      end
    end

    context "when the model is private" do
      before do
        model.update_attribute(:visibility_level, Gitlab::VisibilityLevel::PRIVATE)
      end

      context "when not signed in" do
        context "when the file exists" do
          context "when the file is an image" do
            before do
              allow_any_instance_of(FileUploader).to receive(:image?).and_return(true)
            end

            it "responds with status 200" do
              show_upload

              expect(response).to have_gitlab_http_status(200)
            end
          end

          context "when the file is not an image" do
            before do
              allow_any_instance_of(FileUploader).to receive(:image?).and_return(false)
            end

            it "redirects to the sign in page" do
              show_upload

              expect(response).to redirect_to(new_user_session_path)
            end
          end
        end

        context "when the file doesn't exist" do
          before do
            allow_any_instance_of(FileUploader).to receive(:exists?).and_return(false)
          end

          it "redirects to the sign in page" do
            show_upload

            expect(response).to redirect_to(new_user_session_path)
          end
        end
      end

      context "when signed in" do
        before do
          sign_in(user)
        end

        context "when the user has access to the project" do
          before do
            model.add_developer(user)
          end

          context "when the file exists" do
            it "responds with status 200" do
              show_upload

              expect(response).to have_gitlab_http_status(200)
            end
          end

          context "when the file doesn't exist" do
            before do
              allow_any_instance_of(FileUploader).to receive(:exists?).and_return(false)
            end

            it "responds with status 404" do
              show_upload

              expect(response).to have_gitlab_http_status(404)
            end
          end
        end

        context "when the user doesn't have access to the model" do
          context "when the file exists" do
            context "when the file is an image" do
              before do
                allow_any_instance_of(FileUploader).to receive(:image?).and_return(true)
              end

              it "responds with status 200" do
                show_upload

                expect(response).to have_gitlab_http_status(200)
              end
            end

            context "when the file is not an image" do
              before do
                allow_any_instance_of(FileUploader).to receive(:image?).and_return(false)
              end

              it "responds with status 404" do
                show_upload

                expect(response).to have_gitlab_http_status(404)
              end
            end
          end

          context "when the file doesn't exist" do
            before do
              allow_any_instance_of(FileUploader).to receive(:exists?).and_return(false)
            end

            it "responds with status 404" do
              show_upload

              expect(response).to have_gitlab_http_status(404)
            end
          end
        end
      end
    end
  end
end

shared_examples 'handle uploads authorize' do
  describe "POST #authorize" do
    context 'when a user is not authorized to upload a file' do
      it 'returns 404 status' do
        post_authorize

        expect(response.status).to eq(404)
      end
    end

    context 'when a user can upload a file' do
      before do
        sign_in(user)

        if model.is_a?(PersonalSnippet)
          model.update!(author: user)
        else
          model.add_developer(user)
        end
      end

      context 'and the request bypassed workhorse' do
        it 'raises an exception' do
          expect { post_authorize(verified: false) }.to raise_error JWT::DecodeError
        end
      end

      context 'and request is sent by gitlab-workhorse to authorize the request' do
        shared_examples 'a valid response' do
          before do
            post_authorize
          end

          it 'responds with status 200' do
            expect(response).to have_gitlab_http_status(200)
          end

          it 'uses the gitlab-workhorse content type' do
            expect(response.headers["Content-Type"]).to eq(Gitlab::Workhorse::INTERNAL_API_CONTENT_TYPE)
          end
        end

        shared_examples 'a local file' do
          it_behaves_like 'a valid response' do
            it 'responds with status 200, location of uploads store and object details' do
              expect(json_response['TempPath']).to eq(uploader_class.workhorse_local_upload_path)
              expect(json_response['RemoteObject']).to be_nil
            end
          end
        end

        context 'when using local storage' do
          it_behaves_like 'a local file'
        end

        context 'when using remote storage' do
          context 'when direct upload is enabled' do
            before do
              stub_uploads_object_storage(uploader_class, direct_upload: true)
            end

            it_behaves_like 'a valid response' do
              it 'responds with status 200, location of uploads remote store and object details' do
                expect(json_response).not_to have_key('TempPath')
                expect(json_response['RemoteObject']).to have_key('ID')
                expect(json_response['RemoteObject']).to have_key('GetURL')
                expect(json_response['RemoteObject']).to have_key('StoreURL')
                expect(json_response['RemoteObject']).to have_key('DeleteURL')
                expect(json_response['RemoteObject']).to have_key('MultipartUpload')
              end
            end
          end

          context 'when direct upload is disabled' do
            before do
              stub_uploads_object_storage(uploader_class, direct_upload: false)
            end

            it_behaves_like 'a local file'
          end
        end
      end
    end
  end
end
