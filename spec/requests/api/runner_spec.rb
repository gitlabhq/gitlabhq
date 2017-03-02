require 'spec_helper'

describe API::Runner do
  include ApiHelpers
  include StubGitlabCalls

  let(:registration_token) { 'abcdefg123456' }

  before do
    stub_gitlab_calls
    stub_application_setting(runners_registration_token: registration_token)
  end

  describe '/api/v4/runners' do
    describe 'POST /api/v4/runners' do
      context 'when no token is provided' do
        it 'returns 400 error' do
          post api('/runners')
          expect(response).to have_http_status 400
        end
      end

      context 'when invalid token is provided' do
        it 'returns 403 error' do
          post api('/runners'), token: 'invalid'
          expect(response).to have_http_status 403
        end
      end

      context 'when valid token is provided' do
        it 'creates runner with default values' do
          post api('/runners'), token: registration_token

          runner = Ci::Runner.first

          expect(response).to have_http_status 201
          expect(json_response['id']).to eq(runner.id)
          expect(json_response['token']).to eq(runner.token)
          expect(runner.run_untagged).to be true
        end

        context 'when project token is used' do
          let(:project) { create(:empty_project) }

          it 'creates runner' do
            post api('/runners'), token: project.runners_token

            expect(response).to have_http_status 201
            expect(project.runners.size).to eq(1)
          end
        end
      end

      context 'when runner description is provided' do
        it 'creates runner' do
          post api('/runners'), token: registration_token,
                                description: 'server.hostname'

          expect(response).to have_http_status 201
          expect(Ci::Runner.first.description).to eq('server.hostname')
        end
      end

      context 'when runner tags are provided' do
        it 'creates runner' do
          post api('/runners'), token: registration_token,
                                tag_list: 'tag1, tag2'

          expect(response).to have_http_status 201
          expect(Ci::Runner.first.tag_list.sort).to eq(%w(tag1 tag2))
        end
      end

      context 'when option for running untagged jobs is provided' do
        context 'when tags are provided' do
          it 'creates runner' do
            post api('/runners'), token: registration_token,
                                  run_untagged: false,
                                  tag_list: ['tag']

            expect(response).to have_http_status 201
            expect(Ci::Runner.first.run_untagged).to be false
            expect(Ci::Runner.first.tag_list.sort).to eq(['tag'])
          end
        end

        context 'when tags are not provided' do
          it 'returns 404 error' do
            post api('/runners'), token: registration_token,
                                  run_untagged: false

            expect(response).to have_http_status 404
          end
        end
      end

      context 'when option for locking Runner is provided' do
        it 'creates runner' do
          post api('/runners'), token: registration_token,
                                locked: true

          expect(response).to have_http_status 201
          expect(Ci::Runner.first.locked).to be true
        end
      end

      %w(name version revision platform architecture).each do |param|
        context "when info parameter '#{param}' info is present" do
          let(:value) { "#{param}_value" }

          it %q(updates provided Runner's parameter) do
            post api('/runners'), token: registration_token,
                                  info: { param => value }

            expect(response).to have_http_status 201
            expect(Ci::Runner.first.read_attribute(param.to_sym)).to eq(value)
          end
        end
      end
    end

    describe 'DELETE /api/v4/runners' do
      context 'when no token is provided' do
        it 'returns 400 error' do
          delete api('/runners')

          expect(response).to have_http_status 400
        end
      end

      context 'when invalid token is provided' do
        it 'returns 403 error' do
          delete api('/runners'), token: 'invalid'

          expect(response).to have_http_status 403
        end
      end

      context 'when valid token is provided' do
        let(:runner) { create(:ci_runner) }

        it 'deletes Runner' do
          delete api('/runners'), token: runner.token

          expect(response).to have_http_status 204
          expect(Ci::Runner.count).to eq(0)
        end
      end
    end
  end
end
