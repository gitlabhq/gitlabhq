require 'spec_helper'

describe Gitlab::Lfs::Router do
  let(:project) { create(:project) }
  let(:public_project) { create(:project, :public) }
  let(:forked_project) { fork_project(public_project, user) }

  let(:user) { create(:user) }
  let(:user_two) { create(:user) }
  let!(:lfs_object) { create(:lfs_object, :with_file) }

  let(:request) { Rack::Request.new(env) }
  let(:env) do
    {
      'rack.input'     => '',
      'REQUEST_METHOD' => 'GET',
    }
  end

  let(:lfs_router_auth) { new_lfs_router(project, user) }
  let(:lfs_router_noauth) { new_lfs_router(project, nil) }
  let(:lfs_router_public_auth) { new_lfs_router(public_project, user) }
  let(:lfs_router_public_noauth) { new_lfs_router(public_project, nil) }
  let(:lfs_router_forked_noauth) { new_lfs_router(forked_project, nil) }
  let(:lfs_router_forked_auth) { new_lfs_router(forked_project, user_two) }

  let(:sample_oid) { "b68143e6463773b1b6c6fd009a76c32aeec041faff32ba2ed42fd7f708a17f80" }
  let(:sample_size) { 499013 }

  describe 'when lfs is disabled' do
    before do
      allow(Gitlab.config.lfs).to receive(:enabled).and_return(false)
      env["PATH_INFO"] = "#{project.repository.path_with_namespace}.git/info/lfs/objects/#{sample_oid}"
    end

    it 'responds with 501' do
      respond_with_disabled = [ 501,
                                { "Content-Type"=>"application/vnd.git-lfs+json" },
                                ["{\"message\":\"Git LFS is not enabled on this GitLab server, contact your admin.\",\"documentation_url\":\"#{Gitlab.config.gitlab.url}/help\"}"]
                              ]
      expect(lfs_router_auth.try_call).to match_array(respond_with_disabled)
    end
  end

  describe 'when fetching lfs object' do
    before do
      enable_lfs
      env['HTTP_ACCEPT'] = "application/vnd.git-lfs+json; charset=utf-8"
      env["PATH_INFO"] = "#{project.repository.path_with_namespace}.git/info/lfs/objects/#{sample_oid}"
    end

    describe 'when user is authenticated' do
      context 'and user has project download access' do
        before do
          @auth = authorize(user)
          env["HTTP_AUTHORIZATION"] = @auth
          project.lfs_objects << lfs_object
          project.team << [user, :master]
        end

        it "responds with status 200" do
          expect(lfs_router_auth.try_call.first).to eq(200)
        end

        it "responds with download hypermedia" do
          json_response = ActiveSupport::JSON.decode(lfs_router_auth.try_call.last.first)

          expect(json_response['_links']['download']['href']).to eq("#{Gitlab.config.gitlab.url}/#{project.path_with_namespace}.git/gitlab-lfs/objects/#{sample_oid}")
          expect(json_response['_links']['download']['header']).to eq("Authorization" => @auth)
        end
      end

      context 'and user does not have project access' do
        it "responds with status 403" do
          expect(lfs_router_auth.try_call.first).to eq(403)
        end
      end
    end

    describe 'when user is unauthenticated' do
      context 'and user does not have download access' do
        it "responds with status 401" do
          expect(lfs_router_noauth.try_call.first).to eq(401)
        end
      end

      context 'and user has download access' do
        before do
          project.team << [user, :master]
        end

        it "responds with status 401" do
          expect(lfs_router_noauth.try_call.first).to eq(401)
        end
      end
    end

    describe 'and project is public' do
      context 'and project has access to the lfs object' do
        before do
          public_project.lfs_objects << lfs_object
        end

        context 'and user is authenticated' do
          it "responds with status 200 and sends download hypermedia" do
            expect(lfs_router_public_auth.try_call.first).to eq(200)
            json_response = ActiveSupport::JSON.decode(lfs_router_public_auth.try_call.last.first)

            expect(json_response['_links']['download']['href']).to eq("#{Gitlab.config.gitlab.url}/#{public_project.path_with_namespace}.git/gitlab-lfs/objects/#{sample_oid}")
            expect(json_response['_links']['download']['header']).to eq({})
          end
        end

        context 'and user is unauthenticated' do
          it "responds with status 200 and sends download hypermedia" do
            expect(lfs_router_public_noauth.try_call.first).to eq(200)
            json_response = ActiveSupport::JSON.decode(lfs_router_public_noauth.try_call.last.first)

            expect(json_response['_links']['download']['href']).to eq("#{Gitlab.config.gitlab.url}/#{public_project.path_with_namespace}.git/gitlab-lfs/objects/#{sample_oid}")
            expect(json_response['_links']['download']['header']).to eq({})
          end
        end
      end

      context 'and project does not have access to the lfs object' do
        it "responds with status 404" do
          expect(lfs_router_public_auth.try_call.first).to eq(404)
        end
      end
    end

    describe 'and request comes from gitlab-workhorse' do
      before do
        env["PATH_INFO"] = "#{project.repository.path_with_namespace}.git/gitlab-lfs/objects/#{sample_oid}"
      end
      context 'without user being authorized' do
        it "responds with status 401" do
          expect(lfs_router_noauth.try_call.first).to eq(401)
        end
      end

      context 'with required headers' do
        before do
          env['HTTP_X_SENDFILE_TYPE'] = "X-Sendfile"
        end

        context 'when user does not have project access' do
          it "responds with status 403" do
            expect(lfs_router_auth.try_call.first).to eq(403)
          end
        end

        context 'when user has project access' do
          before do
            project.lfs_objects << lfs_object
            project.team << [user, :master]
          end

          it "responds with status 200" do
            expect(lfs_router_auth.try_call.first).to eq(200)
          end

          it "responds with the file location" do
            expect(lfs_router_auth.try_call[1]['Content-Type']).to eq("application/octet-stream")
            expect(lfs_router_auth.try_call[1]['X-Sendfile']).to eq(lfs_object.file.path)
          end
        end
      end

      context 'without required headers' do
        it "responds with status 403" do
          expect(lfs_router_auth.try_call.first).to eq(403)
        end
      end
    end

    describe 'from a forked public project' do
      before do
        env['HTTP_ACCEPT'] = "application/vnd.git-lfs+json; charset=utf-8"
        env["PATH_INFO"] = "#{forked_project.repository.path_with_namespace}.git/info/lfs/objects/#{sample_oid}"
      end

      context "when fetching a lfs object" do
        context "and user has project download access" do
          before do
            public_project.lfs_objects << lfs_object
          end

          it "can download the lfs object" do
            expect(lfs_router_forked_auth.try_call.first).to eq(200)
            json_response = ActiveSupport::JSON.decode(lfs_router_forked_auth.try_call.last.first)

            expect(json_response['_links']['download']['href']).to eq("#{Gitlab.config.gitlab.url}/#{forked_project.path_with_namespace}.git/gitlab-lfs/objects/#{sample_oid}")
            expect(json_response['_links']['download']['header']).to eq({})
          end
        end

        context "and user is not authenticated but project is public" do
          before do
            public_project.lfs_objects << lfs_object
          end

          it "can download the lfs object" do
            expect(lfs_router_forked_auth.try_call.first).to eq(200)
          end
        end

        context "and user has project download access" do
          before do
            env["PATH_INFO"] = "#{forked_project.repository.path_with_namespace}.git/info/lfs/objects/91eff75a492a3ed0dfcb544d7f31326bc4014c8551849c192fd1e48d4dd2c897"
            @auth = ActionController::HttpAuthentication::Basic.encode_credentials(user.username, user.password)
            env["HTTP_AUTHORIZATION"] = @auth
            lfs_object_two = create(:lfs_object, :with_file, oid: "91eff75a492a3ed0dfcb544d7f31326bc4014c8551849c192fd1e48d4dd2c897", size: 1575078)
            public_project.lfs_objects << lfs_object_two
          end

          it "can get a lfs object that is not in the forked project" do
            expect(lfs_router_forked_auth.try_call.first).to eq(200)

            json_response = ActiveSupport::JSON.decode(lfs_router_forked_auth.try_call.last.first)
            expect(json_response['_links']['download']['href']).to eq("#{Gitlab.config.gitlab.url}/#{forked_project.path_with_namespace}.git/gitlab-lfs/objects/91eff75a492a3ed0dfcb544d7f31326bc4014c8551849c192fd1e48d4dd2c897")
            expect(json_response['_links']['download']['header']).to eq("Authorization" => @auth)
          end
        end

        context "and user has project download access" do
          before do
            env["PATH_INFO"] = "#{forked_project.repository.path_with_namespace}.git/info/lfs/objects/267c8b1d876743971e3a9978405818ff5ca731c4c870b06507619cd9b1847b6b"
            lfs_object_three = create(:lfs_object, :with_file, oid: "267c8b1d876743971e3a9978405818ff5ca731c4c870b06507619cd9b1847b6b", size: 127192524)
            project.lfs_objects << lfs_object_three
          end

          it "cannot get a lfs object that is not in the project" do
            expect(lfs_router_forked_auth.try_call.first).to eq(404)
          end
        end
      end
    end
  end

  describe 'when initiating pushing of the lfs object' do
    before do
      enable_lfs
      env['REQUEST_METHOD'] = 'POST'
      env["PATH_INFO"] = "#{project.repository.path_with_namespace}.git/info/lfs/objects/batch"
    end

    describe 'when user is authenticated' do
      before do
        body = { 'objects' => [{
                   'oid' => sample_oid,
                   'size' => sample_size
                  }],
                  'operation' => 'upload'
                }.to_json
        env['rack.input'] = StringIO.new(body)
      end

      describe 'when user has project push access' do
        before do
          @auth = authorize(user)
          env["HTTP_AUTHORIZATION"] = @auth
          project.team << [user, :master]
        end

        context 'when pushing an lfs object that already exists' do
          before do
            public_project.lfs_objects << lfs_object
          end

          it "responds with status 200 and links the object to the project" do
            response_body = lfs_router_auth.try_call.last
            response = ActiveSupport::JSON.decode(response_body.first)

            expect(response['objects']).to be_kind_of(Array)
            expect(response['objects'].first['oid']).to eq(sample_oid)
            expect(response['objects'].first['size']).to eq(sample_size)
            expect(lfs_object.projects.pluck(:id)).to_not include(project.id)
            expect(lfs_object.projects.pluck(:id)).to include(public_project.id)
            expect(response['objects'].first).to have_key('_links')
          end
        end

        context 'when pushing a lfs object that does not exist' do
          before do
            body = {
              'objects' => [{
                'oid' => '91eff75a492a3ed0dfcb544d7f31326bc4014c8551849c192fd1e48d4dd2c897',
                'size' => 1575078
                }],
              'operation' => 'upload'
                }.to_json
            env['rack.input'] = StringIO.new(body)
          end

          it "responds with status 200 and upload hypermedia link" do
            response = lfs_router_auth.try_call
            expect(response.first).to eq(200)

            response_body = ActiveSupport::JSON.decode(response.last.first)
            expect(response_body['objects']).to be_kind_of(Array)
            expect(response_body['objects'].first['oid']).to eq("91eff75a492a3ed0dfcb544d7f31326bc4014c8551849c192fd1e48d4dd2c897")
            expect(response_body['objects'].first['size']).to eq(1575078)
            expect(lfs_object.projects.pluck(:id)).not_to include(project.id)
            expect(response_body['objects'].first['_links']['upload']['href']).to eq("#{Gitlab.config.gitlab.url}/#{project.path_with_namespace}.git/gitlab-lfs/objects/91eff75a492a3ed0dfcb544d7f31326bc4014c8551849c192fd1e48d4dd2c897/1575078")
            expect(response_body['objects'].first['_links']['upload']['header']).to eq("Authorization" => @auth)
          end
        end

        context 'when pushing one new and one existing lfs object' do
          before do
            body = {
              'objects' => [
                { 'oid' => '91eff75a492a3ed0dfcb544d7f31326bc4014c8551849c192fd1e48d4dd2c897',
                  'size' => 1575078
                },
                { 'oid' => sample_oid,
                  'size' => sample_size
                }
              ],
              'operation' => 'upload'
            }.to_json
            env['rack.input'] = StringIO.new(body)
            public_project.lfs_objects << lfs_object
          end

          it "responds with status 200 with upload hypermedia link for the new object" do
            response = lfs_router_auth.try_call
            expect(response.first).to eq(200)

            response_body = ActiveSupport::JSON.decode(response.last.first)
            expect(response_body['objects']).to be_kind_of(Array)


            expect(response_body['objects'].first['oid']).to eq("91eff75a492a3ed0dfcb544d7f31326bc4014c8551849c192fd1e48d4dd2c897")
            expect(response_body['objects'].first['size']).to eq(1575078)
            expect(response_body['objects'].first['_links']['upload']['href']).to eq("#{Gitlab.config.gitlab.url}/#{project.path_with_namespace}.git/gitlab-lfs/objects/91eff75a492a3ed0dfcb544d7f31326bc4014c8551849c192fd1e48d4dd2c897/1575078")
            expect(response_body['objects'].first['_links']['upload']['header']).to eq("Authorization" => @auth)

            expect(response_body['objects'].last['oid']).to eq(sample_oid)
            expect(response_body['objects'].last['size']).to eq(sample_size)
            expect(lfs_object.projects.pluck(:id)).to_not include(project.id)
            expect(lfs_object.projects.pluck(:id)).to include(public_project.id)
            expect(response_body['objects'].last).to have_key('_links')
          end
        end
      end

      context 'when user does not have push access' do
        it 'responds with 403' do
          expect(lfs_router_auth.try_call.first).to eq(403)
        end
      end
    end

    context 'when user is not authenticated' do
      before do
        env['rack.input'] = StringIO.new(
          { 'objects' => [], 'operation' => 'upload' }.to_json
        )
      end

      context 'when user has push access' do
        before do
          project.team << [user, :master]
        end

        it "responds with status 401" do
          expect(lfs_router_public_noauth.try_call.first).to eq(401)
        end
      end

      context 'when user does not have push access' do
        it "responds with status 401" do
          expect(lfs_router_public_noauth.try_call.first).to eq(401)
        end
      end
    end
  end

  describe 'when pushing a lfs object' do
    before do
      enable_lfs
      env['REQUEST_METHOD'] = 'PUT'
    end

    describe 'to one project' do
      describe 'when user has push access to the project' do
        before do
          project.team << [user, :master]
        end

        describe 'when user is authenticated' do
          context 'and request is sent by gitlab-workhorse to authorize the request' do
            before do
              header_for_upload_authorize(project)
            end

            it 'responds with status 200, location of lfs store and object details' do
              json_response = ActiveSupport::JSON.decode(lfs_router_auth.try_call.last.first)

              expect(lfs_router_auth.try_call.first).to eq(200)
              expect(json_response['StoreLFSPath']).to eq("#{Gitlab.config.shared.path}/lfs-objects/tmp/upload")
              expect(json_response['LfsOid']).to eq(sample_oid)
              expect(json_response['LfsSize']).to eq(sample_size)
            end
          end

          context 'and request is sent by gitlab-workhorse to finalize the upload' do
            before do
              headers_for_upload_finalize(project)
            end

            it 'responds with status 200 and lfs object is linked to the project' do
              expect(lfs_router_auth.try_call.first).to eq(200)
              expect(lfs_object.projects.pluck(:id)).to include(project.id)
            end
          end
        end

        describe 'when user is unauthenticated' do
          let(:lfs_router_noauth) { new_lfs_router(project, nil) }

          context 'and request is sent by gitlab-workhorse to authorize the request' do
            before do
              header_for_upload_authorize(project)
            end

            it 'responds with status 401' do
              expect(lfs_router_noauth.try_call.first).to eq(401)
            end
          end

          context 'and request is sent by gitlab-workhorse to finalize the upload' do
            before do
              headers_for_upload_finalize(project)
            end

            it 'responds with status 401' do
              expect(lfs_router_noauth.try_call.first).to eq(401)
            end
          end

          context 'and request is sent with a malformed headers' do
            before do
              env["PATH_INFO"] = "#{project.repository.path_with_namespace}.git/gitlab-lfs/objects/#{sample_oid}/#{sample_size}"
              env["HTTP_X_GITLAB_LFS_TMP"] = "cat /etc/passwd"
            end

            it 'does not recognize it as a valid lfs command' do
              expect(lfs_router_noauth.try_call).to eq(nil)
            end
          end
        end
      end

      describe 'and user does not have push access' do
        describe 'when user is authenticated' do
          context 'and request is sent by gitlab-workhorse to authorize the request' do
            before do
              header_for_upload_authorize(project)
            end

            it 'responds with 403' do
              expect(lfs_router_auth.try_call.first).to eq(403)
            end
          end

          context 'and request is sent by gitlab-workhorse to finalize the upload' do
            before do
              headers_for_upload_finalize(project)
            end

            it 'responds with 403' do
              expect(lfs_router_auth.try_call.first).to eq(403)
            end
          end
        end

        describe 'when user is unauthenticated' do
          let(:lfs_router_noauth) { new_lfs_router(project, nil) }

          context 'and request is sent by gitlab-workhorse to authorize the request' do
            before do
              header_for_upload_authorize(project)
            end

            it 'responds with 401' do
              expect(lfs_router_noauth.try_call.first).to eq(401)
            end
          end

          context 'and request is sent by gitlab-workhorse to finalize the upload' do
            before do
              headers_for_upload_finalize(project)
            end

            it 'responds with 401' do
              expect(lfs_router_noauth.try_call.first).to eq(401)
            end
          end
        end
      end
    end

    describe "to a forked project" do
      let(:forked_project) { fork_project(public_project, user) }

      describe 'when user has push access to the project' do
        before do
          forked_project.team << [user_two, :master]
        end

        describe 'when user is authenticated' do
          context 'and request is sent by gitlab-workhorse to authorize the request' do
            before do
              header_for_upload_authorize(forked_project)
            end

            it 'responds with status 200, location of lfs store and object details' do
              json_response = ActiveSupport::JSON.decode(lfs_router_forked_auth.try_call.last.first)

              expect(lfs_router_forked_auth.try_call.first).to eq(200)
              expect(json_response['StoreLFSPath']).to eq("#{Gitlab.config.shared.path}/lfs-objects/tmp/upload")
              expect(json_response['LfsOid']).to eq(sample_oid)
              expect(json_response['LfsSize']).to eq(sample_size)
            end
          end

          context 'and request is sent by gitlab-workhorse to finalize the upload' do
            before do
              headers_for_upload_finalize(forked_project)
            end

            it 'responds with status 200 and lfs object is linked to the source project' do
              expect(lfs_router_forked_auth.try_call.first).to eq(200)
              expect(lfs_object.projects.pluck(:id)).to include(public_project.id)
            end
          end
        end

        describe 'when user is unauthenticated' do
          context 'and request is sent by gitlab-workhorse to authorize the request' do
            before do
              header_for_upload_authorize(forked_project)
            end

            it 'responds with status 401' do
              expect(lfs_router_forked_noauth.try_call.first).to eq(401)
            end
          end

          context 'and request is sent by gitlab-workhorse to finalize the upload' do
            before do
              headers_for_upload_finalize(forked_project)
            end

            it 'responds with status 401' do
              expect(lfs_router_forked_noauth.try_call.first).to eq(401)
            end
          end
        end
      end

      describe 'and user does not have push access' do
        describe 'when user is authenticated' do
          context 'and request is sent by gitlab-workhorse to authorize the request' do
            before do
              header_for_upload_authorize(forked_project)
            end

            it 'responds with 403' do
              expect(lfs_router_forked_auth.try_call.first).to eq(403)
            end
          end

          context 'and request is sent by gitlab-workhorse to finalize the upload' do
            before do
              headers_for_upload_finalize(forked_project)
            end

            it 'responds with 403' do
              expect(lfs_router_forked_auth.try_call.first).to eq(403)
            end
          end
        end

        describe 'when user is unauthenticated' do
          context 'and request is sent by gitlab-workhorse to authorize the request' do
            before do
              header_for_upload_authorize(forked_project)
            end

            it 'responds with 401' do
              expect(lfs_router_forked_noauth.try_call.first).to eq(401)
            end
          end

          context 'and request is sent by gitlab-workhorse to finalize the upload' do
            before do
              headers_for_upload_finalize(forked_project)
            end

            it 'responds with 401' do
              expect(lfs_router_forked_noauth.try_call.first).to eq(401)
            end
          end
        end
      end

      describe 'and second project not related to fork or a source project' do
        let(:second_project) { create(:project) }
        let(:lfs_router_second_project) { new_lfs_router(second_project, user) }

        before do
          public_project.lfs_objects << lfs_object
          headers_for_upload_finalize(second_project)
        end

        context 'when pushing the same lfs object to the second project' do
          before do
            second_project.team << [user, :master]
          end

          it 'responds with 200 and links the lfs object to the project' do
            expect(lfs_router_second_project.try_call.first).to eq(200)
            expect(lfs_object.projects.pluck(:id)).to include(second_project.id, public_project.id)
          end
        end
      end
    end
  end

  def enable_lfs
    allow(Gitlab.config.lfs).to receive(:enabled).and_return(true)
  end

  def authorize(user)
    ActionController::HttpAuthentication::Basic.encode_credentials(user.username, user.password)
  end

  def new_lfs_router(project, user)
    Gitlab::Lfs::Router.new(project, user, request)
  end

  def header_for_upload_authorize(project)
    env["PATH_INFO"] = "#{project.repository.path_with_namespace}.git/gitlab-lfs/objects/#{sample_oid}/#{sample_size}/authorize"
  end

  def headers_for_upload_finalize(project)
    env["PATH_INFO"] = "#{project.repository.path_with_namespace}.git/gitlab-lfs/objects/#{sample_oid}/#{sample_size}"
    env["HTTP_X_GITLAB_LFS_TMP"] = "#{sample_oid}6e561c9d4"
  end

  def fork_project(project, user, object = nil)
    allow(RepositoryForkWorker).to receive(:perform_async).and_return(true)
    Projects::ForkService.new(project, user, {}).execute
  end
end
