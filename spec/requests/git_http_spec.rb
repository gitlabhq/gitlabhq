require "spec_helper"

describe 'Git HTTP requests', lib: true do
  let(:user)    { create(:user) }
  let(:project) { create(:project, path: 'project.git-project') }

  it "gives WWW-Authenticate hints" do
    clone_get('doesnt/exist.git')

    expect(response.header['WWW-Authenticate']).to start_with('Basic ')
  end

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
              end

              it "uploads get status 200" do
                upload(path, env) do |response|
                  expect(response).to have_http_status(200)
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
              end

              it "uploads get status 401 (no project existence information leak)" do
                push_get "#{project.path_with_namespace}.git", user: 'oauth2', password: @token.token

                expect(response).to have_http_status(401)
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
        let(:token) { 123 }
        let(:project) { FactoryGirl.create :empty_project }

        before do
          project.update_attributes(runners_token: token, builds_enabled: true)
        end

        it "downloads get status 200" do
          clone_get "#{project.path_with_namespace}.git", user: 'gitlab-ci-token', password: token

          expect(response).to have_http_status(200)
        end

        it "uploads get status 401 (no project existence information leak)" do
          push_get "#{project.path_with_namespace}.git", user: 'gitlab-ci-token', password: token

          expect(response).to have_http_status(401)
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
        before { get path, params }

        it "redirects to the sign-in page" do
          expect(response).to redirect_to(new_user_session_path)
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
        allow_any_instance_of(Repository).to receive(:blob_at).with('5937ac0a7beb003549fc5fd26fc247adbce4a52e', 'info/refs') do
          Gitlab::Git::Blob.find(project.repository, 'master', '.gitignore')
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

  def clone_get(project, options = {})
    get "/#{project}/info/refs", { service: 'git-upload-pack' }, auth_env(*options.values_at(:user, :password, :spnego_request_token))
  end

  def clone_post(project, options = {})
    post "/#{project}/git-upload-pack", {}, auth_env(*options.values_at(:user, :password, :spnego_request_token))
  end

  def push_get(project, options = {})
    get "/#{project}/info/refs", { service: 'git-receive-pack' }, auth_env(*options.values_at(:user, :password, :spnego_request_token))
  end

  def push_post(project, options = {})
    post "/#{project}/git-receive-pack", {}, auth_env(*options.values_at(:user, :password, :spnego_request_token))
  end

  def download(project, user: nil, password: nil, spnego_request_token: nil)
    args = [project, { user: user, password: password, spnego_request_token: spnego_request_token }]

    clone_get(*args)
    yield response

    clone_post(*args)
    yield response
  end

  def upload(project, user: nil, password: nil, spnego_request_token: nil)
    args = [project, { user: user, password: password, spnego_request_token: spnego_request_token }]

    push_get(*args)
    yield response

    push_post(*args)
    yield response
  end

  def auth_env(user, password, spnego_request_token)
    env = {}
    if user && password
      env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Basic.encode_credentials(user, password)
    elsif spnego_request_token
      env['HTTP_AUTHORIZATION'] = "Negotiate #{::Base64.strict_encode64('opaque_request_token')}"
    end

    env
  end
end
