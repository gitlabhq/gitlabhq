require "spec_helper"

describe 'Git HTTP requests', lib: true do
  include GitHttpHelpers
  include WorkhorseHelpers

  it "gives WWW-Authenticate hints" do
    clone_get('doesnt/exist.git')

    expect(response.header['WWW-Authenticate']).to start_with('Basic ')
  end

  describe "User with no identities" do
    let(:user)    { create(:user) }
    let(:project) { create(:project, path: 'project.git-project') }

    context "when the project doesn't exist" do
      context "when no authentication is provided" do
        it "responds with status 401 (no project existence information leak)" do
          download('doesnt/exist.git') do |response|
            expect(response).to have_http_status(401)
          end
        end
      end

      context "when username and password are provided" do
        context "when authentication fails" do
          it "responds with status 401" do
            download('doesnt/exist.git', user: user.username, password: "nope") do |response|
              expect(response).to have_http_status(401)
            end
          end
        end

        context "when authentication succeeds" do
          it "responds with status 404" do
            download('/doesnt/exist.git', user: user.username, password: user.password) do |response|
              expect(response).to have_http_status(404)
            end
          end
        end
      end
    end

    context "when the Wiki for a project exists" do
      it "responds with the right project" do
        wiki = ProjectWiki.new(project)
        project.update_attribute(:visibility_level, Project::PUBLIC)

        download("/#{wiki.repository.path_with_namespace}.git") do |response|
          json_body = ActiveSupport::JSON.decode(response.body)

          expect(response).to have_http_status(200)
          expect(json_body['RepoPath']).to include(wiki.repository.path_with_namespace)
          expect(response.content_type.to_s).to eq(Gitlab::Workhorse::INTERNAL_API_CONTENT_TYPE)
        end
      end
    end

    context "when the project exists" do
      let(:path) { "#{project.path_with_namespace}.git" }

      context "when the project is public" do
        before do
          project.update_attribute(:visibility_level, Project::PUBLIC)
        end

        it "downloads get status 200" do
          download(path, {}) do |response|
            expect(response).to have_http_status(200)
            expect(response.content_type.to_s).to eq(Gitlab::Workhorse::INTERNAL_API_CONTENT_TYPE)
          end
        end

        it "uploads get status 401" do
          upload(path, {}) do |response|
            expect(response).to have_http_status(401)
          end
        end

        context "with correct credentials" do
          let(:env) { { user: user.username, password: user.password } }

          it "uploads get status 403" do
            upload(path, env) do |response|
              expect(response).to have_http_status(403)
            end
          end

          context 'but git-receive-pack is disabled' do
            it "responds with status 404" do
              allow(Gitlab.config.gitlab_shell).to receive(:receive_pack).and_return(false)

              upload(path, env) do |response|
                expect(response).to have_http_status(403)
              end
            end
          end
        end

        context 'but git-upload-pack is disabled' do
          it "responds with status 404" do
            allow(Gitlab.config.gitlab_shell).to receive(:upload_pack).and_return(false)

            download(path, {}) do |response|
              expect(response).to have_http_status(404)
            end
          end
        end

        context 'when the request is not from gitlab-workhorse' do
          it 'raises an exception' do
            expect do
              get("/#{project.path_with_namespace}.git/info/refs?service=git-upload-pack")
            end.to raise_error(JWT::DecodeError)
          end
        end
      end

      context "when Kerberos token is provided" do
        let(:env) { { spnego_request_token: 'opaque_request_token' } }

        before do
          allow_any_instance_of(Projects::GitHttpController).to receive(:allow_kerberos_spnego_auth?).and_return(true)
        end

        context "when authentication fails because of invalid Kerberos token" do
          before do
            allow_any_instance_of(Projects::GitHttpController).to receive(:spnego_credentials!).and_return(nil)
          end

          it "responds with status 401" do
            download(path, env) do |response|
              expect(response.status).to eq(401)
            end
          end
        end

        context "when authentication fails because of unknown Kerberos identity" do
          before do
            allow_any_instance_of(Projects::GitHttpController).to receive(:spnego_credentials!).and_return("mylogin@FOO.COM")
          end

          it "responds with status 401" do
            download(path, env) do |response|
              expect(response.status).to eq(401)
            end
          end
        end

        context "when authentication succeeds" do
          before do
            allow_any_instance_of(Projects::GitHttpController).to receive(:spnego_credentials!).and_return("mylogin@FOO.COM")
            user.identities.create!(provider: "kerberos", extern_uid: "mylogin@FOO.COM")
          end

          context "when the user has access to the project" do
            before do
              project.team << [user, :master]
            end

            context "when the user is blocked" do
              before do
                user.block
                project.team << [user, :master]
              end

              it "responds with status 404" do
                download(path, env) do |response|
                  expect(response.status).to eq(404)
                end
              end
            end

            context "when the user isn't blocked" do
              it "responds with status 200" do
                download(path, env) do |response|
                  expect(response.status).to eq(200)
                end
              end

              it 'updates the user last activity' do
                download(path, env) do |response|
                  expect(user.reload.last_activity_at).not_to be_nil
                end
              end
            end

            it "complies with RFC4559" do
              allow_any_instance_of(Projects::GitHttpController).to receive(:spnego_response_token).and_return("opaque_response_token")
              download(path, env) do |response|
                expect(response.headers['WWW-Authenticate'].split("\n")).to include("Negotiate #{::Base64.strict_encode64('opaque_response_token')}")
              end
            end
          end

          context "when the user doesn't have access to the project" do
            it "responds with status 404" do
              download(path, env) do |response|
                expect(response.status).to eq(404)
              end
            end

            it "complies with RFC4559" do
              allow_any_instance_of(Projects::GitHttpController).to receive(:spnego_response_token).and_return("opaque_response_token")
              download(path, env) do |response|
                expect(response.headers['WWW-Authenticate'].split("\n")).to include("Negotiate #{::Base64.strict_encode64('opaque_response_token')}")
              end
            end
          end
        end
      end

      context "when repository is above size limit" do
        let(:env) { { user: user.username, password: user.password } }

        before do
          project.team << [user, :master]
        end

        it 'responds with status 403' do
          allow_any_instance_of(Project).to receive(:above_size_limit?).and_return(true)

          upload(path, env) do |response|
            expect(response).to have_http_status(403)
          end
        end
      end

      context "when the project is private" do
        before do
          project.update_attribute(:visibility_level, Project::PRIVATE)
        end

        context "when no authentication is provided" do
          it "responds with status 401 to downloads" do
            download(path, {}) do |response|
              expect(response).to have_http_status(401)
            end
          end

          it "responds with status 401 to uploads" do
            upload(path, {}) do |response|
              expect(response).to have_http_status(401)
            end
          end
        end

        context "when username and password are provided" do
          let(:env) { { user: user.username, password: 'nope' } }

          context "when authentication fails" do
            it "responds with status 401" do
              download(path, env) do |response|
                expect(response).to have_http_status(401)
              end
            end

            context "when the user is IP banned" do
              it "responds with status 401" do
                expect(Rack::Attack::Allow2Ban).to receive(:filter).and_return(true)
                allow_any_instance_of(Rack::Request).to receive(:ip).and_return('1.2.3.4')

                clone_get(path, env)

                expect(response).to have_http_status(401)
              end
            end
          end

          context "when authentication succeeds" do
            let(:env) { { user: user.username, password: user.password } }

            context "when the user has access to the project" do
              before do
                project.team << [user, :master]
              end

              context "when the user is blocked" do
                it "responds with status 404" do
                  user.block
                  project.team << [user, :master]

                  download(path, env) do |response|
                    expect(response).to have_http_status(404)
                  end
                end
              end

              context "when the user isn't blocked" do
                it "downloads get status 200" do
                  expect(Rack::Attack::Allow2Ban).to receive(:reset)

                  clone_get(path, env)

                  expect(response).to have_http_status(200)
                  expect(response.content_type.to_s).to eq(Gitlab::Workhorse::INTERNAL_API_CONTENT_TYPE)
                end

                it "uploads get status 200" do
                  upload(path, env) do |response|
                    expect(response).to have_http_status(200)
                    expect(response.content_type.to_s).to eq(Gitlab::Workhorse::INTERNAL_API_CONTENT_TYPE)
                  end
                end
              end

              context "when an oauth token is provided" do
                before do
                  application = Doorkeeper::Application.create!(name: "MyApp", redirect_uri: "https://app.com", owner: user)
                  @token = Doorkeeper::AccessToken.create!(application_id: application.id, resource_owner_id: user.id)
                end

                it "downloads get status 200" do
                  clone_get "#{project.path_with_namespace}.git", user: 'oauth2', password: @token.token

                  expect(response).to have_http_status(200)
                  expect(response.content_type.to_s).to eq(Gitlab::Workhorse::INTERNAL_API_CONTENT_TYPE)
                end

                it "uploads get status 401 (no project existence information leak)" do
                  push_get "#{project.path_with_namespace}.git", user: 'oauth2', password: @token.token

                  expect(response).to have_http_status(401)
                end
              end

              context 'when user has 2FA enabled' do
                let(:user) { create(:user, :two_factor) }
                let(:access_token) { create(:personal_access_token, user: user) }

                before do
                  project.team << [user, :master]
                end

                context 'when username and password are provided' do
                  it 'rejects the clone attempt' do
                    download("#{project.path_with_namespace}.git", user: user.username, password: user.password) do |response|
                      expect(response).to have_http_status(401)
                      expect(response.body).to include('You have 2FA enabled, please use a personal access token for Git over HTTP')
                    end
                  end

                  it 'rejects the push attempt' do
                    upload("#{project.path_with_namespace}.git", user: user.username, password: user.password) do |response|
                      expect(response).to have_http_status(401)
                      expect(response.body).to include('You have 2FA enabled, please use a personal access token for Git over HTTP')
                    end
                  end
                end

                context 'when username and personal access token are provided' do
                  it 'allows clones' do
                    download("#{project.path_with_namespace}.git", user: user.username, password: access_token.token) do |response|
                      expect(response).to have_http_status(200)
                    end
                  end

                  it 'allows pushes' do
                    upload("#{project.path_with_namespace}.git", user: user.username, password: access_token.token) do |response|
                      expect(response).to have_http_status(200)
                    end
                  end
                end
              end

              context "when blank password attempts follow a valid login" do
                def attempt_login(include_password)
                  password = include_password ? user.password : ""
                  clone_get path, user: user.username, password: password
                  response.status
                end

                it "repeated attempts followed by successful attempt" do
                  options = Gitlab.config.rack_attack.git_basic_auth
                  maxretry = options[:maxretry] - 1
                  ip = '1.2.3.4'

                  allow_any_instance_of(Rack::Request).to receive(:ip).and_return(ip)
                  Rack::Attack::Allow2Ban.reset(ip, options)

                  maxretry.times.each do
                    expect(attempt_login(false)).to eq(401)
                  end

                  expect(attempt_login(true)).to eq(200)
                  expect(Rack::Attack::Allow2Ban.banned?(ip)).to be_falsey

                  maxretry.times.each do
                    expect(attempt_login(false)).to eq(401)
                  end

                  Rack::Attack::Allow2Ban.reset(ip, options)
                end
              end
            end

            context "when the user doesn't have access to the project" do
              it "downloads get status 404" do
                download(path, user: user.username, password: user.password) do |response|
                  expect(response).to have_http_status(404)
                end
              end

              it "uploads get status 404" do
                upload(path, user: user.username, password: user.password) do |response|
                  expect(response).to have_http_status(404)
                end
              end
            end
          end
        end

        context "when a gitlab ci token is provided" do
          let(:build) { create(:ci_build, :running) }
          let(:project) { build.project }
          let(:other_project) { create(:empty_project) }

          before do
            project.project_feature.update_attributes(builds_access_level: ProjectFeature::ENABLED)
          end

          context 'when build created by system is authenticated' do
            it "downloads get status 200" do
              clone_get "#{project.path_with_namespace}.git", user: 'gitlab-ci-token', password: build.token

              expect(response).to have_http_status(200)
              expect(response.content_type.to_s).to eq(Gitlab::Workhorse::INTERNAL_API_CONTENT_TYPE)
            end

            it "uploads get status 401 (no project existence information leak)" do
              push_get "#{project.path_with_namespace}.git", user: 'gitlab-ci-token', password: build.token

              expect(response).to have_http_status(401)
            end

            it "downloads from other project get status 404" do
              clone_get "#{other_project.path_with_namespace}.git", user: 'gitlab-ci-token', password: build.token

              expect(response).to have_http_status(404)
            end
          end

          context 'and build created by' do
            before do
              build.update(user: user)
              project.team << [user, :reporter]
            end

            shared_examples 'can download code only' do
              it 'downloads get status 200' do
                clone_get "#{project.path_with_namespace}.git", user: 'gitlab-ci-token', password: build.token

                expect(response).to have_http_status(200)
                expect(response.content_type.to_s).to eq(Gitlab::Workhorse::INTERNAL_API_CONTENT_TYPE)
              end

              it 'uploads get status 403' do
                push_get "#{project.path_with_namespace}.git", user: 'gitlab-ci-token', password: build.token

                expect(response).to have_http_status(401)
              end
            end

            context 'administrator' do
              let(:user) { create(:admin) }

              it_behaves_like 'can download code only'

              it 'downloads from other project get status 403' do
                clone_get "#{other_project.path_with_namespace}.git", user: 'gitlab-ci-token', password: build.token

                expect(response).to have_http_status(403)
              end
            end

            context 'regular user' do
              let(:user) { create(:user) }

              it_behaves_like 'can download code only'

              it 'downloads from other project get status 404' do
                clone_get "#{other_project.path_with_namespace}.git", user: 'gitlab-ci-token', password: build.token

                expect(response).to have_http_status(404)
              end
            end
          end
        end
      end
    end

    context "when the project path doesn't end in .git" do
      context "GET info/refs" do
        let(:path) { "/#{project.path_with_namespace}/info/refs" }

        context "when no params are added" do
          before { get path }

          it "redirects to the .git suffix version" do
            expect(response).to redirect_to("/#{project.path_with_namespace}.git/info/refs")
          end
        end

        context "when the upload-pack service is requested" do
          let(:params) { { service: 'git-upload-pack' } }
          before { get path, params }

          it "redirects to the .git suffix version" do
            expect(response).to redirect_to("/#{project.path_with_namespace}.git/info/refs?service=#{params[:service]}")
          end
        end

        context "when the receive-pack service is requested" do
          let(:params) { { service: 'git-receive-pack' } }
          before { get path, params }

          it "redirects to the .git suffix version" do
            expect(response).to redirect_to("/#{project.path_with_namespace}.git/info/refs?service=#{params[:service]}")
          end
        end

        context "when the params are anything else" do
          let(:params) { { service: 'git-implode-pack' } }

          it "fails to find a route" do
            expect { get(path, params) }.to raise_error(ActionController::RoutingError)
          end
        end
      end

      context "POST git-upload-pack" do
        it "fails to find a route" do
          expect { clone_post(project.path_with_namespace) }.to raise_error(ActionController::RoutingError)
        end
      end

      context "POST git-receive-pack" do
        it "failes to find a route" do
          expect { push_post(project.path_with_namespace) }.to raise_error(ActionController::RoutingError)
        end
      end
    end

    context "retrieving an info/refs file" do
      before { project.update_attribute(:visibility_level, Project::PUBLIC) }

      context "when the file exists" do
        before do
          # Provide a dummy file in its place
          allow_any_instance_of(Repository).to receive(:blob_at).and_call_original
          allow_any_instance_of(Repository).to receive(:blob_at).with('b83d6e391c22777fca1ed3012fce84f633d7fed0', 'info/refs') do
            Gitlab::Git::Blob.find(project.repository, 'master', 'bar/branch-test.txt')
          end

          get "/#{project.path_with_namespace}/blob/master/info/refs"
        end

        it "returns the file" do
          expect(response).to have_http_status(200)
        end
      end

      context "when the file does not exist" do
        before { get "/#{project.path_with_namespace}/blob/master/info/refs" }

        it "returns not found" do
          expect(response).to have_http_status(404)
        end
      end
    end
  end

  describe "User with LDAP identity" do
    let(:user) { create(:omniauth_user, extern_uid: dn) }
    let(:dn) { 'uid=john,ou=people,dc=example,dc=com' }

    before do
      allow(Gitlab::LDAP::Config).to receive(:enabled?).and_return(true)
      allow(Gitlab::LDAP::Authentication).to receive(:login).and_return(nil)
      allow(Gitlab::LDAP::Authentication).to receive(:login).with(user.username, user.password).and_return(user)
    end

    context "when authentication fails" do
      context "when no authentication is provided" do
        it "responds with status 401" do
          download('doesnt/exist.git') do |response|
            expect(response).to have_http_status(401)
          end
        end
      end

      context "when username and invalid password are provided" do
        it "responds with status 401" do
          download('doesnt/exist.git', user: user.username, password: "nope") do |response|
            expect(response).to have_http_status(401)
          end
        end
      end
    end

    context "when authentication succeeds" do
      context "when the project doesn't exist" do
        it "responds with status 404" do
          download('/doesnt/exist.git', user: user.username, password: user.password) do |response|
            expect(response).to have_http_status(404)
          end
        end
      end

      context "when the project exists" do
        let(:project) { create(:project, path: 'project.git-project') }

        before do
          project.team << [user, :master]
        end

        it "responds with status 200" do
          clone_get(path, user: user.username, password: user.password) do |response|
            expect(response).to have_http_status(200)
          end
        end
      end
    end
  end
end
