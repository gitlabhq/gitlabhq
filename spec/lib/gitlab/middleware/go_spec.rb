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
        env['PATH_INFO'] = "/#{path}"
      end

      shared_examples 'go-get=1' do |enabled_protocol:|
        context 'with simple 2-segment project path' do
          let!(:project) { create(:project, :private) }

          context 'with subpackages' do
            let(:path) { "#{project.full_path}/subpackage" }

            it 'returns the full project path' do
              expect_response_with_path(go, enabled_protocol, project.full_path)
            end
          end

          context 'without subpackages' do
            let(:path) { project.full_path }

            it 'returns the full project path' do
              expect_response_with_path(go, enabled_protocol, project.full_path)
            end
          end
        end

        context 'with a nested project path' do
          let(:group) { create(:group, :nested) }
          let!(:project) { create(:project, :public, namespace: group) }

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

              shared_examples 'unauthorized' do
                it 'returns the 2-segment group path' do
                  expect_response_with_path(go, enabled_protocol, group.full_path)
                end
              end

              context 'when not authenticated' do
                it_behaves_like 'unauthorized'
              end

              context 'when authenticated' do
                let(:current_user) { project.creator }

                before do
                  project.team.add_master(current_user)
                end

                shared_examples 'authenticated' do
                  context 'with access to the project' do
                    it 'returns the full project path' do
                      expect_response_with_path(go, enabled_protocol, project.full_path)
                    end
                  end

                  context 'without access to the project' do
                    before do
                      project.team.find_member(current_user).destroy
                    end

                    it_behaves_like 'unauthorized'
                  end
                end

                context 'using warden' do
                  before do
                    env['warden'] = double(authenticate: current_user)
                  end

                  context 'when active' do
                    it_behaves_like 'authenticated'
                  end

                  context 'when blocked' do
                    before do
                      current_user.block!
                    end

                    it_behaves_like 'unauthorized'
                  end
                end

                context 'using a personal access token' do
                  let(:personal_access_token) { create(:personal_access_token, user: current_user) }

                  before do
                    env['HTTP_PRIVATE_TOKEN'] = personal_access_token.token
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

    def expect_response_with_path(response, protocol, path)
      repository_url = case protocol
                       when :ssh
                         "ssh://git@#{Gitlab.config.gitlab.host}/#{path}.git"
                       when :http, nil
                         "http://#{Gitlab.config.gitlab.host}/#{path}.git"
                       end
      expect(response[0]).to eq(200)
      expect(response[1]['Content-Type']).to eq('text/html')
      expected_body = %{<html><head><meta name="go-import" content="#{Gitlab.config.gitlab.host}/#{path} git #{repository_url}" /></head></html>}
      expect(response[2].body).to eq([expected_body])
    end
  end
end
