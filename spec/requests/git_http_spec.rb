# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Git HTTP requests' do
  include ProjectForksHelper
  include TermsHelper
  include GitHttpHelpers
  include WorkhorseHelpers

  shared_examples 'pulls require Basic HTTP Authentication' do
    context "when no credentials are provided" do
      it "responds to downloads with status 401 Unauthorized (no project existence information leak)" do
        download(path) do |response|
          expect(response).to have_gitlab_http_status(:unauthorized)
          expect(response.header['WWW-Authenticate']).to start_with('Basic ')
        end
      end
    end

    context "when only username is provided" do
      it "responds to downloads with status 401 Unauthorized" do
        download(path, user: user.username) do |response|
          expect(response).to have_gitlab_http_status(:unauthorized)
          expect(response.header['WWW-Authenticate']).to start_with('Basic ')
        end
      end
    end

    context "when username and password are provided" do
      context "when authentication fails" do
        it "responds to downloads with status 401 Unauthorized" do
          download(path, user: user.username, password: "wrong-password") do |response|
            expect(response).to have_gitlab_http_status(:unauthorized)
            expect(response.header['WWW-Authenticate']).to start_with('Basic ')
          end
        end

        context "when user is blocked" do
          let(:user) { create(:user, :blocked) }

          it "responds to downloads with status 401 Unauthorized" do
            download(path, user: user.username, password: user.password) do |response|
              expect(response).to have_gitlab_http_status(:unauthorized)
            end
          end
        end
      end

      context "when authentication succeeds" do
        it "does not respond to downloads with status 401 Unauthorized" do
          download(path, user: user.username, password: user.password) do |response|
            expect(response).not_to have_gitlab_http_status(:unauthorized)
            expect(response.header['WWW-Authenticate']).to be_nil
          end
        end
      end
    end
  end

  shared_examples 'operations are not allowed with expired password' do
    context "when password is expired" do
      it "responds to downloads with status 401 Unauthorized" do
        user.update!(password_expires_at: 2.days.ago, password_automatically_set: true)

        download(path, user: user.username, password: user.password) do |response|
          expect(response).to have_gitlab_http_status(:unauthorized)
        end
      end

      it "responds to uploads with status 401 Unauthorized" do
        user.update!(password_expires_at: 2.days.ago, password_automatically_set: true)

        upload(path, user: user.username, password: user.password) do |response|
          expect(response).to have_gitlab_http_status(:unauthorized)
        end
      end
    end
  end

  shared_examples 'pushes require Basic HTTP Authentication' do
    context "when no credentials are provided" do
      it "responds to uploads with status 401 Unauthorized (no project existence information leak)" do
        upload(path) do |response|
          expect(response).to have_gitlab_http_status(:unauthorized)
          expect(response.header['WWW-Authenticate']).to start_with('Basic ')
        end
      end
    end

    context "when only username is provided" do
      it "responds to uploads with status 401 Unauthorized" do
        upload(path, user: user.username) do |response|
          expect(response).to have_gitlab_http_status(:unauthorized)
          expect(response.header['WWW-Authenticate']).to start_with('Basic ')
        end
      end
    end

    context "when username and password are provided" do
      context "when authentication fails" do
        it "responds to uploads with status 401 Unauthorized" do
          upload(path, user: user.username, password: "wrong-password") do |response|
            expect(response).to have_gitlab_http_status(:unauthorized)
            expect(response.header['WWW-Authenticate']).to start_with('Basic ')
          end
        end
      end

      context "when authentication succeeds" do
        it "does not respond to uploads with status 401 Unauthorized" do
          upload(path, user: user.username, password: user.password) do |response|
            expect(response).not_to have_gitlab_http_status(:unauthorized)
            expect(response.header['WWW-Authenticate']).to be_nil
          end
        end
      end
    end
  end

  shared_examples_for 'pulls are allowed' do
    it 'allows pulls' do
      download(path, **env) do |response|
        expect(response).to have_gitlab_http_status(:ok)
        expect(response.media_type).to eq(Gitlab::Workhorse::INTERNAL_API_CONTENT_TYPE)
      end
    end
  end

  shared_examples_for 'pushes are allowed' do
    it 'allows pushes', :sidekiq_might_not_need_inline do
      upload(path, **env) do |response|
        expect(response).to have_gitlab_http_status(:ok)
        expect(response.media_type).to eq(Gitlab::Workhorse::INTERNAL_API_CONTENT_TYPE)
      end
    end
  end

  shared_examples_for 'project path without .git suffix' do
    context "GET info/refs" do
      let(:path) { "/#{repository_path}/info/refs" }

      context "when no params are added" do
        before do
          get path
        end

        it "redirects to the .git suffix version" do
          expect(response).to redirect_to("/#{repository_path}.git/info/refs")
        end
      end

      context "when the upload-pack service is requested" do
        let(:params) { { service: 'git-upload-pack' } }

        before do
          get path, params: params
        end

        it "redirects to the .git suffix version" do
          expect(response).to redirect_to("/#{repository_path}.git/info/refs?service=#{params[:service]}")
        end
      end

      context "when the receive-pack service is requested" do
        let(:params) { { service: 'git-receive-pack' } }

        before do
          get path, params: params
        end

        it "redirects to the .git suffix version" do
          expect(response).to redirect_to("/#{repository_path}.git/info/refs?service=#{params[:service]}")
        end
      end

      context "when the params are anything else" do
        let(:params) { { service: 'git-implode-pack' } }

        before do
          get path, params: params
        end

        it "redirects to the sign-in page" do
          expect(response).to redirect_to(new_user_session_path)
        end
      end
    end

    context "POST git-upload-pack" do
      it "fails to find a route" do
        clone_post(repository_path) do |response|
          expect(response).to have_gitlab_http_status(:not_found)
        end
      end
    end

    context "POST git-receive-pack" do
      it "fails to find a route" do
        push_post(repository_path) do |response|
          expect(response).to have_gitlab_http_status(:not_found)
        end
      end
    end
  end

  describe "User with no identities" do
    let(:user) { create(:user) }

    context "when the project doesn't exist" do
      context "when namespace doesn't exist" do
        let(:path) { 'doesnt/exist.git' }

        it_behaves_like 'pulls require Basic HTTP Authentication'
        it_behaves_like 'pushes require Basic HTTP Authentication'
        it_behaves_like 'operations are not allowed with expired password'

        context 'when authenticated' do
          it 'rejects downloads and uploads with 404 Not Found' do
            download_or_upload(path, user: user.username, password: user.password) do |response|
              expect(response).to have_gitlab_http_status(:not_found)
            end
          end
        end
      end

      context 'when namespace exists' do
        let(:path) { "#{user.namespace.path}/new-project.git"}

        context 'when authenticated' do
          it 'creates a new project under the existing namespace' do
            expect do
              upload(path, user: user.username, password: user.password) do |response|
                expect(response).to have_gitlab_http_status(:ok)
              end
            end.to change { user.projects.count }.by(1)
          end

          it 'rejects push with 422 Unprocessable Entity when project is invalid' do
            path = "#{user.namespace.path}/new.git"

            push_get(path, user: user.username, password: user.password)

            expect(response).to have_gitlab_http_status(:unprocessable_entity)
          end
        end

        it_behaves_like 'project path without .git suffix' do
          let(:repository_path) { "#{user.namespace.path}/project.git-project" }
        end
      end
    end

    context "when requesting the Wiki" do
      let(:wiki) { ProjectWiki.new(project) }
      let(:path) { "/#{wiki.repository.full_path}.git" }

      context "when the project is public" do
        let(:project) { create(:project, :wiki_repo, :public, :wiki_enabled) }

        it_behaves_like 'pushes require Basic HTTP Authentication'

        context 'when unauthenticated' do
          let(:env) { {} }

          it_behaves_like 'pulls are allowed'

          it "responds to pulls with the wiki's repo" do
            download(path) do |response|
              json_body = ActiveSupport::JSON.decode(response.body)

              expect(json_body['Repository']['relative_path']).to eq(wiki.repository.relative_path)
            end
          end
        end

        context 'when authenticated' do
          let(:env) { { user: user.username, password: user.password } }

          context 'and as a developer on the team' do
            before do
              project.add_developer(user)
            end

            context 'but the repo is disabled' do
              let(:project) { create(:project, :wiki_repo, :public, :repository_disabled, :wiki_enabled) }

              it_behaves_like 'pulls are allowed'
              it_behaves_like 'pushes are allowed'
            end
          end

          context 'and not on the team' do
            it_behaves_like 'pulls are allowed'

            it 'rejects pushes with 403 Forbidden' do
              upload(path, **env) do |response|
                expect(response).to have_gitlab_http_status(:forbidden)
                expect(response.body).to eq(git_access_wiki_error(:write_to_wiki))
              end
            end
          end
        end
      end

      context "when the project is private" do
        let(:project) { create(:project, :wiki_repo, :private, :wiki_enabled) }

        it_behaves_like 'pulls require Basic HTTP Authentication'
        it_behaves_like 'pushes require Basic HTTP Authentication'
        it_behaves_like 'operations are not allowed with expired password'

        context 'when authenticated' do
          context 'and as a developer on the team' do
            before do
              project.add_developer(user)
            end

            context 'when user is using credentials with special characters' do
              context 'with password with special characters' do
                before do
                  user.update!(password: 'RKszEwéC5kFnû∆f243fycGu§Gh9ftDj!U')
                end

                it 'allows clones' do
                  download(path, user: user.username, password: user.password) do |response|
                    expect(response).to have_gitlab_http_status(:ok)
                  end
                end
              end
            end

            context 'but the repo is disabled' do
              let(:project) { create(:project, :wiki_repo, :private, :repository_disabled, :wiki_enabled) }

              it 'allows clones' do
                download(path, user: user.username, password: user.password) do |response|
                  expect(response).to have_gitlab_http_status(:ok)
                end
              end

              it 'pushes are allowed' do
                upload(path, user: user.username, password: user.password) do |response|
                  expect(response).to have_gitlab_http_status(:ok)
                end
              end
            end
          end

          context 'and not on the team' do
            it 'rejects clones with 404 Not Found' do
              download(path, user: user.username, password: user.password) do |response|
                expect(response).to have_gitlab_http_status(:not_found)
                expect(response.body).to eq(git_access_wiki_error(:not_found))
              end
            end

            it 'rejects pushes with 404 Not Found' do
              upload(path, user: user.username, password: user.password) do |response|
                expect(response).to have_gitlab_http_status(:not_found)
                expect(response.body).to eq(git_access_wiki_error(:not_found))
              end
            end
          end
        end
      end
    end

    context "when the project exists" do
      let(:path) { "#{project.full_path}.git" }

      context "when the project is public" do
        let(:project) { create(:project, :repository, :public) }

        it_behaves_like 'pushes require Basic HTTP Authentication'

        context 'when not authenticated' do
          let(:env) { {} }

          it_behaves_like 'pulls are allowed'
        end

        context "when authenticated" do
          let(:env) { { user: user.username, password: user.password } }

          context 'as a developer on the team' do
            before do
              project.add_developer(user)
            end

            it_behaves_like 'pulls are allowed'
            it_behaves_like 'pushes are allowed'

            context 'but git-receive-pack over HTTP is disabled in config' do
              before do
                allow(Gitlab.config.gitlab_shell).to receive(:receive_pack).and_return(false)
              end

              it 'rejects pushes with 403 Forbidden' do
                upload(path, **env) do |response|
                  expect(response).to have_gitlab_http_status(:forbidden)
                  expect(response.body).to eq(git_access_error(:receive_pack_disabled_over_http))
                end
              end
            end

            context 'but git-upload-pack over HTTP is disabled in config' do
              it "rejects pushes with 403 Forbidden" do
                allow(Gitlab.config.gitlab_shell).to receive(:upload_pack).and_return(false)

                download(path, **env) do |response|
                  expect(response).to have_gitlab_http_status(:forbidden)
                  expect(response.body).to eq(git_access_error(:upload_pack_disabled_over_http))
                end
              end
            end

            context 'but the service parameter is missing' do
              it 'rejects clones with 403 Forbidden' do
                get("/#{path}/info/refs", headers: auth_env(*env.values_at(:user, :password), nil))

                expect(response).to have_gitlab_http_status(:forbidden)
              end
            end
          end

          context 'and not a member of the team' do
            it_behaves_like 'pulls are allowed'

            it 'rejects pushes with 403 Forbidden' do
              upload(path, **env) do |response|
                expect(response).to have_gitlab_http_status(:forbidden)
                expect(response.body).to eq('You are not allowed to push code to this project.')
              end
            end

            context 'when merge requests are open that allow maintainer access' do
              let(:canonical_project) { create(:project, :public, :repository) }
              let(:project) { fork_project(canonical_project, nil, repository: true) }

              before do
                canonical_project.add_maintainer(user)
                create(:merge_request,
                       source_project: project,
                       target_project:  canonical_project,
                       source_branch: 'fixes',
                       allow_collaboration: true)
              end

              it_behaves_like 'pushes are allowed'
            end

            context 'but the service parameter is missing' do
              it 'rejects clones with 401 Unauthorized' do
                get("/#{path}/info/refs")

                expect(response).to have_gitlab_http_status(:unauthorized)
              end
            end
          end
        end

        context 'when the request is not from gitlab-workhorse' do
          it 'raises an exception' do
            expect do
              get("/#{project.full_path}.git/info/refs?service=git-upload-pack")
            end.to raise_error(JWT::DecodeError)
          end
        end

        context 'when the repo is public' do
          context 'but the repo is disabled' do
            let(:project) { create(:project, :public, :repository, :repository_disabled) }
            let(:path) { "#{project.full_path}.git" }
            let(:env) { {} }

            it_behaves_like 'pulls require Basic HTTP Authentication'
            it_behaves_like 'pushes require Basic HTTP Authentication'
            it_behaves_like 'operations are not allowed with expired password'
          end

          context 'but the repo is enabled' do
            let(:project) { create(:project, :public, :repository, :repository_enabled) }
            let(:path) { "#{project.full_path}.git" }
            let(:env) { {} }

            it_behaves_like 'pulls are allowed'
          end

          context 'but only project members are allowed' do
            let(:project) { create(:project, :public, :repository, :repository_private) }

            it_behaves_like 'pulls require Basic HTTP Authentication'
            it_behaves_like 'pushes require Basic HTTP Authentication'
            it_behaves_like 'operations are not allowed with expired password'
          end
        end

        context 'and the user requests a redirected path' do
          let!(:redirect) { project.route.create_redirect('foo/bar') }
          let(:path) { "#{redirect.path}.git" }

          it 'downloads get status 200 for redirects' do
            clone_get(path)

            expect(response).to have_gitlab_http_status(:ok)
          end
        end
      end

      context "when the project is private" do
        let(:project) { create(:project, :repository, :private) }

        it_behaves_like 'pulls require Basic HTTP Authentication'
        it_behaves_like 'pushes require Basic HTTP Authentication'
        it_behaves_like 'operations are not allowed with expired password'

        context "when username and password are provided" do
          let(:env) { { user: user.username, password: 'nope' } }

          context "when authentication fails" do
            context "when the user is IP banned" do
              before do
                stub_rack_attack_setting(enabled: true, ip_whitelist: [])
              end

              it "responds with status 403" do
                expect(Rack::Attack::Allow2Ban).to receive(:banned?).and_return(true)
                expect(Gitlab::AuthLogger).to receive(:error).with({
                  message: 'Rack_Attack',
                  env: :blocklist,
                  remote_ip: '127.0.0.1',
                  request_method: 'GET',
                  path: "/#{path}/info/refs?service=git-upload-pack"
                })

                clone_get(path, **env)

                expect(response).to have_gitlab_http_status(:forbidden)
              end
            end
          end

          context "when authentication succeeds" do
            let(:env) { { user: user.username, password: user.password } }

            context "when the user has access to the project" do
              before do
                project.add_maintainer(user)
              end

              context "when the user is blocked" do
                it "rejects pulls with 401 Unauthorized" do
                  user.block
                  project.add_maintainer(user)

                  download(path, **env) do |response|
                    expect(response).to have_gitlab_http_status(:unauthorized)
                  end
                end

                it "rejects pulls with 401 Unauthorized for unknown projects (no project existence information leak)" do
                  user.block

                  download('doesnt/exist.git', **env) do |response|
                    expect(response).to have_gitlab_http_status(:unauthorized)
                  end
                end
              end

              context "when the user isn't blocked" do
                before do
                  stub_rack_attack_setting(enabled: true, bantime: 1.minute, findtime: 5.minutes, maxretry: 2, ip_whitelist: [])
                end

                it "resets the IP in Rack Attack on download" do
                  expect(Rack::Attack::Allow2Ban).to receive(:reset).twice

                  download(path, **env) do
                    expect(response).to have_gitlab_http_status(:ok)
                    expect(response.media_type).to eq(Gitlab::Workhorse::INTERNAL_API_CONTENT_TYPE)
                  end
                end

                it "resets the IP in Rack Attack on upload" do
                  expect(Rack::Attack::Allow2Ban).to receive(:reset).twice

                  upload(path, **env) do
                    expect(response).to have_gitlab_http_status(:ok)
                    expect(response.media_type).to eq(Gitlab::Workhorse::INTERNAL_API_CONTENT_TYPE)
                  end
                end

                it 'updates the user last activity', :clean_gitlab_redis_shared_state do
                  expect(user.last_activity_on).to be_nil

                  download(path, **env) do |response|
                    expect(user.reload.last_activity_on).to eql(Date.today)
                  end
                end
              end

              context "when an oauth token is provided" do
                before do
                  application = Doorkeeper::Application.create!(name: "MyApp", redirect_uri: "https://app.com", owner: user)
                  @token = Doorkeeper::AccessToken.create!(application_id: application.id, resource_owner_id: user.id, scopes: "api")
                end

                let(:path) { "#{project.full_path}.git" }
                let(:env) { { user: 'oauth2', password: @token.token } }

                it_behaves_like 'pulls are allowed'
                it_behaves_like 'pushes are allowed'

                context "when password is expired" do
                  it "responds to downloads with status 401 unauthorized" do
                    user.update!(password_expires_at: 2.days.ago, password_automatically_set: true)

                    download(path, **env) do |response|
                      expect(response).to have_gitlab_http_status(:unauthorized)
                    end
                  end
                end
              end

              context 'when user has 2FA enabled' do
                let(:user) { create(:user, :two_factor) }
                let(:access_token) { create(:personal_access_token, user: user) }
                let(:path) { "#{project.full_path}.git" }

                before do
                  project.add_maintainer(user)
                end

                context 'when username and password are provided' do
                  it 'rejects pulls with personal access token error message' do
                    download(path, user: user.username, password: user.password) do |response|
                      expect(response).to have_gitlab_http_status(:unauthorized)
                      expect(response.body).to include('You must use a personal access token with \'read_repository\' or \'write_repository\' scope for Git over HTTP')
                    end
                  end

                  it 'rejects the push attempt with personal access token error message' do
                    upload(path, user: user.username, password: user.password) do |response|
                      expect(response).to have_gitlab_http_status(:unauthorized)
                      expect(response.body).to include('You must use a personal access token with \'read_repository\' or \'write_repository\' scope for Git over HTTP')
                    end
                  end
                end

                context 'when username and personal access token are provided' do
                  let(:env) { { user: user.username, password: access_token.token } }

                  it_behaves_like 'pulls are allowed'
                  it_behaves_like 'pushes are allowed'

                  it 'rejects the push attempt for read_repository scope' do
                    read_access_token = create(:personal_access_token, user: user, scopes: [:read_repository])

                    upload(path, user: user.username, password: read_access_token.token) do |response|
                      expect(response).to have_gitlab_http_status(:forbidden)
                      expect(response.body).to include('You are not allowed to upload code')
                    end
                  end

                  it 'accepts the push attempt for write_repository scope' do
                    write_access_token = create(:personal_access_token, user: user, scopes: [:write_repository])

                    upload(path, user: user.username, password: write_access_token.token) do |response|
                      expect(response).to have_gitlab_http_status(:ok)
                    end
                  end

                  it 'accepts the pull attempt for read_repository scope' do
                    read_access_token = create(:personal_access_token, user: user, scopes: [:read_repository])

                    download(path, user: user.username, password: read_access_token.token) do |response|
                      expect(response).to have_gitlab_http_status(:ok)
                    end
                  end

                  it 'accepts the pull attempt for api scope' do
                    read_access_token = create(:personal_access_token, user: user, scopes: [:api])

                    download(path, user: user.username, password: read_access_token.token) do |response|
                      expect(response).to have_gitlab_http_status(:ok)
                    end
                  end

                  it 'accepts the push attempt for api scope' do
                    write_access_token = create(:personal_access_token, user: user, scopes: [:api])

                    upload(path, user: user.username, password: write_access_token.token) do |response|
                      expect(response).to have_gitlab_http_status(:ok)
                    end
                  end

                  context "when password is expired" do
                    it "responds to uploads with status 401 unauthorized" do
                      user.update!(password_expires_at: 2.days.ago, password_automatically_set: true)

                      write_access_token = create(:personal_access_token, user: user, scopes: [:write_repository])

                      upload(path, user: user.username, password: write_access_token.token) do |response|
                        expect(response).to have_gitlab_http_status(:unauthorized)
                      end
                    end
                  end
                end
              end

              context 'when internal auth is disabled' do
                before do
                  allow_any_instance_of(ApplicationSetting).to receive(:password_authentication_enabled_for_git?) { false }
                end

                it 'rejects pulls with personal access token error message' do
                  download(path, user: 'foo', password: 'bar') do |response|
                    expect(response).to have_gitlab_http_status(:unauthorized)
                    expect(response.body).to include('You must use a personal access token with \'read_repository\' or \'write_repository\' scope for Git over HTTP')
                  end
                end

                it 'rejects pushes with personal access token error message' do
                  upload(path, user: 'foo', password: 'bar') do |response|
                    expect(response).to have_gitlab_http_status(:unauthorized)
                    expect(response.body).to include('You must use a personal access token with \'read_repository\' or \'write_repository\' scope for Git over HTTP')
                  end
                end

                context 'when LDAP is configured' do
                  before do
                    allow(Gitlab::Auth::Ldap::Config).to receive(:enabled?).and_return(true)
                    allow_any_instance_of(Gitlab::Auth::Ldap::Authentication)
                      .to receive(:login).and_return(nil)
                  end

                  it 'does not display the personal access token error message' do
                    upload(path, user: 'foo', password: 'bar') do |response|
                      expect(response).to have_gitlab_http_status(:unauthorized)
                      expect(response.body).not_to include('You must use a personal access token with \'read_repository\' or \'write_repository\' scope for Git over HTTP')
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

                include_context 'rack attack cache store'

                it "repeated attempts followed by successful attempt" do
                  options = Gitlab.config.rack_attack.git_basic_auth
                  maxretry = options[:maxretry]
                  ip = '1.2.3.4'

                  allow_any_instance_of(ActionDispatch::Request).to receive(:ip).and_return(ip)
                  Rack::Attack::Allow2Ban.reset(ip, options)

                  maxretry.times.each do
                    expect(attempt_login(false)).to eq(401)
                  end

                  expect(attempt_login(true)).to eq(200)
                  expect(Rack::Attack::Allow2Ban.banned?(ip)).to be_falsey
                end
              end

              context 'and the user requests a redirected path' do
                let!(:redirect) { project.route.create_redirect('foo/bar') }
                let(:path) { "#{redirect.path}.git" }
                let(:project_moved_message) do
                  <<-MSG.strip_heredoc
                    Project '#{redirect.path}' was moved to '#{project.full_path}'.

                    Please update your Git remote:

                      git remote set-url origin #{project.http_url_to_repo}.
                  MSG
                end

                it 'downloads get status 200' do
                  clone_get(path, **env)

                  expect(response).to have_gitlab_http_status(:ok)
                end

                it 'uploads get status 404 with "project was moved" message' do
                  upload(path, **env) do |response|
                    expect(response).to have_gitlab_http_status(:ok)
                  end
                end
              end
            end

            context "when the user doesn't have access to the project" do
              it "pulls get status 404" do
                download(path, user: user.username, password: user.password) do |response|
                  expect(response).to have_gitlab_http_status(:not_found)
                end
              end

              it "uploads get status 404" do
                upload(path, user: user.username, password: user.password) do |response|
                  expect(response).to have_gitlab_http_status(:not_found)
                end
              end
            end
          end
        end

        context "when a gitlab ci token is provided" do
          let(:project) { create(:project, :repository) }
          let(:build) { create(:ci_build, :running) }
          let(:other_project) { create(:project, :repository) }

          before do
            build.update!(project: project) # can't associate it on factory create
          end

          context 'when build created by system is authenticated' do
            let(:path) { "#{project.full_path}.git" }
            let(:env) { { user: 'gitlab-ci-token', password: build.token } }

            it_behaves_like 'pulls are allowed'

            # A non-401 here is not an information leak since the system is
            # "authenticated" as CI using the correct token. It does not have
            # push access, so pushes should be rejected as forbidden, and giving
            # a reason is fine.
            #
            # We know for sure it is not an information leak since pulls using
            # the build token must be allowed.
            it "rejects pushes with 403 Forbidden" do
              push_get(path, **env)

              expect(response).to have_gitlab_http_status(:forbidden)
              expect(response.body).to eq(git_access_error(:auth_upload))
            end

            # We are "authenticated" as CI using a valid token here. But we are
            # not authorized to see any other project, so return "not found".
            it "rejects pulls for other project with 404 Not Found" do
              clone_get("#{other_project.full_path}.git", **env)

              expect(response).to have_gitlab_http_status(:not_found)
              expect(response.body).to eq(git_access_error(:project_not_found))
            end
          end

          context 'and build created by' do
            before do
              build.update!(user: user)
              project.add_reporter(user)
            end

            shared_examples 'can download code only' do
              let(:path) { "#{project.full_path}.git" }
              let(:env) { { user: 'gitlab-ci-token', password: build.token } }

              it_behaves_like 'pulls are allowed'

              context 'when the repo does not exist' do
                let(:project) { create(:project) }

                it 'rejects pulls with 404 Not Found' do
                  clone_get(path, **env)

                  expect(response).to have_gitlab_http_status(:not_found)
                  expect(response.body).to eq(git_access_error(:no_repo))
                end
              end

              it 'rejects pushes with 403 Forbidden' do
                push_get(path, **env)

                expect(response).to have_gitlab_http_status(:forbidden)
                expect(response.body).to eq(git_access_error(:auth_upload))
              end
            end

            context 'administrator' do
              let(:user) { create(:admin) }

              context 'when admin mode is enabled', :enable_admin_mode do
                it_behaves_like 'can download code only'

                it 'downloads from other project get status 403' do
                  clone_get "#{other_project.full_path}.git", user: 'gitlab-ci-token', password: build.token

                  expect(response).to have_gitlab_http_status(:forbidden)
                end
              end

              context 'when admin mode is disabled' do
                it_behaves_like 'can download code only'

                it 'downloads from other project get status 404' do
                  clone_get "#{other_project.full_path}.git", user: 'gitlab-ci-token', password: build.token

                  expect(response).to have_gitlab_http_status(:not_found)
                end
              end
            end

            context 'regular user' do
              let(:user) { create(:user) }

              it_behaves_like 'can download code only'

              it 'downloads from other project get status 404' do
                clone_get "#{other_project.full_path}.git", user: 'gitlab-ci-token', password: build.token

                expect(response).to have_gitlab_http_status(:not_found)
              end

              context 'when users password is expired' do
                it 'rejects pulls with 401 unauthorized' do
                  user.update!(password_expires_at: 2.days.ago, password_automatically_set: true)

                  download(path, user: 'gitlab-ci-token', password: build.token) do |response|
                    expect(response).to have_gitlab_http_status(:unauthorized)
                  end
                end
              end
            end
          end
        end
      end

      it_behaves_like 'project path without .git suffix' do
        let(:repository_path) { create(:project, :repository, :public, path: 'project.git-project').full_path }
      end

      context "retrieving an info/refs file" do
        let(:project) { create(:project, :repository, :public) }

        context "when the file exists" do
          before do
            # Provide a dummy file in its place
            allow_any_instance_of(Repository).to receive(:blob_at).and_call_original
            allow_any_instance_of(Repository).to receive(:blob_at).with('b83d6e391c22777fca1ed3012fce84f633d7fed0', 'info/refs') do
              Blob.decorate(Gitlab::Git::Blob.find(project.repository, 'master', 'bar/branch-test.txt'), project)
            end

            get "/#{project.full_path}/-/blob/master/info/refs"
          end

          it "returns the file" do
            expect(response).to have_gitlab_http_status(:ok)
          end
        end

        context "when the file does not exist" do
          before do
            get "/#{project.full_path}/-/blob/master/info/refs"
          end

          it "redirects" do
            expect(response).to have_gitlab_http_status(:found)
          end
        end
      end
    end

    context "when the project path ends with a dot" do
      let(:path) { "#{project.full_path}.git" }

      context "when the project is public" do
        let(:project) { create(:project, :repository, :public, path: 'foo.') }

        it_behaves_like 'pushes require Basic HTTP Authentication'

        context 'when not authenticated' do
          let(:env) { {} }

          it_behaves_like 'pulls are allowed'
        end

        context "when authenticated" do
          let(:env) { { user: user.username, password: user.password } }

          context 'as a developer on the team' do
            before do
              project.add_developer(user)
            end

            it_behaves_like 'pulls are allowed'
            it_behaves_like 'pushes are allowed'

            context 'but git-receive-pack over HTTP is disabled in config' do
              before do
                allow(Gitlab.config.gitlab_shell).to receive(:receive_pack).and_return(false)
              end

              it 'rejects pushes with 403 Forbidden' do
                upload(path, **env) do |response|
                  expect(response).to have_gitlab_http_status(:forbidden)
                  expect(response.body).to eq(git_access_error(:receive_pack_disabled_over_http))
                end
              end
            end

            context 'but git-upload-pack over HTTP is disabled in config' do
              it "rejects pushes with 403 Forbidden" do
                allow(Gitlab.config.gitlab_shell).to receive(:upload_pack).and_return(false)

                download(path, **env) do |response|
                  expect(response).to have_gitlab_http_status(:forbidden)
                  expect(response.body).to eq(git_access_error(:upload_pack_disabled_over_http))
                end
              end
            end

            context 'but the service parameter is missing' do
              it 'rejects clones with 403 Forbidden' do
                get("/#{path}/info/refs", headers: auth_env(*env.values_at(:user, :password), nil))

                expect(response).to have_gitlab_http_status(:forbidden)
              end
            end
          end

          context 'and not a member of the team' do
            it_behaves_like 'pulls are allowed'

            it 'rejects pushes with 403 Forbidden' do
              upload(path, **env) do |response|
                expect(response).to have_gitlab_http_status(:forbidden)
                expect(response.body).to eq('You are not allowed to push code to this project.')
              end
            end

            context 'when merge requests are open that allow maintainer access' do
              let(:canonical_project) { create(:project, :public, :repository) }
              let(:project) { fork_project(canonical_project, nil, repository: true) }

              before do
                canonical_project.add_maintainer(user)
                create(:merge_request,
                       source_project: project,
                       target_project:  canonical_project,
                       source_branch: 'fixes',
                       allow_collaboration: true)
              end

              it_behaves_like 'pushes are allowed'
            end

            context 'but the service parameter is missing' do
              it 'rejects clones with 401 Unauthorized' do
                get("/#{path}/info/refs")

                expect(response).to have_gitlab_http_status(:unauthorized)
              end
            end
          end
        end

        context 'when the request is not from gitlab-workhorse' do
          it 'raises an exception' do
            expect do
              get("/#{project.full_path}.git/info/refs?service=git-upload-pack")
            end.to raise_error(JWT::DecodeError)
          end
        end

        context 'when the repo is public' do
          context 'but the repo is disabled' do
            let(:project) { create(:project, :public, :repository, :repository_disabled) }
            let(:path) { "#{project.full_path}.git" }
            let(:env) { {} }

            it_behaves_like 'pulls require Basic HTTP Authentication'
            it_behaves_like 'pushes require Basic HTTP Authentication'
            it_behaves_like 'operations are not allowed with expired password'
          end

          context 'but the repo is enabled' do
            let(:project) { create(:project, :public, :repository, :repository_enabled) }
            let(:path) { "#{project.full_path}.git" }
            let(:env) { {} }

            it_behaves_like 'pulls are allowed'
          end

          context 'but only project members are allowed' do
            let(:project) { create(:project, :public, :repository, :repository_private) }

            it_behaves_like 'pulls require Basic HTTP Authentication'
            it_behaves_like 'pushes require Basic HTTP Authentication'
            it_behaves_like 'operations are not allowed with expired password'
          end
        end

        context 'and the user requests a redirected path' do
          let!(:redirect) { project.route.create_redirect('foo/bar') }
          let(:path) { "#{redirect.path}.git" }

          it 'downloads get status 200 for redirects' do
            clone_get(path)

            expect(response).to have_gitlab_http_status(:ok)
          end
        end
      end

      context "when the project is private" do
        let(:project) { create(:project, :repository, :private, path: 'foo.') }

        it_behaves_like 'pulls require Basic HTTP Authentication'
        it_behaves_like 'pushes require Basic HTTP Authentication'
        it_behaves_like 'operations are not allowed with expired password'

        context "when username and password are provided" do
          let(:env) { { user: user.username, password: 'nope' } }

          context "when authentication fails" do
            context "when the user is IP banned" do
              before do
                stub_rack_attack_setting(enabled: true, ip_whitelist: [])
              end

              it "responds with status 403" do
                expect(Rack::Attack::Allow2Ban).to receive(:banned?).and_return(true)
                expect(Gitlab::AuthLogger).to receive(:error).with({
                  message: 'Rack_Attack',
                  env: :blocklist,
                  remote_ip: '127.0.0.1',
                  request_method: 'GET',
                  path: "/#{path}/info/refs?service=git-upload-pack"
                })

                clone_get(path, **env)

                expect(response).to have_gitlab_http_status(:forbidden)
              end
            end
          end

          context "when authentication succeeds" do
            let(:env) { { user: user.username, password: user.password } }

            context "when the user has access to the project" do
              before do
                project.add_maintainer(user)
              end

              context "when the user is blocked" do
                it "rejects pulls with 401 Unauthorized" do
                  user.block
                  project.add_maintainer(user)

                  download(path, **env) do |response|
                    expect(response).to have_gitlab_http_status(:unauthorized)
                  end
                end

                it "rejects pulls with 401 Unauthorized for unknown projects (no project existence information leak)" do
                  user.block

                  download('doesnt/exist.git', **env) do |response|
                    expect(response).to have_gitlab_http_status(:unauthorized)
                  end
                end
              end

              context "when the user isn't blocked" do
                before do
                  stub_rack_attack_setting(enabled: true, bantime: 1.minute, findtime: 5.minutes, maxretry: 2, ip_whitelist: [])
                end

                it "resets the IP in Rack Attack on download" do
                  expect(Rack::Attack::Allow2Ban).to receive(:reset).twice

                  download(path, **env) do
                    expect(response).to have_gitlab_http_status(:ok)
                    expect(response.media_type).to eq(Gitlab::Workhorse::INTERNAL_API_CONTENT_TYPE)
                  end
                end

                it "resets the IP in Rack Attack on upload" do
                  expect(Rack::Attack::Allow2Ban).to receive(:reset).twice

                  upload(path, **env) do
                    expect(response).to have_gitlab_http_status(:ok)
                    expect(response.media_type).to eq(Gitlab::Workhorse::INTERNAL_API_CONTENT_TYPE)
                  end
                end

                it 'updates the user last activity', :clean_gitlab_redis_shared_state do
                  expect(user.last_activity_on).to be_nil

                  download(path, **env) do |response|
                    expect(user.reload.last_activity_on).to eql(Date.today)
                  end
                end
              end

              context "when an oauth token is provided" do
                before do
                  application = Doorkeeper::Application.create!(name: "MyApp", redirect_uri: "https://app.com", owner: user)
                  @token = Doorkeeper::AccessToken.create!(application_id: application.id, resource_owner_id: user.id, scopes: "api")
                end

                let(:path) { "#{project.full_path}.git" }
                let(:env) { { user: 'oauth2', password: @token.token } }

                it_behaves_like 'pulls are allowed'
                it_behaves_like 'pushes are allowed'

                context "when password is expired" do
                  it "responds to downloads with status 401 unauthorized" do
                    user.update!(password_expires_at: 2.days.ago, password_automatically_set: true)

                    download(path, **env) do |response|
                      expect(response).to have_gitlab_http_status(:unauthorized)
                    end
                  end
                end
              end

              context 'when user has 2FA enabled' do
                let(:user) { create(:user, :two_factor) }
                let(:access_token) { create(:personal_access_token, user: user) }
                let(:path) { "#{project.full_path}.git" }

                before do
                  project.add_maintainer(user)
                end

                context 'when username and password are provided' do
                  it 'rejects pulls with personal access token error message' do
                    download(path, user: user.username, password: user.password) do |response|
                      expect(response).to have_gitlab_http_status(:unauthorized)
                      expect(response.body).to include('You must use a personal access token with \'read_repository\' or \'write_repository\' scope for Git over HTTP')
                    end
                  end

                  it 'rejects the push attempt with personal access token error message' do
                    upload(path, user: user.username, password: user.password) do |response|
                      expect(response).to have_gitlab_http_status(:unauthorized)
                      expect(response.body).to include('You must use a personal access token with \'read_repository\' or \'write_repository\' scope for Git over HTTP')
                    end
                  end
                end

                context 'when username and personal access token are provided' do
                  let(:env) { { user: user.username, password: access_token.token } }

                  it_behaves_like 'pulls are allowed'
                  it_behaves_like 'pushes are allowed'

                  it 'rejects the push attempt for read_repository scope' do
                    read_access_token = create(:personal_access_token, user: user, scopes: [:read_repository])

                    upload(path, user: user.username, password: read_access_token.token) do |response|
                      expect(response).to have_gitlab_http_status(:forbidden)
                      expect(response.body).to include('You are not allowed to upload code')
                    end
                  end

                  it 'accepts the push attempt for write_repository scope' do
                    write_access_token = create(:personal_access_token, user: user, scopes: [:write_repository])

                    upload(path, user: user.username, password: write_access_token.token) do |response|
                      expect(response).to have_gitlab_http_status(:ok)
                    end
                  end

                  it 'accepts the pull attempt for read_repository scope' do
                    read_access_token = create(:personal_access_token, user: user, scopes: [:read_repository])

                    download(path, user: user.username, password: read_access_token.token) do |response|
                      expect(response).to have_gitlab_http_status(:ok)
                    end
                  end

                  it 'accepts the pull attempt for api scope' do
                    read_access_token = create(:personal_access_token, user: user, scopes: [:api])

                    download(path, user: user.username, password: read_access_token.token) do |response|
                      expect(response).to have_gitlab_http_status(:ok)
                    end
                  end

                  it 'accepts the push attempt for api scope' do
                    write_access_token = create(:personal_access_token, user: user, scopes: [:api])

                    upload(path, user: user.username, password: write_access_token.token) do |response|
                      expect(response).to have_gitlab_http_status(:ok)
                    end
                  end

                  context "when password is expired" do
                    it "responds to uploads with status 401 unauthorized" do
                      user.update!(password_expires_at: 2.days.ago, password_automatically_set: true)

                      write_access_token = create(:personal_access_token, user: user, scopes: [:write_repository])

                      upload(path, user: user.username, password: write_access_token.token) do |response|
                        expect(response).to have_gitlab_http_status(:unauthorized)
                      end
                    end
                  end
                end
              end

              context 'when internal auth is disabled' do
                before do
                  allow_any_instance_of(ApplicationSetting).to receive(:password_authentication_enabled_for_git?) { false }
                end

                it 'rejects pulls with personal access token error message' do
                  download(path, user: 'foo', password: 'bar') do |response|
                    expect(response).to have_gitlab_http_status(:unauthorized)
                    expect(response.body).to include('You must use a personal access token with \'read_repository\' or \'write_repository\' scope for Git over HTTP')
                  end
                end

                it 'rejects pushes with personal access token error message' do
                  upload(path, user: 'foo', password: 'bar') do |response|
                    expect(response).to have_gitlab_http_status(:unauthorized)
                    expect(response.body).to include('You must use a personal access token with \'read_repository\' or \'write_repository\' scope for Git over HTTP')
                  end
                end

                context 'when LDAP is configured' do
                  before do
                    allow(Gitlab::Auth::Ldap::Config).to receive(:enabled?).and_return(true)
                    allow_any_instance_of(Gitlab::Auth::Ldap::Authentication)
                      .to receive(:login).and_return(nil)
                  end

                  it 'does not display the personal access token error message' do
                    upload(path, user: 'foo', password: 'bar') do |response|
                      expect(response).to have_gitlab_http_status(:unauthorized)
                      expect(response.body).not_to include('You must use a personal access token with \'read_repository\' or \'write_repository\' scope for Git over HTTP')
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

                include_context 'rack attack cache store'

                it "repeated attempts followed by successful attempt" do
                  options = Gitlab.config.rack_attack.git_basic_auth
                  maxretry = options[:maxretry]
                  ip = '1.2.3.4'

                  allow_any_instance_of(ActionDispatch::Request).to receive(:ip).and_return(ip)
                  Rack::Attack::Allow2Ban.reset(ip, options)

                  maxretry.times.each do
                    expect(attempt_login(false)).to eq(401)
                  end

                  expect(attempt_login(true)).to eq(200)
                  expect(Rack::Attack::Allow2Ban.banned?(ip)).to be_falsey
                end
              end

              context 'and the user requests a redirected path' do
                let!(:redirect) { project.route.create_redirect('foo/bar') }
                let(:path) { "#{redirect.path}.git" }
                let(:project_moved_message) do
                  <<-MSG.strip_heredoc
                    Project '#{redirect.path}' was moved to '#{project.full_path}'.

                    Please update your Git remote:

                      git remote set-url origin #{project.http_url_to_repo}.
                  MSG
                end

                it 'downloads get status 200' do
                  clone_get(path, **env)

                  expect(response).to have_gitlab_http_status(:ok)
                end

                it 'uploads get status 404 with "project was moved" message' do
                  upload(path, **env) do |response|
                    expect(response).to have_gitlab_http_status(:ok)
                  end
                end
              end
            end

            context "when the user doesn't have access to the project" do
              it "pulls get status 404" do
                download(path, user: user.username, password: user.password) do |response|
                  expect(response).to have_gitlab_http_status(:not_found)
                end
              end

              it "uploads get status 404" do
                upload(path, user: user.username, password: user.password) do |response|
                  expect(response).to have_gitlab_http_status(:not_found)
                end
              end
            end
          end
        end

        context "when a gitlab ci token is provided" do
          let(:project) { create(:project, :repository) }
          let(:build) { create(:ci_build, :running) }
          let(:other_project) { create(:project, :repository) }

          before do
            build.update!(project: project) # can't associate it on factory create
          end

          context 'when build created by system is authenticated' do
            let(:path) { "#{project.full_path}.git" }
            let(:env) { { user: 'gitlab-ci-token', password: build.token } }

            it_behaves_like 'pulls are allowed'

            # A non-401 here is not an information leak since the system is
            # "authenticated" as CI using the correct token. It does not have
            # push access, so pushes should be rejected as forbidden, and giving
            # a reason is fine.
            #
            # We know for sure it is not an information leak since pulls using
            # the build token must be allowed.
            it "rejects pushes with 403 Forbidden" do
              push_get(path, **env)

              expect(response).to have_gitlab_http_status(:forbidden)
              expect(response.body).to eq(git_access_error(:auth_upload))
            end

            # We are "authenticated" as CI using a valid token here. But we are
            # not authorized to see any other project, so return "not found".
            it "rejects pulls for other project with 404 Not Found" do
              clone_get("#{other_project.full_path}.git", **env)

              expect(response).to have_gitlab_http_status(:not_found)
              expect(response.body).to eq(git_access_error(:project_not_found))
            end
          end

          context 'and build created by' do
            before do
              build.update!(user: user)
              project.add_reporter(user)
            end

            shared_examples 'can download code only' do
              let(:path) { "#{project.full_path}.git" }
              let(:env) { { user: 'gitlab-ci-token', password: build.token } }

              it_behaves_like 'pulls are allowed'

              context 'when the repo does not exist' do
                let(:project) { create(:project) }

                it 'rejects pulls with 404 Not Found' do
                  clone_get(path, **env)

                  expect(response).to have_gitlab_http_status(:not_found)
                  expect(response.body).to eq(git_access_error(:no_repo))
                end
              end

              it 'rejects pushes with 403 Forbidden' do
                push_get(path, **env)

                expect(response).to have_gitlab_http_status(:forbidden)
                expect(response.body).to eq(git_access_error(:auth_upload))
              end
            end

            context 'administrator' do
              let(:user) { create(:admin) }

              context 'when admin mode is enabled', :enable_admin_mode do
                it_behaves_like 'can download code only'

                it 'downloads from other project get status 403' do
                  clone_get "#{other_project.full_path}.git", user: 'gitlab-ci-token', password: build.token

                  expect(response).to have_gitlab_http_status(:forbidden)
                end
              end

              context 'when admin mode is disabled' do
                it_behaves_like 'can download code only'

                it 'downloads from other project get status 404' do
                  clone_get "#{other_project.full_path}.git", user: 'gitlab-ci-token', password: build.token

                  expect(response).to have_gitlab_http_status(:not_found)
                end
              end
            end

            context 'regular user' do
              let(:user) { create(:user) }

              it_behaves_like 'can download code only'

              it 'downloads from other project get status 404' do
                clone_get "#{other_project.full_path}.git", user: 'gitlab-ci-token', password: build.token

                expect(response).to have_gitlab_http_status(:not_found)
              end

              context 'when users password is expired' do
                it 'rejects pulls with 401 unauthorized' do
                  user.update!(password_expires_at: 2.days.ago, password_automatically_set: true)

                  download(path, user: 'gitlab-ci-token', password: build.token) do |response|
                    expect(response).to have_gitlab_http_status(:unauthorized)
                  end
                end
              end
            end
          end
        end
      end

      it_behaves_like 'project path without .git suffix' do
        let(:repository_path) { create(:project, :repository, :public, path: 'project.').full_path }
      end

      context "retrieving an info/refs file" do
        let(:project) { create(:project, :repository, :public, path: 'project.') }

        context "when the file exists" do
          before do
            # Provide a dummy file in its place
            allow_any_instance_of(Repository).to receive(:blob_at).and_call_original
            allow_any_instance_of(Repository).to receive(:blob_at).with('b83d6e391c22777fca1ed3012fce84f633d7fed0', 'info/refs') do
              Blob.decorate(Gitlab::Git::Blob.find(project.repository, 'master', 'bar/branch-test.txt'), project)
            end

            get "/#{project.full_path}/-/blob/master/info/refs"
          end

          it "returns the file" do
            expect(response).to have_gitlab_http_status(:ok)
          end
        end

        context "when the file does not exist" do
          before do
            get "/#{project.full_path}/-/blob/master/info/refs"
          end

          it "redirects" do
            expect(response).to have_gitlab_http_status(:found)
          end
        end
      end
    end

    context "when the Wiki path ends with a dot" do
      let(:wiki) { ProjectWiki.new(project) }
      let(:path) { "/#{wiki.repository.full_path}.git" }

      context "when the project is public" do
        let(:project) { create(:project, :wiki_repo, :public, :wiki_enabled, path: 'foo.') }

        it_behaves_like 'pushes require Basic HTTP Authentication'

        context 'when unauthenticated' do
          let(:env) { {} }

          it_behaves_like 'pulls are allowed'

          it "responds to pulls with the wiki's repo" do
            download(path) do |response|
              json_body = ActiveSupport::JSON.decode(response.body)

              expect(json_body['Repository']['relative_path']).to eq(wiki.repository.relative_path)
            end
          end
        end

        context 'when authenticated' do
          let(:env) { { user: user.username, password: user.password } }

          context 'and as a developer on the team' do
            before do
              project.add_developer(user)
            end

            context 'but the repo is disabled' do
              let(:project) { create(:project, :wiki_repo, :public, :repository_disabled, :wiki_enabled, path: 'foo.') }

              it_behaves_like 'pulls are allowed'
              it_behaves_like 'pushes are allowed'
            end
          end

          context 'and not on the team' do
            it_behaves_like 'pulls are allowed'

            it 'rejects pushes with 403 Forbidden' do
              upload(path, **env) do |response|
                expect(response).to have_gitlab_http_status(:forbidden)
                expect(response.body).to eq(git_access_wiki_error(:write_to_wiki))
              end
            end
          end
        end
      end

      context "when the project is private" do
        let(:project) { create(:project, :wiki_repo, :private, :wiki_enabled, path: 'foo.') }

        it_behaves_like 'pulls require Basic HTTP Authentication'
        it_behaves_like 'pushes require Basic HTTP Authentication'
        it_behaves_like 'operations are not allowed with expired password'

        context 'when authenticated' do
          context 'and as a developer on the team' do
            before do
              project.add_developer(user)
            end

            context 'when user is using credentials with special characters' do
              context 'with password with special characters' do
                before do
                  user.update!(password: 'RKszEwéC5kFnû∆f243fycGu§Gh9ftDj!U')
                end

                it 'allows clones' do
                  download(path, user: user.username, password: user.password) do |response|
                    expect(response).to have_gitlab_http_status(:ok)
                  end
                end
              end
            end

            context 'but the repo is disabled' do
              let(:project) { create(:project, :wiki_repo, :private, :repository_disabled, :wiki_enabled, path: 'foo.') }

              it 'allows clones' do
                download(path, user: user.username, password: user.password) do |response|
                  expect(response).to have_gitlab_http_status(:ok)
                end
              end

              it 'pushes are allowed' do
                upload(path, user: user.username, password: user.password) do |response|
                  expect(response).to have_gitlab_http_status(:ok)
                end
              end
            end
          end

          context 'and not on the team' do
            it 'rejects clones with 404 Not Found' do
              download(path, user: user.username, password: user.password) do |response|
                expect(response).to have_gitlab_http_status(:not_found)
                expect(response.body).to eq(git_access_wiki_error(:not_found))
              end
            end

            it 'rejects pushes with 404 Not Found' do
              upload(path, user: user.username, password: user.password) do |response|
                expect(response).to have_gitlab_http_status(:not_found)
                expect(response.body).to eq(git_access_wiki_error(:not_found))
              end
            end
          end
        end
      end
    end
  end

  describe "User with LDAP identity" do
    let(:user) { create(:omniauth_user, extern_uid: dn) }
    let(:dn) { 'uid=john,ou=people,dc=example,dc=com' }
    let(:path) { 'doesnt/exist.git' }

    before do
      allow(Gitlab::Auth::OAuth::Provider).to receive(:enabled?).and_return(true)
      allow_any_instance_of(Gitlab::Auth::Ldap::Authentication).to receive(:login).and_return(nil)
      allow_any_instance_of(Gitlab::Auth::Ldap::Authentication).to receive(:login).with(user.username, user.password).and_return(user)
    end

    it_behaves_like 'pulls require Basic HTTP Authentication'
    it_behaves_like 'pushes require Basic HTTP Authentication'

    context "when authentication succeeds" do
      context "when the project doesn't exist" do
        it "responds with status 404 Not Found" do
          download(path, user: user.username, password: user.password) do |response|
            expect(response).to have_gitlab_http_status(:not_found)
          end
        end
      end

      context "when the project exists" do
        let(:project) { create(:project, :repository) }
        let(:path) { "#{project.full_path}.git" }
        let(:env) { { user: user.username, password: user.password } }

        context 'and the user is on the team' do
          before do
            project.add_maintainer(user)
          end

          it "responds with status 200" do
            clone_get(path, **env) do |response|
              expect(response).to have_gitlab_http_status(:ok)
            end
          end

          it_behaves_like 'pulls are allowed'
          it_behaves_like 'pushes are allowed'

          context "when password is expired" do
            it "responds to downloads with status 200" do
              user.update!(password_expires_at: 2.days.ago)

              download(path, user: user.username, password: user.password) do |response|
                expect(response).to have_gitlab_http_status(:ok)
              end
            end

            it "responds to uploads with status 200" do
              user.update!(password_expires_at: 2.days.ago)

              upload(path, user: user.username, password: user.password) do |response|
                expect(response).to have_gitlab_http_status(:ok)
              end
            end
          end
        end
      end
    end
  end

  context 'when terms are enforced' do
    let(:project) { create(:project, :repository) }
    let(:user) { create(:user) }
    let(:path) { "#{project.full_path}.git" }
    let(:env) { { user: user.username, password: user.password } }

    before do
      project.add_maintainer(user)
      enforce_terms
    end

    it 'blocks git access when the user did not accept terms', :aggregate_failures do
      clone_get(path, **env) do |response|
        expect(response).to have_gitlab_http_status(:forbidden)
      end

      download(path, **env) do |response|
        expect(response).to have_gitlab_http_status(:forbidden)
      end

      upload(path, **env) do |response|
        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end

    context 'when the user accepted the terms' do
      before do
        accept_terms(user)
      end

      it 'allows clones' do
        clone_get(path, **env) do |response|
          expect(response).to have_gitlab_http_status(:ok)
        end
      end

      it_behaves_like 'pulls are allowed'
      it_behaves_like 'pushes are allowed'
    end

    context 'from CI' do
      let(:build) { create(:ci_build, :running) }
      let(:env) { { user: 'gitlab-ci-token', password: build.token } }

      before do
        build.update!(user: user, project: project)
      end

      it_behaves_like 'pulls are allowed'
    end
  end
end
