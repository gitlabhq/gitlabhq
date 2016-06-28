require "spec_helper"

describe Grack::Auth, lib: true do
  let(:user)    { create(:user) }
  let(:project) { create(:project) }

  let(:app)   { lambda { |env| [200, {}, "Success!"] } }
  let(:env) do
    {
      'rack.input'     => '',
      'REQUEST_METHOD' => 'GET',
      'QUERY_STRING'   => 'service=git-upload-pack'
    }
  end
  let(:status) { Grack::AuthSpawner::call(env).first }

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

    context "when the Wiki for a project exists" do
      before do
        @wiki = ProjectWiki.new(project)
        env["PATH_INFO"] = "#{@wiki.repository.path_with_namespace}.git/info/refs"
        project.update_attribute(:visibility_level, Project::PUBLIC)
      end

      it "responds with the right project" do
        response = Grack::AuthSpawner::call(env)
        json_body = ActiveSupport::JSON.decode(response[2][0])

        expect(response.first).to eq(200)
        expect(json_body['RepoPath']).to include(@wiki.repository.path_with_namespace)
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

        context "when Kerberos token is provided" do
          before do
            allow_any_instance_of(Grack::Auth).to receive(:allow_kerberos_auth?).and_return(true)
            env["HTTP_AUTHORIZATION"] = "Negotiate #{::Base64.strict_encode64('opaque_request_token')}"
          end

          shared_examples "RFC4559 compliance" do
            it "complies with RFC4559" do
              allow_any_instance_of(Grack::Auth::Request).to receive(:spnego_response_token).and_return("opaque_response_token")

              headers = Grack::AuthSpawner::call(env)[1]
              expect(headers['WWW-Authenticate'].split("\n")).to include("Negotiate #{::Base64.strict_encode64('opaque_response_token')}")
            end
          end

          context "when authentication fails because of invalid Kerberos token" do
            before do
              allow_any_instance_of(Grack::Auth::Request).to receive(:spnego_credentials!).and_return(nil)
            end

            it "responds with status 401" do
              expect(status).to eq(401)
            end
          end

          context "when authentication fails because of unknown Kerberos identity" do
            before do
              allow_any_instance_of(Grack::Auth::Request).to receive(:spnego_credentials!).and_return("mylogin@FOO.COM")
            end

            it "responds with status 401" do
              expect(status).to eq(401)
            end

          end

          context "when authentication succeeds" do
            before do
              allow_any_instance_of(Grack::Auth::Request).to receive(:spnego_credentials!).and_return("mylogin@FOO.COM")
              user.identities.build(provider: "kerberos", extern_uid:"mylogin@FOO.COM").save
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
                it "responds with status 200" do
                  expect(status).to eq(200)
                end
              end

              include_examples "RFC4559 compliance"
            end

            context "when the user doesn't have access to the project" do
              it "responds with status 404" do
                expect(status).to eq(404)
              end

              include_examples "RFC4559 compliance"
            end
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
                  Grack::AuthSpawner::call(env).first
                end

                it "repeated attempts followed by successful attempt" do
                  maxretry.times.each do
                    expect(attempt_login(false)).to eq(401)
                  end

                  expect(attempt_login(true)).to eq(200)
                  expect(Rack::Attack::Allow2Ban.banned?(ip)).to be_falsey

                  maxretry.times.each do
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
          let(:project) { FactoryGirl.create :empty_project }

          before do
            project.update_attributes(runners_token: token, builds_enabled: true)

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
