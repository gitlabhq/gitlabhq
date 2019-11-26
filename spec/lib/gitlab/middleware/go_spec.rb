# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Middleware::Go do
  let(:app) { double(:app) }
  let(:middleware) { described_class.new(app) }
  let(:env) do
    {
      'rack.input' => '',
      'REQUEST_METHOD' => 'GET'
    }
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
        env['PATH_INFO'] = +"/#{path}"
      end

      shared_examples 'go-get=1' do |enabled_protocol:|
        context 'with simple 2-segment project path' do
          let!(:project) { create(:project, :private, :repository) }

          context 'with subpackages' do
            let(:path) { "#{project.full_path}/subpackage" }

            it 'returns the full project path' do
              expect_response_with_path(go, enabled_protocol, project.full_path, project.default_branch)
            end
          end

          context 'without subpackages' do
            let(:path) { project.full_path }

            it 'returns the full project path' do
              expect_response_with_path(go, enabled_protocol, project.full_path, project.default_branch)
            end
          end
        end

        context 'with a nested project path' do
          let(:group) { create(:group, :nested) }
          let!(:project) { create(:project, :public, :repository, namespace: group) }

          shared_examples 'a nested project' do
            context 'when the project is public' do
              it 'returns the full project path' do
                expect_response_with_path(go, enabled_protocol, project.full_path, project.default_branch)
              end
            end

            context 'when the project is private' do
              before do
                project.update_attribute(:visibility_level, Project::PRIVATE)
              end

              shared_examples 'unauthorized' do
                it 'returns the 2-segment group path' do
                  expect_response_with_path(go, enabled_protocol, group.full_path, project.default_branch)
                end
              end

              context 'when not authenticated' do
                it_behaves_like 'unauthorized'
              end

              context 'when authenticated' do
                let(:current_user) { project.creator }

                before do
                  project.team.add_maintainer(current_user)
                end

                shared_examples 'authenticated' do
                  context 'with access to the project' do
                    it 'returns the full project path' do
                      expect_response_with_path(go, enabled_protocol, project.full_path, project.default_branch)
                    end
                  end

                  context 'without access to the project' do
                    before do
                      project.team.find_member(current_user).destroy
                    end

                    it_behaves_like 'unauthorized'
                  end

                  context 'with user is blocked' do
                    before do
                      current_user.block
                    end

                    it_behaves_like 'unauthorized'
                  end
                end

                context 'using basic auth' do
                  context 'using a personal access token' do
                    let(:personal_access_token) { create(:personal_access_token, user: current_user) }

                    before do
                      env['REMOTE_ADDR'] = "192.168.0.1"
                      env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Basic.encode_credentials(current_user.username, personal_access_token.token)
                    end

                    context 'with api scope' do
                      it_behaves_like 'authenticated'
                    end

                    context 'with read_user scope' do
                      before do
                        personal_access_token.update_attribute(:scopes, [:read_user])
                      end

                      it_behaves_like 'unauthorized'
                    end
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

          it 'skips go-import generation' do
            expect(app).to receive(:call).and_return('no-go')

            go
          end
        end

        context 'with a public project without a repository' do
          let!(:project) { create(:project, :public) }
          let(:path) { project.full_path }

          it 'returns 404' do
            response = go
            expect(response[0]).to eq(404)
            expect(response[1]['Content-Type']).to eq('text/html')
            expected_body = %{<html><body>go get #{Gitlab.config.gitlab.url}/#{project.full_path}</body></html>}
            expect(response[2].body).to eq([expected_body])
          end
        end

        context 'with a non-standard head' do
          let(:user) { create(:user) }
          let!(:project) { create(:project, :public, :repository) }
          let(:path) { project.full_path }
          let(:default_branch) { 'default_branch' }

          before do
            project.add_maintainer(user)
            project.repository.add_branch(user, default_branch, 'master')
            project.change_head(default_branch)
          end

          it 'returns the full project path' do
            expect_response_with_path(go, enabled_protocol, project.full_path, default_branch)
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

    def expect_response_with_path(response, protocol, path, branch)
      repository_url = case protocol
                       when :ssh
                         "ssh://#{Gitlab.config.gitlab.user}@#{Gitlab.config.gitlab.host}/#{path}.git"
                       when :http, nil
                         "http://#{Gitlab.config.gitlab.host}/#{path}.git"
                       end
      project_url = "http://#{Gitlab.config.gitlab.host}/#{path}"
      expect(response[0]).to eq(200)
      expect(response[1]['Content-Type']).to eq('text/html')
      expected_body = %{<html><head><meta name="go-import" content="#{Gitlab.config.gitlab.host}/#{path} git #{repository_url}" /><meta name="go-source" content="#{Gitlab.config.gitlab.host}/#{path} #{project_url} #{project_url}/tree/#{branch}{/dir} #{project_url}/blob/#{branch}{/dir}/{file}#L{line}" /></head><body>go get #{Gitlab.config.gitlab.url}/#{path}</body></html>}
      expect(response[2].body).to eq([expected_body])
    end
  end
end
