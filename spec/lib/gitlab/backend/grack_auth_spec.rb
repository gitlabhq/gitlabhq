require "spec_helper"

describe Grack::Auth do
  let(:user)    { create(:user) }
  let(:project) { create(:project) }

  let(:app)   { lambda { |env| [200, {}, "Success!"] } }
  let!(:auth) { Grack::Auth.new(app) }
  let(:env) do
    {
      'rack.input'     => '',
      'REQUEST_METHOD' => 'GET',
      'QUERY_STRING'   => 'service=git-upload-pack'
    }
  end
  let(:status) { auth.call(env).first }

  describe "#call" do
    context "when the project doesn't exist" do
      before do
        env["PATH_INFO"] = "doesnt/exist.git"
      end

      context "when no authentication is provided" do
        it "responds with status 401" do
          expect(status).to eq(401)
        end
      end

      context "when username and password are provided" do
        context "when authentication fails" do
          before do
            env["HTTP_AUTHORIZATION"] = ActionController::HttpAuthentication::Basic.encode_credentials(user.username, "nope")
          end

          it "responds with status 401" do
            expect(status).to eq(401)
          end
        end

        context "when authentication succeeds" do
          before do
            env["HTTP_AUTHORIZATION"] = ActionController::HttpAuthentication::Basic.encode_credentials(user.username, user.password)
          end

          it "responds with status 404" do
            expect(status).to eq(404)
          end
        end
      end
    end

    context "when the project exists" do
      before do
        env["PATH_INFO"] = project.path_with_namespace + ".git"
      end

      context "when the project is public" do
        before do
          project.update_attribute(:visibility_level, Project::PUBLIC)
        end

        it "responds with status 200" do
          expect(status).to eq(200)
        end
      end

      context "when the project is private" do
        before do
          project.update_attribute(:visibility_level, Project::PRIVATE)
        end

        context "when no authentication is provided" do
          it "responds with status 401" do
            expect(status).to eq(401)
          end
        end

        context "when username and password are provided" do
          context "when authentication fails" do
            before do
              env["HTTP_AUTHORIZATION"] = ActionController::HttpAuthentication::Basic.encode_credentials(user.username, "nope")
            end

            it "responds with status 401" do
              expect(status).to eq(401)
            end

            context "when the user is IP banned" do
              before do
                expect(Rack::Attack::Allow2Ban).to receive(:filter).and_return(true)
                allow_any_instance_of(Rack::Request).to receive(:ip).and_return('1.2.3.4')
              end

              it "responds with status 401" do
                expect(status).to eq(401)
              end
            end
          end

          context "when authentication succeeds" do
            before do
              env["HTTP_AUTHORIZATION"] = ActionController::HttpAuthentication::Basic.encode_credentials(user.username, user.password)
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
                  expect(status).to eq(404)
                end
              end

              context "when the user isn't blocked" do
                before do
                  expect(Rack::Attack::Allow2Ban).to receive(:reset)
                end

                it "responds with status 200" do
                  expect(status).to eq(200)
                end
              end

              context "when blank password attempts follow a valid login" do
                let(:options) { Gitlab.config.rack_attack.git_basic_auth }
                let(:maxretry) { options[:maxretry] - 1 }
                let(:ip) { '1.2.3.4' }

                before do
                  allow_any_instance_of(Rack::Request).to receive(:ip).and_return(ip)
                  Rack::Attack::Allow2Ban.reset(ip, options)
                end

                after do
                  Rack::Attack::Allow2Ban.reset(ip, options)
                end

                def attempt_login(include_password)
                  password = include_password ? user.password : ""
                  env["HTTP_AUTHORIZATION"] = ActionController::HttpAuthentication::Basic.encode_credentials(user.username, password)
                  Grack::Auth.new(app)
                  auth.call(env).first
                end

                it "repeated attempts followed by successful attempt" do
                  for n in 0..maxretry do
                    expect(attempt_login(false)).to eq(401)
                  end

                  expect(attempt_login(true)).to eq(200)
                  expect(Rack::Attack::Allow2Ban.banned?(ip)).to be_falsey

                  for n in 0..maxretry do
                    expect(attempt_login(false)).to eq(401)
                  end
                end
              end
            end

            context "when the user doesn't have access to the project" do
              it "responds with status 404" do
                expect(status).to eq(404)
              end
            end
          end
        end

        context "when a gitlab ci token is provided" do
          let(:token) { "123" }

          before do
            gitlab_ci_service = project.build_gitlab_ci_service
            gitlab_ci_service.active = true
            gitlab_ci_service.token = token
            gitlab_ci_service.save

            env["HTTP_AUTHORIZATION"] = ActionController::HttpAuthentication::Basic.encode_credentials("gitlab-ci-token", token)
          end

          it "responds with status 200" do
            expect(status).to eq(200)
          end
        end
      end
    end
  end
end
