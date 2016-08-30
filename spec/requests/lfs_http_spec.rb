require 'spec_helper'

describe 'Git LFS API and storage' do
  let(:user) { create(:user) }
  let!(:lfs_object) { create(:lfs_object, :with_file) }

  let(:headers) do
    {
      'Authorization' => authorization,
      'X-Sendfile-Type' => sendfile
    }.compact
  end
  let(:authorization) { }
  let(:sendfile) { }

  let(:sample_oid) { lfs_object.oid }
  let(:sample_size) { lfs_object.size }

  describe 'when lfs is disabled' do
    let(:project) { create(:empty_project) }
    let(:body) do
      {
        'objects' => [
          { 'oid' => '91eff75a492a3ed0dfcb544d7f31326bc4014c8551849c192fd1e48d4dd2c897',
            'size' => 1575078
          },
          { 'oid' => sample_oid,
            'size' => sample_size
          }
        ],
        'operation' => 'upload'
      }
    end
    let(:authorization) { authorize_user }

    before do
      allow(Gitlab.config.lfs).to receive(:enabled).and_return(false)
      post_lfs_json "#{project.http_url_to_repo}/info/lfs/objects/batch", body, headers
    end

    it 'responds with 501' do
      expect(response).to have_http_status(501)
      expect(json_response).to include('message' => 'Git LFS is not enabled on this GitLab server, contact your admin.')
    end
  end

  describe 'deprecated API' do
    let(:project) { create(:empty_project) }

    before do
      enable_lfs
    end

    shared_examples 'a deprecated' do
      it 'responds with 501' do
        expect(response).to have_http_status(501)
      end

      it 'returns deprecated message' do
        expect(json_response).to include('message' => 'Server supports batch API only, please update your Git LFS client to version 1.0.1 and up.')
      end
    end

    context 'when fetching lfs object using deprecated API' do
      let(:authorization) { authorize_user }

      before do
        get "#{project.http_url_to_repo}/info/lfs/objects/#{sample_oid}", nil, headers
      end

      it_behaves_like 'a deprecated'
    end

    context 'when handling lfs request using deprecated API' do
      let(:authorization) { authorize_user }
      before do
        post_lfs_json "#{project.http_url_to_repo}/info/lfs/objects", nil, headers
      end

      it_behaves_like 'a deprecated'
    end
  end

  describe 'when fetching lfs object' do
    let(:project) { create(:empty_project) }
    let(:update_permissions) { }

    before do
      enable_lfs
      update_permissions
      get "#{project.http_url_to_repo}/gitlab-lfs/objects/#{sample_oid}", nil, headers
    end

    context 'and request comes from gitlab-workhorse' do
      context 'without user being authorized' do
        it 'responds with status 401' do
          expect(response).to have_http_status(401)
        end
      end

      context 'with required headers' do
        shared_examples 'responds with a file' do
          let(:sendfile) { 'X-Sendfile' }

          it 'responds with status 200' do
            expect(response).to have_http_status(200)
          end

          it 'responds with the file location' do
            expect(response.headers['Content-Type']).to eq('application/octet-stream')
            expect(response.headers['X-Sendfile']).to eq(lfs_object.file.path)
          end
        end

        context 'with user is authorized' do
          let(:authorization) { authorize_user }

          context 'and does not have project access' do
            let(:update_permissions) do
              project.lfs_objects << lfs_object
            end

            it 'responds with status 404' do
              expect(response).to have_http_status(404)
            end
          end

          context 'and does have project access' do
            let(:update_permissions) do
              project.team << [user, :master]
              project.lfs_objects << lfs_object
            end

            it_behaves_like 'responds with a file'
          end
        end

        context 'when CI is authorized' do
          let(:authorization) { authorize_ci_project }

          let(:update_permissions) do
            project.lfs_objects << lfs_object
          end

          it_behaves_like 'responds with a file'
        end
      end

      context 'without required headers' do
        let(:authorization) { authorize_user }

        it 'responds with status 404' do
          expect(response).to have_http_status(404)
        end
      end
    end
  end

  describe 'when handling lfs batch request' do
    let(:update_lfs_permissions) { }
    let(:update_user_permissions) { }

    before do
      enable_lfs
      update_lfs_permissions
      update_user_permissions
      post_lfs_json "#{project.http_url_to_repo}/info/lfs/objects/batch", body, headers
    end

    describe 'download' do
      let(:project) { create(:empty_project) }
      let(:body) do
        { 'operation' => 'download',
          'objects' => [
            { 'oid' => sample_oid,
              'size' => sample_size
            }]
        }
      end

      shared_examples 'an authorized requests' do
        context 'when downloading an lfs object that is assigned to our project' do
          let(:update_lfs_permissions) do
            project.lfs_objects << lfs_object
          end

          it 'responds with status 200' do
            expect(response).to have_http_status(200)
          end

          it 'with href to download' do
            expect(json_response).to eq('objects' => [
              { 'oid' => sample_oid,
                'size' => sample_size,
                'actions' => {
                  'download' => {
                    'href' => "#{project.http_url_to_repo}/gitlab-lfs/objects/#{sample_oid}",
                    'header' => { 'Authorization' => authorization }
                  }
                }
              }])
          end
        end

        context 'when downloading an lfs object that is assigned to other project' do
          let(:other_project) { create(:empty_project) }
          let(:update_lfs_permissions) do
            other_project.lfs_objects << lfs_object
          end

          it 'responds with status 200' do
            expect(response).to have_http_status(200)
          end

          it 'with href to download' do
            expect(json_response).to eq('objects' => [
              { 'oid' => sample_oid,
                'size' => sample_size,
                'error' => {
                  'code' => 404,
                  'message' => "Object does not exist on the server or you don't have permissions to access it",
                }
              }])
          end
        end

        context 'when downloading a lfs object that does not exist' do
          let(:body) do
            { 'operation' => 'download',
              'objects' => [
                { 'oid' => '91eff75a492a3ed0dfcb544d7f31326bc4014c8551849c192fd1e48d4dd2c897',
                  'size' => 1575078
                }]
            }
          end

          it 'responds with status 200' do
            expect(response).to have_http_status(200)
          end

          it 'with an 404 for specific object' do
            expect(json_response).to eq('objects' => [
              { 'oid' => '91eff75a492a3ed0dfcb544d7f31326bc4014c8551849c192fd1e48d4dd2c897',
                'size' => 1575078,
                'error' => {
                  'code' => 404,
                  'message' => "Object does not exist on the server or you don't have permissions to access it",
                }
              }])
          end
        end

        context 'when downloading one new and one existing lfs object' do
          let(:body) do
            { 'operation' => 'download',
              'objects' => [
                { 'oid' => '91eff75a492a3ed0dfcb544d7f31326bc4014c8551849c192fd1e48d4dd2c897',
                  'size' => 1575078
                },
                { 'oid' => sample_oid,
                  'size' => sample_size
                }
              ]
            }
          end

          let(:update_lfs_permissions) do
            project.lfs_objects << lfs_object
          end

          it 'responds with status 200' do
            expect(response).to have_http_status(200)
          end

          it 'responds with upload hypermedia link for the new object' do
            expect(json_response).to eq('objects' => [
              { 'oid' => '91eff75a492a3ed0dfcb544d7f31326bc4014c8551849c192fd1e48d4dd2c897',
                'size' => 1575078,
                'error' => {
                  'code' => 404,
                  'message' => "Object does not exist on the server or you don't have permissions to access it",
                }
              },
              { 'oid' => sample_oid,
                'size' => sample_size,
                'actions' => {
                  'download' => {
                    'href' => "#{project.http_url_to_repo}/gitlab-lfs/objects/#{sample_oid}",
                    'header' => { 'Authorization' => authorization }
                  }
                }
              }])
          end
        end
      end

      context 'when user is authenticated' do
        let(:authorization) { authorize_user }

        let(:update_user_permissions) do
          project.team << [user, role]
        end

        it_behaves_like 'an authorized requests' do
          let(:role) { :reporter }
        end

        context 'when user does is not member of the project' do
          let(:update_user_permissions) { nil }

          it 'responds with 404' do
            expect(response).to have_http_status(404)
          end
        end

        context 'when user does not have download access' do
          let(:role) { :guest }

          it 'responds with 403' do
            expect(response).to have_http_status(403)
          end
        end
      end

      context 'when CI is authorized' do
        let(:authorization) { authorize_ci_project }

        it_behaves_like 'an authorized requests'
      end

      context 'when user is not authenticated' do
        describe 'is accessing public project' do
          let(:project) { create(:project, :public) }

          let(:update_lfs_permissions) do
            project.lfs_objects << lfs_object
          end

          it 'responds with status 200 and href to download' do
            expect(response).to have_http_status(200)
          end

          it 'responds with status 200 and href to download' do
            expect(json_response).to eq('objects' => [
              { 'oid' => sample_oid,
                'size' => sample_size,
                'actions' => {
                  'download' => {
                    'href' => "#{project.http_url_to_repo}/gitlab-lfs/objects/#{sample_oid}",
                    'header' => {}
                  }
                }
              }])
          end
        end

        describe 'is accessing non-public project' do
          let(:update_lfs_permissions) do
            project.lfs_objects << lfs_object
          end

          it 'responds with authorization required' do
            expect(response).to have_http_status(401)
          end
        end
      end
    end

    describe 'upload' do
      let(:project) { create(:project, :public) }
      let(:body) do
        { 'operation' => 'upload',
          'objects' => [
            { 'oid' => sample_oid,
              'size' => sample_size
            }]
        }
      end

      describe 'when request is authenticated' do
        describe 'when user has project push access' do
          let(:authorization) { authorize_user }

          let(:update_user_permissions) do
            project.team << [user, :developer]
          end

          context 'when pushing an lfs object that already exists' do
            let(:other_project) { create(:empty_project) }
            let(:update_lfs_permissions) do
              other_project.lfs_objects << lfs_object
            end

            it 'responds with status 200' do
              expect(response).to have_http_status(200)
            end

            it 'responds with links the object to the project' do
              expect(json_response['objects']).to be_kind_of(Array)
              expect(json_response['objects'].first['oid']).to eq(sample_oid)
              expect(json_response['objects'].first['size']).to eq(sample_size)
              expect(lfs_object.projects.pluck(:id)).not_to include(project.id)
              expect(lfs_object.projects.pluck(:id)).to include(other_project.id)
              expect(json_response['objects'].first['actions']['upload']['href']).to eq("#{project.http_url_to_repo}/gitlab-lfs/objects/#{sample_oid}/#{sample_size}")
              expect(json_response['objects'].first['actions']['upload']['header']).to eq('Authorization' => authorization)
            end
          end

          context 'when pushing a lfs object that does not exist' do
            let(:body) do
              { 'operation' => 'upload',
                'objects' => [
                  { 'oid' => '91eff75a492a3ed0dfcb544d7f31326bc4014c8551849c192fd1e48d4dd2c897',
                    'size' => 1575078
                  }]
              }
            end

            it 'responds with status 200' do
              expect(response).to have_http_status(200)
            end

            it 'responds with upload hypermedia link' do
              expect(json_response['objects']).to be_kind_of(Array)
              expect(json_response['objects'].first['oid']).to eq("91eff75a492a3ed0dfcb544d7f31326bc4014c8551849c192fd1e48d4dd2c897")
              expect(json_response['objects'].first['size']).to eq(1575078)
              expect(json_response['objects'].first['actions']['upload']['href']).to eq("#{Gitlab.config.gitlab.url}/#{project.path_with_namespace}.git/gitlab-lfs/objects/91eff75a492a3ed0dfcb544d7f31326bc4014c8551849c192fd1e48d4dd2c897/1575078")
              expect(json_response['objects'].first['actions']['upload']['header']).to eq('Authorization' => authorization)
            end
          end

          context 'when pushing one new and one existing lfs object' do
            let(:body) do
              { 'operation' => 'upload',
                'objects' => [
                  { 'oid' => '91eff75a492a3ed0dfcb544d7f31326bc4014c8551849c192fd1e48d4dd2c897',
                    'size' => 1575078
                  },
                  { 'oid' => sample_oid,
                    'size' => sample_size
                  }
                ]
              }
            end

            let(:update_lfs_permissions) do
              project.lfs_objects << lfs_object
            end

            it 'responds with status 200' do
              expect(response).to have_http_status(200)
            end

            it 'responds with upload hypermedia link for the new object' do
              expect(json_response['objects']).to be_kind_of(Array)

              expect(json_response['objects'].first['oid']).to eq("91eff75a492a3ed0dfcb544d7f31326bc4014c8551849c192fd1e48d4dd2c897")
              expect(json_response['objects'].first['size']).to eq(1575078)
              expect(json_response['objects'].first['actions']['upload']['href']).to eq("#{project.http_url_to_repo}/gitlab-lfs/objects/91eff75a492a3ed0dfcb544d7f31326bc4014c8551849c192fd1e48d4dd2c897/1575078")
              expect(json_response['objects'].first['actions']['upload']['header']).to eq("Authorization" => authorization)

              expect(json_response['objects'].last['oid']).to eq(sample_oid)
              expect(json_response['objects'].last['size']).to eq(sample_size)
              expect(json_response['objects'].last).not_to have_key('actions')
            end
          end
        end

        context 'when user does not have push access' do
          let(:authorization) { authorize_user }

          it 'responds with 403' do
            expect(response).to have_http_status(403)
          end
        end

        context 'when CI is authorized' do
          let(:authorization) { authorize_ci_project }

          it 'responds with 401' do
            expect(response).to have_http_status(401)
          end
        end
      end

      context 'when user is not authenticated' do
        context 'when user has push access' do
          let(:update_user_permissions) do
            project.team << [user, :master]
          end

          it 'responds with status 401' do
            expect(response).to have_http_status(401)
          end
        end

        context 'when user does not have push access' do
          it 'responds with status 401' do
            expect(response).to have_http_status(401)
          end
        end
      end

      context 'when CI is authorized' do
        let(:authorization) { authorize_ci_project }

        it 'responds with status 403' do
          expect(response).to have_http_status(401)
        end
      end
    end

    describe 'unsupported' do
      let(:project) { create(:empty_project) }
      let(:authorization) { authorize_user }
      let(:body) do
        { 'operation' => 'other',
          'objects' => [
            { 'oid' => sample_oid,
              'size' => sample_size
            }]
        }
      end

      it 'responds with status 404' do
        expect(response).to have_http_status(404)
      end
    end
  end

  describe 'when pushing a lfs object' do
    before do
      enable_lfs
    end

    shared_examples 'unauthorized' do
      context 'and request is sent by gitlab-workhorse to authorize the request' do
        before do
          put_authorize
        end

        it 'responds with status 401' do
          expect(response).to have_http_status(401)
        end
      end

      context 'and request is sent by gitlab-workhorse to finalize the upload' do
        before do
          put_finalize
        end

        it 'responds with status 401' do
          expect(response).to have_http_status(401)
        end
      end

      context 'and request is sent with a malformed headers' do
        before do
          put_finalize('/etc/passwd')
        end

        it 'does not recognize it as a valid lfs command' do
          expect(response).to have_http_status(401)
        end
      end
    end

    shared_examples 'forbidden' do
      context 'and request is sent by gitlab-workhorse to authorize the request' do
        before do
          put_authorize
        end

        it 'responds with 403' do
          expect(response).to have_http_status(403)
        end
      end

      context 'and request is sent by gitlab-workhorse to finalize the upload' do
        before do
          put_finalize
        end

        it 'responds with 403' do
          expect(response).to have_http_status(403)
        end
      end

      context 'and request is sent with a malformed headers' do
        before do
          put_finalize('/etc/passwd')
        end

        it 'does not recognize it as a valid lfs command' do
          expect(response).to have_http_status(403)
        end
      end
    end

    describe 'to one project' do
      let(:project) { create(:empty_project) }

      describe 'when user is authenticated' do
        let(:authorization) { authorize_user }

        describe 'when user has push access to the project' do
          before do
            project.team << [user, :developer]
          end

          context 'and request is sent by gitlab-workhorse to authorize the request' do
            before do
              put_authorize
            end

            it 'responds with status 200' do
              expect(response).to have_http_status(200)
            end

            it 'responds with status 200, location of lfs store and object details' do
              expect(json_response['StoreLFSPath']).to eq("#{Gitlab.config.shared.path}/lfs-objects/tmp/upload")
              expect(json_response['LfsOid']).to eq(sample_oid)
              expect(json_response['LfsSize']).to eq(sample_size)
            end
          end

          context 'and request is sent by gitlab-workhorse to finalize the upload' do
            before do
              put_finalize
            end

            it 'responds with status 200' do
              expect(response).to have_http_status(200)
            end

            it 'lfs object is linked to the project' do
              expect(lfs_object.projects.pluck(:id)).to include(project.id)
            end
          end

          context 'invalid tempfiles' do
            it 'rejects slashes in the tempfile name (path traversal' do
              put_finalize('foo/bar')
              expect(response).to have_http_status(403)
            end

            it 'rejects tempfile names that do not start with the oid' do
              put_finalize("foo#{sample_oid}")
              expect(response).to have_http_status(403)
            end
          end
        end

        describe 'and user does not have push access' do
          before do
            project.team << [user, :reporter]
          end

          it_behaves_like 'forbidden'
        end
      end

      context 'when CI is authenticated' do
        let(:authorization) { authorize_ci_project }

        it_behaves_like 'unauthorized'
      end

      context 'for unauthenticated' do
        it_behaves_like 'unauthorized'
      end
    end

    describe 'to a forked project' do
      let(:upstream_project) { create(:project, :public) }
      let(:project_owner) { create(:user) }
      let(:project) { fork_project(upstream_project, project_owner) }

      describe 'when user is authenticated' do
        let(:authorization) { authorize_user }

        describe 'when user has push access to the project' do
          before do
            project.team << [user, :developer]
          end

          context 'and request is sent by gitlab-workhorse to authorize the request' do
            before do
              put_authorize
            end

            it 'responds with status 200' do
              expect(response).to have_http_status(200)
            end

            it 'with location of lfs store and object details' do
              expect(json_response['StoreLFSPath']).to eq("#{Gitlab.config.shared.path}/lfs-objects/tmp/upload")
              expect(json_response['LfsOid']).to eq(sample_oid)
              expect(json_response['LfsSize']).to eq(sample_size)
            end
          end

          context 'and request is sent by gitlab-workhorse to finalize the upload' do
            before do
              put_finalize
            end

            it 'responds with status 200' do
              expect(response).to have_http_status(200)
            end

            it 'lfs object is linked to the source project' do
              expect(lfs_object.projects.pluck(:id)).to include(upstream_project.id)
            end
          end
        end

        describe 'and user does not have push access' do
          it_behaves_like 'forbidden'
        end
      end

      context 'when CI is authenticated' do
        let(:authorization) { authorize_ci_project }

        it_behaves_like 'unauthorized'
      end

      context 'for unauthenticated' do
        it_behaves_like 'unauthorized'
      end

      describe 'and second project not related to fork or a source project' do
        let(:second_project) { create(:empty_project) }
        let(:authorization) { authorize_user }

        before do
          second_project.team << [user, :master]
          upstream_project.lfs_objects << lfs_object
        end

        context 'when pushing the same lfs object to the second project' do
          before do
            put "#{second_project.http_url_to_repo}/gitlab-lfs/objects/#{sample_oid}/#{sample_size}", nil,
                headers.merge('X-Gitlab-Lfs-Tmp' => lfs_tmp_file).compact
          end

          it 'responds with status 200' do
            expect(response).to have_http_status(200)
          end

          it 'links the lfs object to the project' do
            expect(lfs_object.projects.pluck(:id)).to include(second_project.id, upstream_project.id)
          end
        end
      end
    end

    def put_authorize
      put "#{project.http_url_to_repo}/gitlab-lfs/objects/#{sample_oid}/#{sample_size}/authorize", nil, headers
    end

    def put_finalize(lfs_tmp = lfs_tmp_file)
      put "#{project.http_url_to_repo}/gitlab-lfs/objects/#{sample_oid}/#{sample_size}", nil,
          headers.merge('X-Gitlab-Lfs-Tmp' => lfs_tmp).compact
    end

    def lfs_tmp_file
      "#{sample_oid}012345678"
    end
  end

  def enable_lfs
    allow(Gitlab.config.lfs).to receive(:enabled).and_return(true)
  end

  def authorize_ci_project
    ActionController::HttpAuthentication::Basic.encode_credentials('gitlab-ci-token', project.runners_token)
  end

  def authorize_user
    ActionController::HttpAuthentication::Basic.encode_credentials(user.username, user.password)
  end

  def fork_project(project, user, object = nil)
    allow(RepositoryForkWorker).to receive(:perform_async).and_return(true)
    Projects::ForkService.new(project, user, {}).execute
  end

  def post_lfs_json(url, body = nil, headers = nil)
    post(url, body.try(:to_json), (headers || {}).merge('Content-Type' => 'application/vnd.git-lfs+json'))
  end

  def json_response
    @json_response ||= JSON.parse(response.body)
  end
end
