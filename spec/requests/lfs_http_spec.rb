# frozen_string_literal: true
require 'spec_helper'

RSpec.describe 'Git LFS API and storage' do
  include LfsHttpHelpers
  include ProjectForksHelper
  include WorkhorseHelpers

  let_it_be(:project, reload: true) { create(:project, :empty_repo) }
  let_it_be(:user) { create(:user) }

  context 'with projects' do
    it_behaves_like 'LFS http requests' do
      let_it_be(:other_project, reload: true) { create(:project, :empty_repo) }

      let(:container) { project }
      let(:authorize_guest) { project.add_guest(user) }
      let(:authorize_download) { project.add_reporter(user) }
      let(:authorize_upload) { project.add_developer(user) }

      context 'project specific LFS settings' do
        let(:body) { upload_body(sample_object) }

        before do
          authorize_upload
          project.update_attribute(:lfs_enabled, project_lfs_enabled)

          subject
        end

        describe 'LFS disabled in project' do
          let(:project_lfs_enabled) { false }

          context 'when uploading' do
            subject(:request) { post_lfs_json(batch_url(project), body, headers) }

            it_behaves_like 'LFS http 404 response'
          end

          context 'when downloading' do
            subject(:request) { get(objects_url(project, sample_oid), params: {}, headers: headers) }

            it_behaves_like 'LFS http 404 response'
          end
        end

        describe 'LFS enabled in project' do
          let(:project_lfs_enabled) { true }

          context 'when uploading' do
            subject(:request) { post_lfs_json(batch_url(project), body, headers) }

            it_behaves_like 'LFS http 200 response'
          end

          context 'when downloading' do
            subject(:request) { get(objects_url(project, sample_oid), params: {}, headers: headers) }

            it_behaves_like 'LFS http 200 blob response'
          end
        end
      end

      describe 'when fetching LFS object' do
        subject(:request) { get objects_url(project, sample_oid), params: {}, headers: headers }

        let(:response) { request && super() }

        before do
          project.lfs_objects << lfs_object
        end

        context 'when LFS uses object storage' do
          before do
            authorize_download
          end

          context 'when proxy download is enabled' do
            before do
              stub_lfs_object_storage(proxy_download: true)
              lfs_object.file.migrate!(LfsObjectUploader::Store::REMOTE)
            end

            it 'responds with the workhorse send-url' do
              expect(response).to have_gitlab_http_status(:ok)
              expect(response.headers[Gitlab::Workhorse::SEND_DATA_HEADER]).to start_with("send-url:")
            end
          end

          context 'when proxy download is disabled' do
            before do
              stub_lfs_object_storage(proxy_download: false)
              lfs_object.file.migrate!(LfsObjectUploader::Store::REMOTE)
            end

            it 'responds with redirect' do
              expect(response).to have_gitlab_http_status(:found)
            end

            it 'responds with the file location' do
              expect(response.location).to include(lfs_object.reload.file.path)
            end
          end
        end

        context 'when deploy key is authorized' do
          let_it_be(:key) { create(:deploy_key) }

          let(:authorization) { authorize_deploy_key }

          before do
            project.deploy_keys << key
          end

          it_behaves_like 'LFS http 200 blob response'
        end

        context 'when using a user key (LFSToken)' do
          let(:authorization) { authorize_user_key }

          context 'when user allowed' do
            before do
              authorize_download
            end

            it_behaves_like 'LFS http 200 blob response'

            context 'when user password is expired' do
              let_it_be(:user) { create(:user, password_expires_at: 1.minute.ago, password_automatically_set: true)}

              it_behaves_like 'LFS http 401 response'
            end

            context 'when user is blocked' do
              let_it_be(:user) { create(:user, :blocked)}

              it_behaves_like 'LFS http 401 response'
            end
          end

          context 'when user not allowed' do
            it_behaves_like 'LFS http 404 response'
          end
        end

        context 'when build is authorized as' do
          let(:authorization) { authorize_ci_project }
          let(:pipeline) { create(:ci_empty_pipeline, project: project) }
          let(:build) { create(:ci_build, :running, pipeline: pipeline, user: user) }

          shared_examples 'can download LFS only from own projects' do
            context 'for owned project' do
              let_it_be(:project) { create(:project, namespace: user.namespace) }

              it_behaves_like 'LFS http 200 blob response'
            end

            context 'for member of project' do
              before do
                authorize_download
              end

              it_behaves_like 'LFS http 200 blob response'
            end

            context 'for other project' do
              let(:pipeline) { create(:ci_empty_pipeline, project: other_project) }

              it 'rejects downloading code' do
                expect(response).to have_gitlab_http_status(:not_found)
              end
            end
          end

          context 'administrator', :enable_admin_mode do
            let_it_be(:user) { create(:admin) }

            it_behaves_like 'can download LFS only from own projects'
          end

          context 'regular user' do
            it_behaves_like 'can download LFS only from own projects'
          end

          context 'does not have user' do
            let(:build) { create(:ci_build, :running, pipeline: pipeline) }

            it_behaves_like 'can download LFS only from own projects'
          end
        end
      end

      describe 'when handling LFS batch request' do
        subject(:request) { post_lfs_json batch_url(project), body, headers }

        let(:response) { request && super() }

        before do
          project.lfs_objects << lfs_object
        end

        shared_examples 'process authorization header' do |renew_authorization:|
          let(:response_authorization) do
            authorization_in_action(lfs_actions.first)
          end

          if renew_authorization
            context 'when the authorization comes from a user' do
              it 'returns a new valid LFS token authorization' do
                expect(response_authorization).not_to eq(authorization)
              end

              it 'returns a valid token' do
                username, token = ::Base64.decode64(response_authorization.split(' ', 2).last).split(':', 2)

                expect(username).to eq(user.username)
                expect(Gitlab::LfsToken.new(user).token_valid?(token)).to be_truthy
              end

              it 'generates only one new token per each request' do
                authorizations = lfs_actions.map do |action|
                  authorization_in_action(action)
                end.compact

                expect(authorizations.uniq.count).to eq 1
              end
            end
          else
            context 'when the authorization comes from a token' do
              it 'returns the same authorization header' do
                expect(response_authorization).to eq(authorization)
              end
            end
          end

          def lfs_actions
            json_response['objects'].map { |a| a['actions'] }.compact
          end

          def authorization_in_action(action)
            (action['upload'] || action['download']).dig('header', 'Authorization')
          end
        end

        describe 'download' do
          let(:body) { download_body(sample_object) }

          shared_examples 'an authorized request' do |renew_authorization:|
            context 'when downloading an LFS object that is assigned to our project' do
              it_behaves_like 'LFS http 200 response'

              it 'with href to download' do
                expect(json_response['objects'].first).to include(sample_object)
                expect(json_response['objects'].first['actions']['download']['href']).to eq(objects_url(project, sample_oid))
              end

              it_behaves_like 'process authorization header', renew_authorization: renew_authorization
            end

            context 'when downloading an LFS object that is assigned to other project' do
              before do
                lfs_object.update!(projects: [other_project])
              end

              it_behaves_like 'LFS http 200 response'

              it 'with an 404 for specific object' do
                expect(json_response['objects'].first).to include(sample_object)
                expect(json_response['objects'].first['error']).to include('code' => 404, 'message' => "Object does not exist on the server or you don't have permissions to access it")
              end
            end

            context 'when downloading a LFS object that does not exist' do
              let(:body) { download_body(non_existing_object) }

              it_behaves_like 'LFS http 200 response'

              it 'with an 404 for specific object' do
                expect(json_response['objects'].first).to include(non_existing_object)
                expect(json_response['objects'].first['error']).to include('code' => 404, 'message' => "Object does not exist on the server or you don't have permissions to access it")
              end
            end

            context 'when downloading one existing and one missing LFS object' do
              let(:body) { download_body(multiple_objects) }

              it_behaves_like 'LFS http 200 response'

              it 'responds with download hypermedia link for the existing object' do
                expect(json_response['objects'].first).to include(sample_object)
                expect(json_response['objects'].first['actions']['download']).to include('href' => objects_url(project, sample_oid))
                expect(json_response['objects'].last).to eq({
                  'oid' => non_existing_object_oid,
                  'size' => non_existing_object_size,
                  'error' => {
                    'code' => 404,
                    'message' => "Object does not exist on the server or you don't have permissions to access it"
                  }
                })
              end

              it_behaves_like 'process authorization header', renew_authorization: renew_authorization
            end

            context 'when downloading two existing LFS objects' do
              let(:body) { download_body(multiple_objects) }
              let(:other_object) { create(:lfs_object, :with_file, oid: non_existing_object_oid, size: non_existing_object_size) }

              before do
                project.lfs_objects << other_object
              end

              it 'responds with the download hypermedia link for each object' do
                expect(json_response['objects'].first).to include(sample_object)
                expect(json_response['objects'].first['actions']['download']).to include('href' => objects_url(project, sample_oid))

                expect(json_response['objects'].last).to include(non_existing_object)
                expect(json_response['objects'].last['actions']['download']).to include('href' => objects_url(project, non_existing_object_oid))
              end

              it_behaves_like 'process authorization header', renew_authorization: renew_authorization
            end
          end

          context 'when user is authenticated' do
            before do
              project.add_role(user, role) if role
            end

            it_behaves_like 'an authorized request', renew_authorization: true do
              let(:role) { :reporter }
            end

            context 'when user is not a member of the project' do
              let(:role) { nil }

              it_behaves_like 'LFS http 404 response'
            end

            context 'when user does not have download access' do
              let(:role) { :guest }

              it_behaves_like 'LFS http 404 response'
            end

            context 'when user password is expired' do
              let_it_be(:user) { create(:user, password_expires_at: 1.minute.ago, password_automatically_set: true)}

              let(:role) { :reporter}

              it_behaves_like 'LFS http 401 response'
            end

            context 'when user is blocked' do
              let_it_be(:user) { create(:user, :blocked)}

              let(:role) { :reporter}

              it_behaves_like 'LFS http 401 response'
            end
          end

          context 'when using Deploy Tokens' do
            let(:authorization) { authorize_deploy_token }

            context 'when Deploy Token is not valid' do
              let(:deploy_token) { create(:deploy_token, projects: [project], read_repository: false) }

              it_behaves_like 'LFS http 401 response'
            end

            context 'when Deploy Token is not related to the project' do
              let(:deploy_token) { create(:deploy_token, projects: [other_project]) }

              it_behaves_like 'LFS http 401 response'
            end

            # TODO: We should fix this test case that causes flakyness by alternating the result of the above test cases.
            context 'when Deploy Token is valid' do
              let(:deploy_token) { create(:deploy_token, projects: [project]) }

              it_behaves_like 'an authorized request', renew_authorization: false
            end
          end

          context 'when build is authorized as' do
            let(:authorization) { authorize_ci_project }

            shared_examples 'can download LFS only from own projects' do |renew_authorization:|
              context 'for own project' do
                let(:pipeline) { create(:ci_empty_pipeline, project: project) }

                before do
                  authorize_download
                end

                it_behaves_like 'an authorized request', renew_authorization: renew_authorization
              end

              context 'for other project' do
                let(:pipeline) { create(:ci_empty_pipeline, project: other_project) }

                it 'rejects downloading code' do
                  expect(response).to have_gitlab_http_status(:not_found)
                end
              end
            end

            context 'administrator', :enable_admin_mode do
              let_it_be(:user) { create(:admin) }

              let(:build) { create(:ci_build, :running, pipeline: pipeline, user: user) }

              it_behaves_like 'can download LFS only from own projects', renew_authorization: true
            end

            context 'regular user' do
              let(:build) { create(:ci_build, :running, pipeline: pipeline, user: user) }

              it_behaves_like 'can download LFS only from own projects', renew_authorization: true
            end

            context 'does not have user' do
              let(:build) { create(:ci_build, :running, pipeline: pipeline) }

              it_behaves_like 'can download LFS only from own projects', renew_authorization: false
            end
          end

          context 'when user is not authenticated' do
            let(:authorization) { nil }

            describe 'is accessing public project' do
              let_it_be(:project) { create(:project, :public) }

              it_behaves_like 'LFS http 200 response'

              it 'returns href to download' do
                expect(json_response).to eq({
                  'objects' => [
                    {
                      'oid' => sample_oid,
                      'size' => sample_size,
                      'authenticated' => true,
                      'actions' => {
                        'download' => {
                          'href' => objects_url(project, sample_oid),
                          'header' => {}
                        }
                      }
                    }
                  ]
                })
              end
            end

            describe 'is accessing non-public project' do
              it_behaves_like 'LFS http 401 response'
            end
          end
        end

        describe 'upload' do
          let_it_be(:project) { create(:project, :public) }

          let(:body) { upload_body(sample_object) }

          shared_examples 'pushes new LFS objects' do |renew_authorization:|
            let(:sample_size) { 150.megabytes }
            let(:sample_oid) { non_existing_object_oid }

            it_behaves_like 'LFS http 200 response'

            it 'responds with upload hypermedia link' do
              expect(json_response['objects']).to be_kind_of(Array)
              expect(json_response['objects'].first).to include(sample_object)
              expect(json_response['objects'].first['actions']['upload']['href']).to eq(objects_url(project, sample_oid, sample_size))

              headers = json_response['objects'].first['actions']['upload']['header']
              expect(headers['Content-Type']).to eq('application/octet-stream')
              expect(headers['Transfer-Encoding']).to eq('chunked')
            end

            it_behaves_like 'process authorization header', renew_authorization: renew_authorization
          end

          describe 'when request is authenticated' do
            describe 'when user has project push access' do
              before do
                authorize_upload
              end

              context 'when pushing an LFS object that already exists' do
                shared_examples_for 'batch upload with existing LFS object' do
                  it_behaves_like 'LFS http 200 response'

                  it 'responds with links to the object in the project' do
                    expect(json_response['objects']).to be_kind_of(Array)
                    expect(json_response['objects'].first).to include(sample_object)
                    expect(lfs_object.projects.pluck(:id)).not_to include(project.id)
                    expect(lfs_object.projects.pluck(:id)).to include(other_project.id)
                    expect(json_response['objects'].first['actions']['upload']['href']).to eq(objects_url(project, sample_oid, sample_size))

                    headers = json_response['objects'].first['actions']['upload']['header']
                    expect(headers['Content-Type']).to eq('application/octet-stream')
                    expect(headers['Transfer-Encoding']).to eq('chunked')
                  end

                  it_behaves_like 'process authorization header', renew_authorization: true
                end

                context 'in another project' do
                  before do
                    lfs_object.update!(projects: [other_project])
                  end

                  it_behaves_like 'batch upload with existing LFS object'
                end

                context 'in source of fork project' do
                  let(:project) { fork_project(other_project) }

                  before do
                    lfs_object.update!(projects: [other_project])
                  end

                  it_behaves_like 'batch upload with existing LFS object'
                end
              end

              context 'when pushing a LFS object that does not exist' do
                it_behaves_like 'pushes new LFS objects', renew_authorization: true
              end

              context 'when pushing one new and one existing LFS object' do
                let(:body) { upload_body(multiple_objects) }

                it_behaves_like 'LFS http 200 response'

                it 'responds with upload hypermedia link for the new object' do
                  expect(json_response['objects']).to be_kind_of(Array)

                  expect(json_response['objects'].first).to include(sample_object)
                  expect(json_response['objects'].first).not_to have_key('actions')

                  expect(json_response['objects'].last).to include(non_existing_object)
                  expect(json_response['objects'].last['actions']['upload']['href']).to eq(objects_url(project, non_existing_object_oid, non_existing_object_size))

                  headers = json_response['objects'].last['actions']['upload']['header']
                  expect(headers['Content-Type']).to eq('application/octet-stream')
                  expect(headers['Transfer-Encoding']).to eq('chunked')
                end

                it_behaves_like 'process authorization header', renew_authorization: true
              end
            end

            context 'when user does not have push access' do
              it_behaves_like 'LFS http 403 response'
            end

            context 'when build is authorized' do
              let(:authorization) { authorize_ci_project }
              let(:pipeline) { create(:ci_empty_pipeline, project: project) }

              context 'build has an user' do
                let(:build) { create(:ci_build, :running, pipeline: pipeline, user: user) }

                context 'tries to push to own project' do
                  it_behaves_like 'LFS http 403 response'
                end

                context 'tries to push to other project' do
                  let(:pipeline) { create(:ci_empty_pipeline, project: other_project) }

                  # I'm not sure what this tests that is different from the previous test
                  it_behaves_like 'LFS http 403 response'
                end
              end

              context 'does not have user' do
                let(:build) { create(:ci_build, :running, pipeline: pipeline) }

                it_behaves_like 'LFS http 403 response'
              end
            end

            context 'when deploy key has project push access' do
              let(:key) { create(:deploy_key) }
              let(:authorization) { authorize_deploy_key }

              before do
                project.deploy_keys_projects.create!(deploy_key: key, can_push: true)
              end

              it_behaves_like 'pushes new LFS objects', renew_authorization: false
            end
          end

          context 'when user is not authenticated' do
            let(:authorization) { nil }

            context 'when user has push access' do
              before do
                authorize_upload
              end

              it_behaves_like 'LFS http 401 response'
            end

            context 'when user does not have push access' do
              it_behaves_like 'LFS http 401 response'
            end
          end
        end

        describe 'unsupported' do
          let(:body) { request_body('other', sample_object) }

          it_behaves_like 'LFS http 404 response'
        end
      end

      describe 'when handling LFS batch request on a read-only GitLab instance' do
        subject { post_lfs_json(batch_url(project), body, headers) }

        before do
          allow(Gitlab::Database).to receive(:read_only?) { true }

          project.add_maintainer(user)

          subject
        end

        context 'when downloading' do
          let(:body) { download_body(sample_object) }

          it_behaves_like 'LFS http 200 response'
        end

        context 'when uploading' do
          let(:body) { upload_body(sample_object) }

          it_behaves_like 'LFS http expected response code and message' do
            let(:response_code) { 403 }
            let(:message) { 'You cannot write to this read-only GitLab instance.' }
          end
        end
      end

      describe 'when pushing a LFS object' do
        let(:include_workhorse_jwt_header) { true }

        shared_examples 'unauthorized' do
          context 'and request is sent by gitlab-workhorse to authorize the request' do
            before do
              put_authorize
            end

            it_behaves_like 'LFS http 401 response'
          end

          context 'and request is sent by gitlab-workhorse to finalize the upload' do
            before do
              put_finalize
            end

            it_behaves_like 'LFS http 401 response'
          end

          context 'and request is sent with a malformed headers' do
            before do
              put_finalize('/etc/passwd')
            end

            it_behaves_like 'LFS http 401 response'
          end
        end

        shared_examples 'forbidden' do
          context 'and request is sent by gitlab-workhorse to authorize the request' do
            before do
              put_authorize
            end

            it_behaves_like 'LFS http 403 response'
          end

          context 'and request is sent by gitlab-workhorse to finalize the upload' do
            before do
              put_finalize
            end

            it_behaves_like 'LFS http 403 response'
          end

          context 'and request is sent with a malformed headers' do
            before do
              put_finalize('/etc/passwd')
            end

            it_behaves_like 'LFS http 403 response'
          end
        end

        describe 'to one project' do
          describe 'when user is authenticated' do
            describe 'when user has push access to the project' do
              before do
                project.add_developer(user)
              end

              context 'and the request bypassed workhorse' do
                it 'raises an exception' do
                  expect { put_authorize(verified: false) }.to raise_error JWT::DecodeError
                end
              end

              context 'and request is sent by gitlab-workhorse to authorize the request' do
                shared_examples 'a valid response' do
                  before do
                    put_authorize
                  end

                  it_behaves_like 'LFS http 200 workhorse response'
                end

                shared_examples 'a local file' do
                  it_behaves_like 'a valid response' do
                    it 'responds with status 200, location of LFS store and object details' do
                      expect(json_response['TempPath']).to eq(LfsObjectUploader.workhorse_local_upload_path)
                      expect(json_response['RemoteObject']).to be_nil
                      expect(json_response['LfsOid']).to eq(sample_oid)
                      expect(json_response['LfsSize']).to eq(sample_size)
                    end
                  end
                end

                context 'when using local storage' do
                  it_behaves_like 'a local file'
                end

                context 'when using remote storage' do
                  context 'when direct upload is enabled' do
                    before do
                      stub_lfs_object_storage(enabled: true, direct_upload: true)
                    end

                    it_behaves_like 'a valid response' do
                      it 'responds with status 200, location of LFS remote store and object details' do
                        expect(json_response).not_to have_key('TempPath')
                        expect(json_response['RemoteObject']).to have_key('ID')
                        expect(json_response['RemoteObject']).to have_key('GetURL')
                        expect(json_response['RemoteObject']).to have_key('StoreURL')
                        expect(json_response['RemoteObject']).to have_key('DeleteURL')
                        expect(json_response['RemoteObject']).to have_key('MultipartUpload')
                        expect(json_response['LfsOid']).to eq(sample_oid)
                        expect(json_response['LfsSize']).to eq(sample_size)
                      end
                    end
                  end

                  context 'when direct upload is disabled' do
                    before do
                      stub_lfs_object_storage(enabled: true, direct_upload: false)
                    end

                    it_behaves_like 'a local file'
                  end
                end
              end

              context 'and request is sent by gitlab-workhorse to finalize the upload' do
                before do
                  put_finalize
                end

                it_behaves_like 'LFS http 200 response'

                it 'LFS object is linked to the project' do
                  expect(lfs_object.projects.pluck(:id)).to include(project.id)
                end
              end

              context 'and request to finalize the upload is not sent by gitlab-workhorse' do
                it 'fails with a JWT decode error' do
                  expect { put_finalize(lfs_tmp_file, verified: false) }.to raise_error(JWT::DecodeError)
                end
              end

              context 'and workhorse requests upload finalize for a new LFS object' do
                before do
                  lfs_object.destroy!
                end

                context 'with object storage disabled' do
                  it "doesn't attempt to migrate file to object storage" do
                    expect(ObjectStorage::BackgroundMoveWorker).not_to receive(:perform_async)

                    put_finalize(with_tempfile: true)
                  end
                end

                context 'with object storage enabled' do
                  context 'and direct upload enabled' do
                    let!(:fog_connection) do
                      stub_lfs_object_storage(direct_upload: true)
                    end

                    let(:tmp_object) do
                      fog_connection.directories.new(key: 'lfs-objects').files.create( # rubocop: disable Rails/SaveBang
                        key: 'tmp/uploads/12312300',
                        body: 'content'
                      )
                    end

                    ['123123', '../../123123'].each do |remote_id|
                      context "with invalid remote_id: #{remote_id}" do
                        subject do
                          put_finalize(remote_object: tmp_object, args: {
                            'file.remote_id' => remote_id
                          })
                        end

                        it 'responds with status 403' do
                          subject

                          expect(response).to have_gitlab_http_status(:forbidden)
                        end
                      end
                    end

                    context 'with valid remote_id' do
                      subject do
                        put_finalize(remote_object: tmp_object, args: {
                          'file.remote_id' => '12312300',
                          'file.name' => 'name'
                        })
                      end

                      it 'responds with status 200' do
                        subject

                        expect(response).to have_gitlab_http_status(:ok)

                        object = LfsObject.find_by_oid(sample_oid)
                        expect(object).to be_present
                        expect(object.file.read).to eq(tmp_object.body)
                      end

                      it 'schedules migration of file to object storage' do
                        subject

                        expect(LfsObject.last.projects).to include(project)
                      end

                      it 'have valid file' do
                        subject

                        expect(LfsObject.last.file_store).to eq(ObjectStorage::Store::REMOTE)
                        expect(LfsObject.last.file).to be_exists
                      end
                    end
                  end

                  context 'and background upload enabled' do
                    before do
                      stub_lfs_object_storage(background_upload: true)
                    end

                    it 'schedules migration of file to object storage' do
                      expect(ObjectStorage::BackgroundMoveWorker).to receive(:perform_async).with('LfsObjectUploader', 'LfsObject', :file, kind_of(Numeric))

                      put_finalize(with_tempfile: true)
                    end
                  end
                end
              end

              context 'without the lfs object' do
                before do
                  lfs_object.destroy!
                end

                it 'rejects slashes in the tempfile name (path traversal)' do
                  put_finalize('../bar', with_tempfile: true)
                  expect(response).to have_gitlab_http_status(:bad_request)
                end

                context 'not sending the workhorse jwt header' do
                  let(:include_workhorse_jwt_header) { false }

                  it 'rejects the request' do
                    put_finalize(with_tempfile: true)

                    expect(response).to have_gitlab_http_status(:unprocessable_entity)
                  end
                end
              end
            end

            describe 'and user does not have push access' do
              before do
                project.add_reporter(user)
              end

              it_behaves_like 'forbidden'
            end
          end

          context 'when build is authorized' do
            let(:authorization) { authorize_ci_project }
            let(:pipeline) { create(:ci_empty_pipeline, project: project) }

            context 'build has an user' do
              let(:build) { create(:ci_build, :running, pipeline: pipeline, user: user) }

              context 'tries to push to own project' do
                before do
                  project.add_developer(user)
                  put_authorize
                end

                it_behaves_like 'LFS http 403 response'
              end

              context 'tries to push to other project' do
                let(:pipeline) { create(:ci_empty_pipeline, project: other_project) }

                before do
                  put_authorize
                end

                it_behaves_like 'LFS http 404 response'
              end
            end

            context 'does not have user' do
              let(:build) { create(:ci_build, :running, pipeline: pipeline) }

              before do
                put_authorize
              end

              it_behaves_like 'LFS http 403 response'
            end
          end

          describe 'when using a user key (LFSToken)' do
            let(:authorization) { authorize_user_key }

            context 'when user allowed' do
              before do
                project.add_developer(user)
                put_authorize
              end

              it_behaves_like 'LFS http 200 workhorse response'

              context 'when user password is expired' do
                let_it_be(:user) { create(:user, password_expires_at: 1.minute.ago, password_automatically_set: true) }

                it_behaves_like 'LFS http 401 response'
              end

              context 'when user is blocked' do
                let_it_be(:user) { create(:user, :blocked)}

                it_behaves_like 'LFS http 401 response'
              end
            end

            context 'when user not allowed' do
              before do
                put_authorize
              end

              it_behaves_like 'LFS http 404 response'
            end
          end

          context 'for unauthenticated' do
            let(:authorization) { nil }

            it_behaves_like 'unauthorized'
          end
        end

        describe 'to a forked project' do
          let_it_be(:upstream_project) { create(:project, :public) }
          let_it_be(:project_owner) { create(:user) }

          let(:project) { fork_project(upstream_project, project_owner) }

          describe 'when user is authenticated' do
            describe 'when user has push access to the project' do
              before do
                project.add_developer(user)
              end

              context 'and request is sent by gitlab-workhorse to authorize the request' do
                before do
                  put_authorize
                end

                it_behaves_like 'LFS http 200 workhorse response'

                it 'with location of LFS store and object details' do
                  expect(json_response['TempPath']).to eq(LfsObjectUploader.workhorse_local_upload_path)
                  expect(json_response['LfsOid']).to eq(sample_oid)
                  expect(json_response['LfsSize']).to eq(sample_size)
                end
              end

              context 'and request is sent by gitlab-workhorse to finalize the upload' do
                before do
                  put_finalize
                end

                it_behaves_like 'LFS http 200 response'

                it 'LFS object is linked to the forked project' do
                  expect(lfs_object.projects.pluck(:id)).to include(project.id)
                end
              end
            end

            describe 'and user does not have push access' do
              it_behaves_like 'forbidden'
            end
          end

          context 'when build is authorized' do
            let(:authorization) { authorize_ci_project }
            let(:pipeline) { create(:ci_empty_pipeline, project: project) }

            before do
              put_authorize
            end

            context 'build has an user' do
              let(:build) { create(:ci_build, :running, pipeline: pipeline, user: user) }

              context 'tries to push to own project' do
                it_behaves_like 'LFS http 403 response'
              end

              context 'tries to push to other project' do
                let(:pipeline) { create(:ci_empty_pipeline, project: other_project) }

                # I'm not sure what this tests that is different from the previous test
                it_behaves_like 'LFS http 403 response'
              end
            end

            context 'does not have user' do
              let(:build) { create(:ci_build, :running, pipeline: pipeline) }

              it_behaves_like 'LFS http 403 response'
            end
          end

          context 'for unauthenticated' do
            let(:authorization) { nil }

            it_behaves_like 'unauthorized'
          end

          describe 'and second project not related to fork or a source project' do
            let_it_be(:second_project) { create(:project) }

            before do
              second_project.add_maintainer(user)
              upstream_project.lfs_objects << lfs_object
            end

            context 'when pushing the same LFS object to the second project' do
              before do
                finalize_headers = headers
                  .merge('X-Gitlab-Lfs-Tmp' => lfs_tmp_file)
                  .merge(workhorse_internal_api_request_header)

                put objects_url(second_project, sample_oid, sample_size),
                  params: {},
                  headers: finalize_headers
              end

              it_behaves_like 'LFS http 200 response'

              it 'links the LFS object to the project' do
                expect(lfs_object.projects.pluck(:id)).to include(second_project.id, upstream_project.id)
              end
            end
          end
        end

        def put_authorize(verified: true)
          authorize_headers = headers
          authorize_headers.merge!(workhorse_internal_api_request_header) if verified

          put authorize_url(project, sample_oid, sample_size), params: {}, headers: authorize_headers
        end

        def put_finalize(lfs_tmp = lfs_tmp_file, with_tempfile: false, verified: true, remote_object: nil, args: {})
          uploaded_file = nil

          if with_tempfile
            upload_path = LfsObjectUploader.workhorse_local_upload_path
            file_path = upload_path + '/' + lfs_tmp if lfs_tmp

            FileUtils.mkdir_p(upload_path)
            FileUtils.touch(file_path)

            uploaded_file = UploadedFile.new(file_path, filename: File.basename(file_path))
          elsif remote_object
            uploaded_file = fog_to_uploaded_file(remote_object)
          end

          finalize_headers = headers
          finalize_headers.merge!(workhorse_internal_api_request_header) if verified

          workhorse_finalize(
            objects_url(project, sample_oid, sample_size),
            method: :put,
            file_key: :file,
            params: args.merge(file: uploaded_file),
            headers: finalize_headers,
            send_rewritten_field: include_workhorse_jwt_header
          )
        end

        def lfs_tmp_file
          "#{sample_oid}012345678"
        end
      end
    end
  end

  context 'with project wikis' do
    it_behaves_like 'LFS http requests' do
      let(:container) { create(:project_wiki, :empty_repo, project: project) }
      let(:authorize_guest) { project.add_guest(user) }
      let(:authorize_download) { project.add_reporter(user) }
      let(:authorize_upload) { project.add_developer(user) }
    end
  end

  context 'with snippets' do
    # LFS is not supported on snippets, so we override the shared examples
    # to expect 404 responses instead.
    [
      'LFS http 200 response',
      'LFS http 200 blob response',
      'LFS http 403 response'
    ].each do |examples|
      shared_examples_for(examples) { it_behaves_like 'LFS http 404 response' }
    end

    context 'with project snippets' do
      it_behaves_like 'LFS http requests' do
        let(:container) { create(:project_snippet, :empty_repo, project: project) }
        let(:authorize_guest) { project.add_guest(user) }
        let(:authorize_download) { project.add_reporter(user) }
        let(:authorize_upload) { project.add_developer(user) }
      end
    end

    context 'with personal snippets' do
      it_behaves_like 'LFS http requests' do
        let(:container) { create(:personal_snippet, :empty_repo) }
        let(:authorize_upload) { container.update!(author: user) }
      end
    end
  end
end
