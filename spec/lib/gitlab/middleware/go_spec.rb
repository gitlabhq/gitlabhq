# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Middleware::Go, feature_category: :source_code_management do
  let(:app) { double(:app) }
  let(:middleware) { described_class.new(app) }
  let(:instance_host) { 'localhost' }
  let(:instance_url) { "http://#{instance_host}" }
  let(:env) do
    {
      'rack.input' => '',
      'REQUEST_METHOD' => 'GET'
    }
  end

  before do
    stub_config_setting(url: instance_url)
    stub_config_setting(host: instance_host)
  end

  describe '#call' do
    describe 'when go-get=0' do
      before do
        env['QUERY_STRING'] = 'go-get=0'
      end

      it 'skips go-import generation' do
        expect(app).to receive(:call).with(env).and_return('no-go')
        middleware.call(env)
      end
    end

    describe 'when go-get=1' do
      before do
        env['QUERY_STRING'] = 'go-get=1'
        env['PATH_INFO'] = "/#{path}"
      end

      shared_examples 'go-get=1' do |enabled_protocol:|
        context 'with simple 2-segment project path' do
          let!(:project) { create(:project, :public, :repository) }

          context 'with subpackages' do
            let(:path) { "#{project.full_path}/subpackage" }

            it 'returns the full project path', :unlimited_max_formatted_output_length do
              expect_response_with_path(go, enabled_protocol, project.full_path)
            end
          end

          context 'without subpackages' do
            let(:path) { project.full_path }

            context 'when the project is public' do
              it 'returns the full project path' do
                expect_response_with_path(go, enabled_protocol, project.full_path)
              end
            end

            context 'when a custom url is set' do
              let(:instance_url) { "http://#{instance_host}/gitlab" }

              it 'returns the full project path' do
                expect_response_with_path(go, enabled_protocol, project.full_path, url_based: true)
              end
            end

            context 'when the project is private' do
              before do
                project.update_attribute(:visibility_level, Project::PRIVATE)
              end

              context 'when authorization header is not present' do
                it 'returns the 2-segment path' do
                  expect_response_with_path(go, enabled_protocol, project.full_path)
                end

                context 'when instance does not allow password authentication for Git over HTTP(S)' do
                  before do
                    stub_application_setting(password_authentication_enabled_for_git: false)
                  end

                  it 'returns the 2-segment path' do
                    expect_response_with_path(go, enabled_protocol, project.full_path)
                  end
                end
              end

              context 'when authorization header is present but invalid' do
                before do
                  env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Basic.encode_credentials('invalid', 'invalid')
                end

                it 'returns 404' do
                  expect_404_response(go)
                end
              end

              context 'when authenticated' do
                let(:current_user) { project.creator }
                let(:personal_access_token) { create(:personal_access_token, user: current_user) }

                before do
                  env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Basic.encode_credentials(current_user.username, personal_access_token.token)
                end

                context 'when the project accessed by a redirect' do
                  let!(:redirect_route) { create(:redirect_route, source: project, path: 'redirect/project') }

                  it 'returns the full project path' do
                    expect_response_with_path(go, enabled_protocol, project.full_path)
                  end
                end
              end
            end
          end
        end

        context 'with a nested project path' do
          let(:group) { create(:group, :nested) }
          let!(:project) { create(:project, :public, :repository, namespace: group) }

          shared_examples 'a nested project' do
            context 'when the project is public' do
              it 'returns the full project path' do
                expect_response_with_path(go, enabled_protocol, project.full_path)
              end
            end

            context 'when the project is private' do
              before do
                project.update_attribute(:visibility_level, Project::PRIVATE)
              end

              context 'when invalid authentication header exists' do
                before do
                  env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Basic.encode_credentials('invalid', 'invalid')
                end

                it 'returns 404' do
                  expect_404_response(go)
                end
              end

              shared_examples 'when authenticated' do
                let(:current_user) { project.creator }

                before do
                  project.team.add_maintainer(current_user)
                end

                context 'with access to the project' do
                  it 'returns the full project path' do
                    expect_response_with_path(go, enabled_protocol, project.full_path)
                  end
                end

                context 'without access to the project', :sidekiq_inline do
                  before do
                    project.team.find_member(current_user).destroy!
                  end

                  it 'returns 404' do
                    expect_404_response(go)
                  end
                end

                context 'with user is blocked' do
                  before do
                    current_user.block
                  end

                  it 'returns 404' do
                    expect_404_response(go)
                  end
                end
              end

              context 'using basic auth' do
                let(:current_user) { project.creator }

                context 'using a personal access token' do
                  let(:personal_access_token) { create(:personal_access_token, user: current_user) }

                  before do
                    env['REMOTE_ADDR'] = "192.168.0.1"
                    env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Basic.encode_credentials(current_user.username, personal_access_token.token)
                  end

                  context 'with api scope' do
                    it_behaves_like 'when authenticated'
                  end

                  context 'with read_user scope' do
                    before do
                      personal_access_token.update_attribute(:scopes, [:read_user])
                    end

                    it 'returns 404' do
                      expect_404_response(go)
                    end
                  end

                  context 'with a denylisted ip' do
                    let(:request) { ActionDispatch::Request.new(env) }
                    let(:attributes) do
                      {
                        message: 'Rack_Attack',
                        status: 403,
                        env: :blocklist,
                        remote_ip: env['REMOTE_ADDR'],
                        request_method: request.request_method,
                        path: request.filtered_path
                      }
                    end

                    it 'returns forbidden', :aggregate_failures do
                      err = Gitlab::Auth::IpBlocked.new
                      expect(Gitlab::Auth).to receive(:find_for_git_client).and_raise(err)
                      expect(Gitlab::AuthLogger).to receive(:error).with(attributes)

                      response = go

                      expect(response[0]).to eq(403)
                      expect(response[2]).to eq([err.message])
                    end
                  end
                end

                context 'when a personal access token is missing' do
                  before do
                    env['REMOTE_ADDR'] = '192.168.0.1'
                    env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Basic.encode_credentials(current_user.username, 'dummy_password')
                  end

                  it 'returns 404' do
                    expect(Gitlab::Auth).to receive(:find_for_git_client).and_raise(Gitlab::Auth::MissingPersonalAccessTokenError)

                    expect_404_response(go)
                  end
                end
              end
            end
          end

          context 'with subpackages' do
            let(:path) { "#{project.full_path}/subpackage" }

            it_behaves_like 'a nested project'
          end

          context 'with a subpackage that is not a valid project path' do
            let(:path) { "#{project.full_path}/---subpackage" }

            it_behaves_like 'a nested project'
          end

          context 'without subpackages' do
            let(:path) { project.full_path }

            it_behaves_like 'a nested project'
          end
        end

        context 'with a bogus path' do
          let(:path) { "http:;url=http:&sol;&sol;www.example.com'http-equiv='refresh'x='?go-get=1" }

          it 'returns 404' do
            expect_404_response(go)
          end
        end

        context 'with a public project without a repository' do
          let!(:project) { create(:project, :public) }
          let(:path) { project.full_path }

          it 'returns 404' do
            expect_404_response(go)
          end
        end
      end

      context 'with SSH disabled' do
        before do
          stub_application_setting(enabled_git_access_protocol: 'http')
        end

        include_examples 'go-get=1', enabled_protocol: :http
      end

      context 'with HTTP disabled' do
        before do
          stub_application_setting(enabled_git_access_protocol: 'ssh')
        end

        include_examples 'go-get=1', enabled_protocol: :ssh
      end

      context 'with nothing disabled' do
        before do
          stub_application_setting(enabled_git_access_protocol: nil)
        end

        include_examples 'go-get=1', enabled_protocol: nil
      end

      context 'with nothing disabled (blank string)' do
        before do
          stub_application_setting(enabled_git_access_protocol: '')
        end

        include_examples 'go-get=1', enabled_protocol: nil
      end
    end

    def go
      middleware.call(env)
    end

    def expect_404_response(response)
      expect(response[2]).to start_with([/Go package not found or access denied/])
      expect(response[1]['Content-Type']).to eq('text/plain')
      expect(response[0]).to eq(404)
    end

    def expect_response_with_path(response, protocol, path, url_based: false)
      root_url = url_based ? Gitlab.config.gitlab.url.gsub(%r{\Ahttps?://}, '') : Gitlab.config.gitlab.host

      repository_url = case protocol
                       when :ssh
                         shell = Gitlab.config.gitlab_shell
                         "ssh://#{shell.ssh_user}@#{shell.ssh_host}/#{path}.git"
                       else
                         "http://#{root_url}/#{path}.git"
                       end

      expect(response[0]).to eq(200)
      expect(response[1]['Content-Type']).to eq('text/html')
      expected_body = %(<html><head><meta name="go-import" content="#{root_url}/#{path} git #{repository_url}"></head><body>go get #{root_url}/#{path}</body></html>)
      expect(response[2]).to eq([expected_body])
    end
  end
end
