# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Files, feature_category: :source_code_management do
  include RepoHelpers

  let_it_be(:group) { create(:group, :public) }
  let(:helper) do
    fake_class = Class.new do
      include ::API::Helpers::HeadersHelpers

      attr_reader :headers

      def initialize
        @headers = {}
      end

      def header(key, value)
        @headers[key] = value
      end
    end

    fake_class.new
  end

  let_it_be_with_refind(:user) { create(:user) }
  let_it_be(:inherited_guest) { create(:user, guest_of: group) }
  let_it_be(:inherited_reporter) { create(:user, reporter_of: group) }
  let_it_be(:inherited_developer) { create(:user, developer_of: group) }

  let_it_be_with_reload(:project) { create(:project, :repository, namespace: user.namespace, developers: user) }
  let_it_be_with_reload(:public_project) { create(:project, :public, :repository) }
  let_it_be_with_reload(:private_project) { create(:project, :private, :repository, group: group) }
  let_it_be_with_reload(:public_project_private_repo) { create(:project, :public, :repository, :repository_private, group: group) }

  let_it_be(:guest) { create(:user) { |u| project.add_guest(u) } }
  let(:file_path) { 'files%2Fruby%2Fpopen%2Erb' }
  let(:file_name) { 'popen.rb' }
  let(:last_commit_id) { '570e7b2abdd848b95f2f578043fc23bd6f6fd24d' }
  let(:content_sha256) { 'c440cd09bae50c4632cc58638ad33c6aa375b6109d811e76a9cc3a613c1e8887' }
  let(:executable_file_path) { 'files%2Fexecutables%2Fls' }
  let(:invalid_file_path) { '%2e%2e%2f' }
  let(:absolute_path) { '%2Fetc%2Fpasswd.rb' }
  let(:invalid_file_message) { 'file_path should be a valid file path' }
  let(:params) do
    {
      ref: 'master'
    }
  end

  let(:executable_ref_params) do
    {
      ref: 'with-executables'
    }
  end

  let(:last_commit_for_path) do
    Gitlab::Git::Commit
    .last_for_path(project.repository, 'master', Addressable::URI.unencode_component(file_path))
  end

  shared_context 'with author parameters' do
    let(:author_email) { 'user@example.org' }
    let(:author_name) { 'John Doe' }
  end

  def route(file_path = nil)
    "/projects/#{project.id}/repository/files/#{file_path}"
  end

  def expect_to_send_git_blob(url, params)
    expect(Gitlab::Workhorse).to receive(:send_git_blob)

    get url, params: params

    expect(response).to have_gitlab_http_status(:ok)
    expect(response.parsed_body).to be_empty
  end

  context 'http headers' do
    it 'converts value into string' do
      helper.set_http_headers(test: 1)

      expect(helper.headers).to eq({ 'X-Gitlab-Test' => '1' })
    end

    context 'when value is an Enumerable' do
      it 'raises an exception' do
        expect { helper.set_http_headers(test: [1]) }.to raise_error(ArgumentError)
      end
    end
  end

  shared_examples 'when path is absolute' do
    it 'returns 400 when file path is absolute' do
      subject

      expect(response).to have_gitlab_http_status(:bad_request)

      if response.body.present?
        expect(json_response['error']).to eq(invalid_file_message)
      end
    end
  end

  describe 'HEAD /projects/:id/repository/files/:file_path' do
    shared_examples_for 'repository files' do
      let(:options) { {} }

      it 'returns 400 when file path is invalid' do
        head api(route(invalid_file_path), current_user, **options), params: params

        expect(response).to have_gitlab_http_status(:bad_request)
      end

      it_behaves_like 'when path is absolute' do
        subject { head api(route(absolute_path), current_user, **options), params: params }
      end

      it 'returns file attributes in headers' do
        head api(route(file_path), current_user, **options), params: params

        expect(response).to have_gitlab_http_status(:ok)
        expect(response.headers['X-Gitlab-File-Path']).to eq(CGI.unescape(file_path))
        expect(response.headers['X-Gitlab-File-Name']).to eq(file_name)
        expect(response.headers['X-Gitlab-Last-Commit-Id']).to eq(last_commit_id)
        expect(response.headers['X-Gitlab-Content-Sha256']).to eq(content_sha256)
      end

      it 'caches sha256 of the content', :use_clean_rails_redis_caching do
        head api(route(file_path), current_user, **options), params: params

        expect_next_instance_of(Gitlab::Cache::Client) do |instance|
          expect(instance).to receive(:fetch).with(anything, nil, { cache_identifier: 'API::Files#content_sha', backing_resource: :gitaly }).and_call_original
        end

        expect(Rails.cache.fetch("blob_content_sha256:#{project.full_path}:#{response.headers['X-Gitlab-Blob-Id']}"))
          .to eq(content_sha256)

        expect_next_instance_of(Gitlab::Git::Blob) do |instance|
          expect(instance).not_to receive(:load_all_data!)
        end

        head api(route(file_path), current_user, **options), params: params
      end

      it 'returns file by commit sha' do
        # This file is deleted on HEAD
        file_path = 'files%2Fjs%2Fcommit%2Ejs%2Ecoffee'
        params[:ref] = '6f6d7e7ed97bb5f0054f2b1df789b39ca89b6ff9'

        head api(route(file_path), current_user, **options), params: params

        expect(response).to have_gitlab_http_status(:ok)
        expect(response.headers['X-Gitlab-File-Name']).to eq('commit.js.coffee')
        expect(response.headers['X-Gitlab-Content-Sha256']).to eq('08785f04375b47f81f46e68cc125d5ef368aa20576ddb53f91f4d83f1d04b929')
      end

      context 'when mandatory params are not given' do
        it 'responds with a 400 status' do
          head api(route('any%2Ffile'), current_user, **options)

          expect(response).to have_gitlab_http_status(:bad_request)
        end
      end

      context 'when file_path does not exist' do
        it 'responds with a 404 status' do
          params[:ref] = 'master'

          head api(route('app%2Fmodels%2Fapplication%2Erb'), current_user, **options), params: params

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end

      context 'when file_path does not exist' do
        include_context 'disabled repository'

        it 'responds with a 403 status' do
          head api(route(file_path), current_user, **options), params: params

          expect(response).to have_gitlab_http_status(:forbidden)
        end
      end
    end

    context 'when unauthenticated' do
      context 'and project is public' do
        let(:project) { public_project }

        it_behaves_like 'repository files' do
          let(:current_user) { nil }
        end
      end

      context 'and project is private' do
        it 'responds with a 404 status' do
          current_user = nil

          head api(route(file_path), current_user), params: params

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end
    end

    context 'when PATs are used' do
      it_behaves_like 'repository files' do
        let(:token) { create(:personal_access_token, scopes: ['read_repository'], user: user) }
        let(:current_user) { nil }
        let(:options) { { personal_access_token: token } }
      end
    end

    context 'when authenticated' do
      context 'and user is a developer' do
        it_behaves_like 'repository files' do
          let(:current_user) { user }
        end
      end

      context 'and user is a guest' do
        it_behaves_like '403 response' do
          let(:request) { head api(route(file_path), guest), params: params }
        end
      end
    end
  end

  describe 'GET /projects/:id/repository/files/:file_path' do
    let(:options) { {} }

    shared_examples 'returns non-executable file attributes as json' do
      specify do
        get api(route(file_path), api_user, **options), params: params

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response['file_path']).to eq(CGI.unescape(file_path))
        expect(json_response['file_name']).to eq(file_name)
        expect(json_response['last_commit_id']).to eq(last_commit_id)
        expect(json_response['content_sha256']).to eq(content_sha256)
        expect(json_response['execute_filemode']).to eq(false)
        expect(Base64.decode64(json_response['content']).lines.first).to eq("require 'fileutils'\n")
      end
    end

    shared_examples_for 'repository files' do
      it 'returns 400 for invalid file path' do
        # TODO: remove spec once the feature flag is removed
        # https://gitlab.com/gitlab-org/gitlab/-/issues/415460
        stub_feature_flags(check_path_traversal_middleware_reject_requests: false)

        get api(route(invalid_file_path), api_user, **options), params: params

        expect(response).to have_gitlab_http_status(:bad_request)
        expect(json_response['error']).to eq(invalid_file_message)
      end

      it_behaves_like 'when path is absolute' do
        subject { get api(route(absolute_path), api_user, **options), params: params }
      end

      it_behaves_like 'returns non-executable file attributes as json'

      context 'for executable file' do
        it 'returns file attributes as json' do
          get api(route(executable_file_path), api_user, **options), params: executable_ref_params

          aggregate_failures 'testing response' do
            expect(response).to have_gitlab_http_status(:ok)
            expect(json_response['file_path']).to eq(CGI.unescape(executable_file_path))
            expect(json_response['file_name']).to eq('ls')
            expect(json_response['last_commit_id']).to eq('6b8dc4a827797aa025ff6b8f425e583858a10d4f')
            expect(json_response['content_sha256']).to eq('2c74b1181ef780dfb692c030d3a0df6e0b624135c38a9344e56b9f80007b6191')
            expect(json_response['execute_filemode']).to eq(true)
            expect(Base64.decode64(json_response['content']).lines.first).to eq("#!/bin/sh\n")
          end
        end
      end

      it 'returns json when file has txt extension' do
        file_path = 'bar%2Fbranch-test.txt'

        get api(route(file_path), api_user, **options), params: params

        expect(response).to have_gitlab_http_status(:ok)
        expect(response.media_type).to eq('application/json')
      end

      context 'with filename with pathspec characters' do
        let(:file_path) { ':wq' }
        let(:newrev) { project.repository.commit('master').sha }

        before do
          create_file_in_repo(project, 'master', 'master', file_path, 'Test file')
        end

        it 'returns JSON wth commit SHA' do
          params[:ref] = 'master'

          get api(route(file_path), api_user, **options), params: params

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response['file_path']).to eq(file_path)
          expect(json_response['file_name']).to eq(file_path)
          expect(json_response['last_commit_id']).to eq(newrev)
        end
      end

      it 'returns file by commit sha' do
        # This file is deleted on HEAD
        file_path = 'files%2Fjs%2Fcommit%2Ejs%2Ecoffee'
        params[:ref] = '6f6d7e7ed97bb5f0054f2b1df789b39ca89b6ff9'

        get api(route(file_path), api_user, **options), params: params

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response['file_name']).to eq('commit.js.coffee')
        expect(json_response['content_sha256']).to eq('08785f04375b47f81f46e68cc125d5ef368aa20576ddb53f91f4d83f1d04b929')
        expect(Base64.decode64(json_response['content']).lines.first).to eq("class Commit\n")
      end

      it 'returns raw file info' do
        url = route(file_path) + '/raw'
        expect_to_send_git_blob(api(url, api_user, **options), params)
        expect(headers[Gitlab::Workhorse::DETECT_HEADER]).to eq 'true'
      end

      it 'returns blame file info' do
        url = route(file_path) + '/blame'

        get api(url, api_user, **options), params: params

        expect(response).to have_gitlab_http_status(:ok)
      end

      context 'when a project is moved' do
        let_it_be(:redirect_route) { 'new/project/location' }
        let_it_be(:file_path) { 'files%2Fruby%2Fpopen.rb' }

        it 'redirects to the new project location' do
          project.route.create_redirect(redirect_route)

          url = "/projects/#{CGI.escape(redirect_route)}/repository/files/#{file_path}"
          get api(url, api_user, **options), params: params

          expect(response).to have_gitlab_http_status(:moved_permanently)
          expect(response.headers['Location']).to start_with(
            "#{request.base_url}/api/v4/projects/#{project.id}/repository/files/#{file_path}"
          )
        end
      end

      it 'sets inline content disposition by default' do
        url = route(file_path) + '/raw'

        get api(url, api_user, **options), params: params

        expect(headers['Content-Disposition']).to eq(%(inline; filename="#{file_name}"; filename*=UTF-8''#{file_name}))
      end

      context 'when mandatory params are not given' do
        it_behaves_like '400 response' do
          let(:request) { get api(route('any%2Ffile'), current_user, **options) }
        end
      end

      context 'when file_path does not exist' do
        let(:params) { { ref: 'master' } }

        it_behaves_like '404 response' do
          let(:request) { get api(route('app%2Fmodels%2Fapplication%2Erb'), api_user, **options), params: params }
          let(:message) { '404 File Not Found' }
        end
      end

      context 'when repository is disabled' do
        include_context 'disabled repository'

        it_behaves_like '403 response' do
          let(:request) { get api(route(file_path), api_user, **options), params: params }
        end
      end
    end

    context 'when unauthenticated' do
      context 'and project is public' do
        it_behaves_like 'repository files' do
          let(:project) { public_project }
          let(:current_user) { nil }
          let(:api_user) { nil }
        end
      end

      context 'and project is private' do
        it_behaves_like '404 response' do
          let(:request) { get api(route(file_path)), params: params }
          let(:message) { '404 Project Not Found' }
        end
      end
    end

    context 'when authenticated' do
      context 'and user is a direct project member' do
        context 'and project is private' do
          context 'and user is a developer' do
            it_behaves_like 'repository files' do
              let(:current_user) { user }
              let(:api_user) { user }
            end

            context 'and PATs are used' do
              it_behaves_like 'repository files' do
                let(:token) { create(:personal_access_token, scopes: ['read_repository'], user: user) }
                let(:current_user) { user }
                let(:api_user) { nil }
                let(:options) { { personal_access_token: token } }
              end
            end
          end

          context 'and user is a guest' do
            it_behaves_like '403 response' do
              let(:request) { get api(route(file_path), guest), params: params }
            end
          end
        end
      end
    end

    context 'when authenticated' do
      context 'and user is an inherited member from the group' do
        context 'when project is public with private repository' do
          let(:project) { public_project_private_repo }

          context 'and user is a guest' do
            it_behaves_like 'returns non-executable file attributes as json' do
              let(:api_user) { inherited_guest }
            end
          end

          context 'and user is a reporter' do
            it_behaves_like 'returns non-executable file attributes as json' do
              let(:api_user) { inherited_reporter }
            end
          end

          context 'and user is a developer' do
            it_behaves_like 'returns non-executable file attributes as json' do
              let(:api_user) { inherited_developer }
            end
          end
        end

        context 'when project is private' do
          let(:project) { private_project }

          context 'and user is a guest' do
            it_behaves_like '403 response' do
              let(:request) { get api(route(file_path), inherited_guest), params: params }
            end
          end

          context 'and user is a reporter' do
            it_behaves_like 'returns non-executable file attributes as json' do
              let(:api_user) { inherited_reporter }
            end
          end

          context 'and user is a developer' do
            it_behaves_like 'returns non-executable file attributes as json' do
              let(:api_user) { inherited_developer }
            end
          end
        end
      end
    end
  end

  describe 'GET /projects/:id/repository/files/:file_path/blame' do
    shared_examples_for 'repository blame files' do
      let(:expected_blame_range_sizes) do
        [3, 2, 1, 2, 1, 1, 1, 1, 8, 1, 3, 1, 2, 1, 4, 1, 2, 2]
      end

      let(:expected_blame_range_commit_ids) do
        %w[
          913c66a37b4a45b9769037c55c2d238bd0942d2e
          874797c3a73b60d2187ed6e2fcabd289ff75171e
          913c66a37b4a45b9769037c55c2d238bd0942d2e
          874797c3a73b60d2187ed6e2fcabd289ff75171e
          570e7b2abdd848b95f2f578043fc23bd6f6fd24d
          874797c3a73b60d2187ed6e2fcabd289ff75171e
          913c66a37b4a45b9769037c55c2d238bd0942d2e
          874797c3a73b60d2187ed6e2fcabd289ff75171e
          570e7b2abdd848b95f2f578043fc23bd6f6fd24d
          913c66a37b4a45b9769037c55c2d238bd0942d2e
          874797c3a73b60d2187ed6e2fcabd289ff75171e
          913c66a37b4a45b9769037c55c2d238bd0942d2e
          874797c3a73b60d2187ed6e2fcabd289ff75171e
          570e7b2abdd848b95f2f578043fc23bd6f6fd24d
          874797c3a73b60d2187ed6e2fcabd289ff75171e
          913c66a37b4a45b9769037c55c2d238bd0942d2e
          874797c3a73b60d2187ed6e2fcabd289ff75171e
          913c66a37b4a45b9769037c55c2d238bd0942d2e
        ]
      end

      it 'returns file attributes in headers' do
        head api(route(file_path) + '/blame', current_user), params: params

        expect(response).to have_gitlab_http_status(:ok)
        expect(response.headers['X-Gitlab-File-Path']).to eq(CGI.unescape(file_path))
        expect(response.headers['X-Gitlab-File-Name']).to eq(file_name)
        expect(response.headers['X-Gitlab-Last-Commit-Id']).to eq(last_commit_id)
        expect(response.headers['X-Gitlab-Content-Sha256']).to eq(content_sha256)
        expect(response.headers['X-Gitlab-Execute-Filemode']).to eq('false')
      end

      context 'for executable file' do
        it 'returns file attributes in headers' do
          head api(route(executable_file_path) + '/blame', current_user), params: executable_ref_params

          aggregate_failures 'testing response' do
            expect(response).to have_gitlab_http_status(:ok)
            expect(response.headers['X-Gitlab-File-Path']).to eq(CGI.unescape(executable_file_path))
            expect(response.headers['X-Gitlab-File-Name']).to eq('ls')
            expect(response.headers['X-Gitlab-Last-Commit-Id']).to eq('6b8dc4a827797aa025ff6b8f425e583858a10d4f')
            expect(response.headers['X-Gitlab-Content-Sha256'])
              .to eq('2c74b1181ef780dfb692c030d3a0df6e0b624135c38a9344e56b9f80007b6191')
            expect(response.headers['X-Gitlab-Execute-Filemode']).to eq('true')
          end
        end
      end

      it 'returns 400 when file path is invalid' do
        # TODO: remove spec once the feature flag is removed
        # https://gitlab.com/gitlab-org/gitlab/-/issues/415460
        stub_feature_flags(check_path_traversal_middleware_reject_requests: false)

        get api(route(invalid_file_path) + '/blame', current_user), params: params

        expect(response).to have_gitlab_http_status(:bad_request)
        expect(json_response['error']).to eq(invalid_file_message)
      end

      it_behaves_like 'when path is absolute' do
        subject { get api(route(absolute_path) + '/blame', current_user), params: params }
      end

      it 'returns blame file attributes as json' do
        get api(route(file_path) + '/blame', current_user), params: params

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response.map { |x| x['lines'].size }).to eq(expected_blame_range_sizes)
        expect(json_response.map { |x| x['commit']['id'] }).to eq(expected_blame_range_commit_ids)
        range = json_response[0]
        expect(range['lines']).to eq(["require 'fileutils'", "require 'open3'", ''])
        expect(range['commit']['id']).to eq('913c66a37b4a45b9769037c55c2d238bd0942d2e')
        expect(range['commit']['parent_ids']).to eq(['cfe32cf61b73a0d5e9f13e774abde7ff789b1660'])
        expect(range['commit']['message'])
          .to eq("Files, encoding and much more\n\nSigned-off-by: Dmitriy Zaporozhets <dmitriy.zaporozhets@gmail.com>\n")

        expect(range['commit']['authored_date']).to eq('2014-02-27T10:14:56.000+02:00')
        expect(range['commit']['author_name']).to eq('Dmitriy Zaporozhets')
        expect(range['commit']['author_email']).to eq('dmitriy.zaporozhets@gmail.com')

        expect(range['commit']['committed_date']).to eq('2014-02-27T10:14:56.000+02:00')
        expect(range['commit']['committer_name']).to eq('Dmitriy Zaporozhets')
        expect(range['commit']['committer_email']).to eq('dmitriy.zaporozhets@gmail.com')
      end

      context 'with a range parameter' do
        let(:params) { super().merge(range: { start: 2, end: 4 }) }

        it 'returns file blame attributes as json for the range' do
          get api(route(file_path) + '/blame', current_user), params: params

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response.size).to eq(2)

          lines = json_response.map { |x| x['lines'] }

          expect(lines.map(&:size)).to eq(expected_blame_range_sizes[1..2])
          expect(lines.flatten).to eq(["require 'open3'", '', 'module Popen'])
        end

        context 'when start > end' do
          let(:params) { super().merge(range: { start: 4, end: 2 }) }

          it 'returns 400 error' do
            get api(route(file_path) + '/blame', current_user), params: params

            expect(response).to have_gitlab_http_status(:bad_request)
            expect(json_response['message']).to eq('range[start] must be less than or equal to range[end]')
          end
        end

        context 'when range is incomplete' do
          let(:params) { super().merge(range: { start: 1 }) }

          it 'returns 400 error' do
            get api(route(file_path) + '/blame', current_user), params: params

            expect(response).to have_gitlab_http_status(:bad_request)
            expect(json_response['error']).to eq('range[end] is missing, range[end] is empty')
          end
        end

        context 'when range contains negative integers' do
          let(:params) { super().merge(range: { start: -2, end: -5 }) }

          it 'returns 400 error' do
            get api(route(file_path) + '/blame', current_user), params: params

            expect(response).to have_gitlab_http_status(:bad_request)
            expect(json_response['error']).to eq('range[start] does not have a valid value, range[end] does not have a valid value')
          end
        end

        context 'when range is missing' do
          let(:params) { super().merge(range: { start: '', end: '' }) }

          it 'returns 400 error' do
            get api(route(file_path) + '/blame', current_user), params: params

            expect(response).to have_gitlab_http_status(:bad_request)
            expect(json_response['error']).to eq('range[start] is empty, range[end] is empty')
          end
        end
      end

      it 'returns blame file info for files with dots' do
        url = route('.gitignore') + '/blame'

        get api(url, current_user), params: params

        expect(response).to have_gitlab_http_status(:ok)
      end

      it 'returns file by commit sha' do
        # This file is deleted on HEAD
        file_path = 'files%2Fjs%2Fcommit%2Ejs%2Ecoffee'
        params[:ref] = '6f6d7e7ed97bb5f0054f2b1df789b39ca89b6ff9'

        get api(route(file_path) + '/blame', current_user), params: params

        expect(response).to have_gitlab_http_status(:ok)
      end

      context 'when mandatory params are not given' do
        it_behaves_like '400 response' do
          let(:request) { get api(route('any%2Ffile/blame'), current_user) }
        end
      end

      context 'when file_path does not exist' do
        let(:params) { { ref: 'master' } }

        it_behaves_like '404 response' do
          let(:request) { get api(route('app%2Fmodels%2Fapplication%2Erb/blame'), current_user), params: params }
          let(:message) { '404 File Not Found' }
        end
      end

      context 'when commit does not exist' do
        let(:params) { { ref: '1111111111111111111111111111111111111111' } }

        it_behaves_like '404 response' do
          let(:request) { get api(route(file_path + '/blame'), current_user), params: params }
          let(:message) { '404 Commit Not Found' }
        end
      end

      context 'when repository is disabled' do
        include_context 'disabled repository'

        it_behaves_like '403 response' do
          let(:request) { get api(route(file_path + '/blame'), current_user), params: params }
        end
      end
    end

    context 'when unauthenticated' do
      context 'and project is public' do
        it_behaves_like 'repository blame files' do
          let(:project) { public_project }
          let(:current_user) { nil }
        end
      end

      context 'and project is private' do
        it_behaves_like '404 response' do
          let(:request) { get api(route(file_path)), params: params }
          let(:message) { '404 Project Not Found' }
        end
      end
    end

    context 'when authenticated' do
      context 'and user is a developer' do
        it_behaves_like 'repository blame files' do
          let(:current_user) { user }
        end
      end

      context 'and user is a guest' do
        it_behaves_like '403 response' do
          let(:request) { get api(route(file_path) + '/blame', guest), params: params }
        end
      end
    end

    context 'when PATs are used' do
      it 'returns blame file by commit sha' do
        token = create(:personal_access_token, scopes: ['read_repository'], user: user)

        # This file is deleted on HEAD
        file_path = 'files%2Fjs%2Fcommit%2Ejs%2Ecoffee'
        params[:ref] = '6f6d7e7ed97bb5f0054f2b1df789b39ca89b6ff9'

        get api(route(file_path) + '/blame', personal_access_token: token), params: params

        expect(response).to have_gitlab_http_status(:ok)
      end
    end
  end

  describe 'HEAD /projects/:id/repository/files/:file_path/raw' do
    let(:request) { head api(route(file_path) + '/raw', current_user), params: params }

    describe 'response headers' do
      subject { response.headers }

      context 'and user is a developer' do
        let(:current_user) { user }

        it 'responds with blob data' do
          request
          headers = response.headers
          expect(headers['X-Gitlab-File-Name']).to eq(file_name)
          expect(headers['X-Gitlab-File-Path']).to eq('files/ruby/popen.rb')
          expect(headers['X-Gitlab-Content-Sha256']).to eq('c440cd09bae50c4632cc58638ad33c6aa375b6109d811e76a9cc3a613c1e8887')
          expect(headers['X-Gitlab-Ref']).to eq('master')
          expect(headers['X-Gitlab-Blob-Id']).to eq('7e3e39ebb9b2bf433b4ad17313770fbe4051649c')
          expect(headers['X-Gitlab-Commit-Id']).to eq(project.repository.commit.id)
          expect(headers['X-Gitlab-Last-Commit-Id']).to eq('570e7b2abdd848b95f2f578043fc23bd6f6fd24d')
        end

        context 'when lfs parameter is true and the project has lfs enabled' do
          before do
            allow(Gitlab.config.lfs).to receive(:enabled).and_return(true)
            project.update_attribute(:lfs_enabled, true)
          end

          let(:request) { head api(route('files%2Flfs%2Flfs_object.iso') + '/raw', current_user), params: params.merge(lfs: true) }

          context 'and the file has an lfs object' do
            let_it_be(:lfs_object) { create(:lfs_object, :with_file, oid: '91eff75a492a3ed0dfcb544d7f31326bc4014c8551849c192fd1e48d4dd2c897') }

            it 'responds with 404' do
              request

              expect(response).to have_gitlab_http_status(:not_found)
            end

            context 'and the project has access to the lfs object' do
              before do
                project.lfs_objects << lfs_object
              end

              context 'and lfs uses AWS' do
                before do
                  stub_lfs_object_storage(config: Gitlab.config.lfs.object_store.merge(connection: {
                    provider: 'AWS',
                    aws_access_key_id: '',
                    aws_secret_access_key: ''
                  }))
                  lfs_object.file.migrate!(LfsObjectUploader::Store::REMOTE)
                end

                it 'redirects to the lfs object file with a signed url' do
                  request

                  expect(response).to have_gitlab_http_status(:found)
                  expect(response.location).to include(lfs_object.reload.file.path)
                  expect(response.location).to include('X-Amz-SignedHeaders')
                end
              end
            end
          end
        end
      end

      context 'and user is a guest' do
        it_behaves_like '403 response' do
          let(:request) { head api(route(file_path), guest), params: params }
        end
      end
    end
  end

  describe 'GET /projects/:id/repository/files/:file_path/raw' do
    shared_examples_for 'repository raw files' do
      it 'returns 400 when file path is invalid' do
        # TODO: remove spec once the feature flag is removed
        # https://gitlab.com/gitlab-org/gitlab/-/issues/415460
        stub_feature_flags(check_path_traversal_middleware_reject_requests: false)

        get api(route(invalid_file_path) + '/raw', current_user), params: params

        expect(response).to have_gitlab_http_status(:bad_request)
        expect(json_response['error']).to eq(invalid_file_message)
      end

      it_behaves_like 'when path is absolute' do
        subject { get api(route(absolute_path) + '/raw', current_user), params: params }
      end

      it 'returns raw file info' do
        url = route(file_path) + '/raw'

        expect_to_send_git_blob(api(url, current_user), params)
      end

      context 'when ref is not provided' do
        before do
          stub_application_setting(default_branch_name: 'main')
        end

        it 'returns response :ok', :aggregate_failures do
          url = route(file_path) + '/raw'

          expect_to_send_git_blob(api(url, current_user), {})
        end
      end

      it 'returns raw file info for files with dots' do
        url = route('.gitignore') + '/raw'

        expect_to_send_git_blob(api(url, current_user), params)
      end

      it 'returns file by commit sha' do
        # This file is deleted on HEAD
        file_path = 'files%2Fjs%2Fcommit%2Ejs%2Ecoffee'
        params[:ref] = '6f6d7e7ed97bb5f0054f2b1df789b39ca89b6ff9'

        expect_to_send_git_blob(api(route(file_path) + '/raw', current_user), params)
      end

      it 'sets no-cache headers' do
        url = route('.gitignore') + '/raw'

        expect_to_send_git_blob(api(url, current_user), params)

        expect(response.headers['Cache-Control']).to eq('max-age=0, private, must-revalidate, no-store, no-cache')
        expect(response.headers['Expires']).to eq('Fri, 01 Jan 1990 00:00:00 GMT')
      end

      context 'when mandatory params are not given' do
        it_behaves_like '400 response' do
          let(:request) { get api(route('any%2Ffile'), current_user) }
        end
      end

      context 'when file_path does not exist' do
        let(:params) { { ref: 'master' } }

        it_behaves_like '404 response' do
          let(:request) { get api(route('app%2Fmodels%2Fapplication%2Erb'), current_user), params: params }
          let(:message) { '404 File Not Found' }
        end
      end

      context 'when repository is disabled' do
        include_context 'disabled repository'

        it_behaves_like '403 response' do
          let(:request) { get api(route(file_path), current_user), params: params }
        end
      end

      context 'when lfs parameter is true and the project has lfs enabled' do
        before do
          allow(Gitlab.config.lfs).to receive(:enabled).and_return(true)
          project.update_attribute(:lfs_enabled, true)
        end

        let(:request) { get api(route(file_path) + '/raw', current_user), params: params.merge(lfs: true) }
        let(:file_path) { 'files%2Flfs%2Flfs_object.iso' }

        it_behaves_like '404 response'

        context 'and the file has an lfs object' do
          let_it_be(:lfs_object) { create(:lfs_object, :with_file, oid: '91eff75a492a3ed0dfcb544d7f31326bc4014c8551849c192fd1e48d4dd2c897') }

          it_behaves_like '404 response'

          context 'and the project has access to the lfs object' do
            before do
              project.lfs_objects << lfs_object
            end

            context 'and lfs uses local file storage' do
              before do
                Grape::Endpoint.before_each do |endpoint|
                  allow(endpoint).to receive(:sendfile).with(lfs_object.file.path)
                end
              end

              after do
                Grape::Endpoint.before_each nil
              end

              it 'responds with the lfs object file' do
                request
                expect(response.headers["Content-Disposition"]).to eq(
                  "attachment; filename=\"#{lfs_object.file.filename}\"; filename*=UTF-8''#{lfs_object.file.filename}"
                )
              end
            end

            context 'and lfs uses remote object storage' do
              before do
                stub_lfs_object_storage
                lfs_object.file.migrate!(LfsObjectUploader::Store::REMOTE)
              end

              it 'redirects to the lfs object file' do
                request

                expect(response).to have_gitlab_http_status(:found)
                expect(response.location).to include(lfs_object.reload.file.path)
              end
            end
          end
        end
      end
    end

    context 'when unauthenticated' do
      context 'and project is public' do
        it_behaves_like 'repository raw files' do
          let(:project) { public_project }
          let(:current_user) { nil }
        end
      end

      context 'and project is private' do
        it_behaves_like '404 response' do
          let(:request) { get api(route(file_path)), params: params }
          let(:message) { '404 Project Not Found' }
        end
      end
    end

    context 'when authenticated' do
      context 'and user is a developer' do
        it_behaves_like 'repository raw files' do
          let(:current_user) { user }
        end
      end

      context 'and user is a guest' do
        it_behaves_like '403 response' do
          let(:request) { get api(route(file_path), guest), params: params }
        end
      end
    end

    context 'when PATs are used' do
      it 'returns file by commit sha' do
        token = create(:personal_access_token, scopes: ['read_repository'], user: user)

        # This file is deleted on HEAD
        file_path = 'files%2Fjs%2Fcommit%2Ejs%2Ecoffee'
        params[:ref] = '6f6d7e7ed97bb5f0054f2b1df789b39ca89b6ff9'
        url = api(route(file_path) + '/raw', personal_access_token: token)

        expect_to_send_git_blob(url, params)
      end
    end
  end

  describe 'POST /projects/:id/repository/files/:file_path' do
    let(:file_path) { FFaker::Guid.guid }

    let(:params) do
      {
        branch: 'master',
        content: 'puts 8',
        commit_message: 'Added newfile'
      }
    end

    let(:executable_params) do
      {
        branch: 'master',
        content: 'puts 8',
        commit_message: 'Added newfile',
        execute_filemode: true
      }
    end

    shared_examples 'creates a new file in the project repo' do
      specify do
        post api(route(file_path), current_user), params: params

        expect(response).to have_gitlab_http_status(:created)
        expect(json_response['file_path']).to eq(CGI.unescape(file_path))
        last_commit = project.repository.commit.raw
        expect(last_commit.author_email).to eq(current_user.email)
        expect(last_commit.author_name).to eq(current_user.name)
        expect(project.repository.blob_at_branch(params[:branch], CGI.unescape(file_path)).executable?).to eq(false)
      end
    end

    context 'when authenticated', 'as a direct project member' do
      context 'when project is private' do
        context 'and user is a developer' do
          it 'returns 400 when file path is invalid' do
            # TODO: remove spec once the feature flag is removed
            # https://gitlab.com/gitlab-org/gitlab/-/issues/415460
            stub_feature_flags(check_path_traversal_middleware_reject_requests: false)

            post api(route(invalid_file_path), user), params: params

            expect(response).to have_gitlab_http_status(:bad_request)
            expect(json_response['error']).to eq(invalid_file_message)
          end

          it_behaves_like 'when path is absolute' do
            subject { post api(route(absolute_path), user), params: params }
          end

          it_behaves_like 'creates a new file in the project repo' do
            let(:current_user) { user }
          end

          it 'creates a new executable file in project repo' do
            post api(route(file_path), user), params: executable_params

            expect(response).to have_gitlab_http_status(:created)
            expect(json_response['file_path']).to eq(CGI.unescape(file_path))
            last_commit = project.repository.commit.raw
            expect(last_commit.author_email).to eq(user.email)
            expect(last_commit.author_name).to eq(user.name)
            expect(project.repository.blob_at_branch(params[:branch], CGI.unescape(file_path)).executable?).to eq(true)
          end

          context 'when no mandatory params given' do
            it 'returns a 400 bad request' do
              post api(route('any%2Etxt'), user)

              expect(response).to have_gitlab_http_status(:bad_request)
            end
          end

          context 'when the commit message is empty' do
            before do
              params[:commit_message] = ''
            end

            it 'returns a 400 bad request' do
              post api(route(file_path), user), params: params

              expect(response).to have_gitlab_http_status(:bad_request)
            end
          end

          context 'when editor fails to create file' do
            before do
              allow_next_instance_of(Repository) do |instance|
                allow(instance).to receive(:create_file).and_raise(Gitlab::Git::CommitError, 'Cannot create file')
              end
            end

            it 'returns a 400 bad request' do
              post api(route('any%2Etxt'), user), params: params

              expect(response).to have_gitlab_http_status(:bad_request)
            end
          end

          context 'and PATs are used' do
            it 'returns 403 with `read_repository` scope' do
              token = create(:personal_access_token, scopes: ['read_repository'], user: user)

              post api(route(file_path), personal_access_token: token), params: params

              expect(response).to have_gitlab_http_status(:forbidden)
            end

            it 'returns 201 with `api` scope' do
              token = create(:personal_access_token, scopes: ['api'], user: user)

              post api(route(file_path), personal_access_token: token), params: params

              expect(response).to have_gitlab_http_status(:created)
            end
          end

          context 'and the repo is empty' do
            let!(:project) { create(:project_empty_repo, namespace: user.namespace) }

            it_behaves_like 'creates a new file in the project repo' do
              let(:current_user) { user }
              let(:file_path) { FFaker::Guid.guid }
            end
          end

          context 'when specifying an author' do
            include_context 'with author parameters'

            it 'creates a new file with the specified author' do
              params.merge!(author_email: author_email, author_name: author_name)
              post api(route('new_file_with_author%2Etxt'), user), params: params

              expect(response).to have_gitlab_http_status(:created)
              expect(response.media_type).to eq('application/json')
              last_commit = project.repository.commit.raw
              expect(last_commit.author_email).to eq(author_email)
              expect(last_commit.author_name).to eq(author_name)
            end
          end
        end
      end
    end

    context 'when authenticated' do
      context 'and user is an inherited member from the group' do
        context 'when project is public with private repository' do
          let(:project) { public_project_private_repo }

          context 'and user is a guest' do
            it_behaves_like '403 response' do
              let(:request) { post api(route(file_path), inherited_guest), params: params }
            end
          end

          context 'and user is a reporter' do
            it_behaves_like '403 response' do
              let(:request) { post api(route(file_path), inherited_reporter), params: params }
            end
          end

          context 'and user is a developer' do
            it_behaves_like 'creates a new file in the project repo' do
              let(:current_user) { inherited_developer }
            end
          end
        end

        context 'when project is private' do
          let(:project) { private_project }

          context 'and user is a guest' do
            it_behaves_like '403 response' do
              let(:request) { post api(route(file_path), inherited_guest), params: params }
            end
          end

          context 'and user is a reporter' do
            it_behaves_like '403 response' do
              let(:request) { post api(route(file_path), inherited_reporter), params: params }
            end
          end

          context 'and user is a developer' do
            it_behaves_like 'creates a new file in the project repo' do
              let(:current_user) { inherited_developer }
            end
          end
        end
      end
    end
  end

  describe 'PUT /projects/:id/repository/files' do
    let(:params) do
      {
        branch: 'master',
        content: 'puts 8',
        commit_message: 'Changed file'
      }
    end

    it 'updates existing file in project repo' do
      put api(route(file_path), user), params: params

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response['file_path']).to eq(CGI.unescape(file_path))
      last_commit = project.repository.commit.raw
      expect(last_commit.author_email).to eq(user.email)
      expect(last_commit.author_name).to eq(user.name)
    end

    context 'when the commit message is empty' do
      before do
        params[:commit_message] = ''
      end

      it 'returns a 400 bad request' do
        put api(route(file_path), user), params: params

        expect(response).to have_gitlab_http_status(:bad_request)
      end
    end

    context 'when base64 encoding with a nil content' do
      let(:params) { super().merge(content: nil, encoding: 'base64') }

      it 'updates a file with an empty content' do
        put api(route(file_path), user), params: params

        expect(response).to have_gitlab_http_status(:ok)
        updated_blob = project.repository.blob_at('master', CGI.unescape(file_path))
        expect(updated_blob.data).to be_empty
      end
    end

    context 'when updating an existing file with stale last commit id' do
      let(:params_with_stale_id) { params.merge(last_commit_id: last_commit_for_path.parent_id) }

      it 'returns a 400 bad request' do
        put api(route(file_path), user), params: params_with_stale_id

        expect(response).to have_gitlab_http_status(:bad_request)
        expect(json_response['message']).to eq(_('You are attempting to update a file that has changed since you started editing it.'))
      end
    end

    context 'with correct last commit id' do
      let(:params_with_correct_id) { params.merge(last_commit_id: last_commit_for_path.id) }

      it 'updates existing file in project repo' do
        put api(route(file_path), user), params: params_with_correct_id

        expect(response).to have_gitlab_http_status(:ok)
      end
    end

    context 'when file path is invalid' do
      let(:params_with_correct_id) { params.merge(last_commit_id: last_commit_for_path.id) }

      it 'returns a 400 bad request' do
        # TODO: remove spec once the feature flag is removed
        # https://gitlab.com/gitlab-org/gitlab/-/issues/415460
        stub_feature_flags(check_path_traversal_middleware_reject_requests: false)

        put api(route(invalid_file_path), user), params: params_with_correct_id

        expect(response).to have_gitlab_http_status(:bad_request)
        expect(json_response['error']).to eq(invalid_file_message)
      end
    end

    it_behaves_like 'when path is absolute' do
      let(:params_with_correct_id) { params.merge(last_commit_id: last_commit_for_path.id) }

      subject { put api(route(absolute_path), user), params: params_with_correct_id }
    end

    context 'when no params given' do
      it 'returns a 400 bad request' do
        put api(route(file_path), user)

        expect(response).to have_gitlab_http_status(:bad_request)
      end
    end

    context 'when specifying an author' do
      include_context 'with author parameters'

      it 'updates a file with the specified author' do
        params.merge!(author_email: author_email, author_name: author_name, content: 'New content')

        put api(route(file_path), user), params: params

        expect(response).to have_gitlab_http_status(:ok)
        last_commit = project.repository.commit.raw
        expect(last_commit.author_email).to eq(author_email)
        expect(last_commit.author_name).to eq(author_name)
      end
    end

    context 'when specifying the execute_filemode' do
      let(:executable_params) do
        {
          branch: 'master',
          content: 'puts 8',
          commit_message: 'Changed file',
          execute_filemode: true
        }
      end

      let(:non_executable_params) do
        {
          branch: 'with-executables',
          content: 'puts 8',
          commit_message: 'Changed file',
          execute_filemode: false
        }
      end

      it 'updates to executable file mode' do
        put api(route(file_path), user), params: executable_params

        aggregate_failures 'testing response' do
          expect(response).to have_gitlab_http_status(:ok)
          expect(project.repository.blob_at_branch(executable_params[:branch], CGI.unescape(file_path)).executable?).to eq(true)
        end
      end

      it 'updates to non-executable file mode' do
        put api(route(executable_file_path), user), params: non_executable_params

        aggregate_failures 'testing response' do
          expect(response).to have_gitlab_http_status(:ok)
          expect(project.repository.blob_at_branch(non_executable_params[:branch], CGI.unescape(executable_file_path)).executable?).to eq(false)
        end
      end
    end
  end

  describe 'DELETE /projects/:id/repository/files' do
    let(:params) do
      {
        branch: 'master',
        commit_message: 'Changed file'
      }
    end

    describe 'when files are deleted' do
      let(:file_path) { FFaker::Guid.guid }

      before do
        create_file_in_repo(project, 'master', 'master', file_path, 'Test file')
      end

      it 'deletes existing file in project repo' do
        delete api(route(file_path), user), params: params

        expect(response).to have_gitlab_http_status(:no_content)
      end

      context 'when specifying an author' do
        include_context 'with author parameters'

        before do
          params.merge!(author_email: author_email, author_name: author_name)
        end

        it 'removes a file with the specified author' do
          delete api(route(file_path), user), params: params

          expect(response).to have_gitlab_http_status(:no_content)
        end
      end
    end

    describe 'when files are not deleted' do
      it_behaves_like 'when path is absolute' do
        subject { delete api(route(absolute_path), user), params: params }
      end

      it 'returns 400 when file path is invalid' do
        # TODO: remove spec once the feature flag is removed
        # https://gitlab.com/gitlab-org/gitlab/-/issues/415460
        stub_feature_flags(check_path_traversal_middleware_reject_requests: false)

        delete api(route(invalid_file_path), user), params: params

        expect(response).to have_gitlab_http_status(:bad_request)
        expect(json_response['error']).to eq(invalid_file_message)
      end

      context 'when no params given' do
        it 'returns a 400 bad request' do
          delete api(route(file_path), user)

          expect(response).to have_gitlab_http_status(:bad_request)
        end
      end

      context 'when the commit message is empty' do
        before do
          params[:commit_message] = ''
        end

        it 'returns a 400 bad request' do
          delete api(route(file_path), user), params: params

          expect(response).to have_gitlab_http_status(:bad_request)
        end
      end

      context 'when fails to delete file' do
        before do
          allow_next_instance_of(Repository) do |instance|
            allow(instance).to receive(:delete_file).and_raise(Gitlab::Git::CommitError, 'Cannot delete file')
          end
        end

        it 'returns a 400 bad request' do
          delete api(route(file_path), user), params: params

          expect(response).to have_gitlab_http_status(:bad_request)
        end
      end
    end
  end

  describe 'POST /projects/:id/repository/files with binary file' do
    let(:file_path) { 'test%2Ebin' }
    let(:put_params) do
      {
        branch: 'master',
        content: 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABAQMAAAAl21bKAAAAA1BMVEUAAACnej3aAAAAAXRSTlMAQObYZgAAAApJREFUCNdjYAAAAAIAAeIhvDMAAAAASUVORK5CYII=',
        commit_message: 'Binary file with a \n should not be touched',
        encoding: 'base64'
      }
    end

    let(:get_params) do
      {
        ref: 'master'
      }
    end

    before do
      post api(route(file_path), user), params: put_params
    end

    it 'remains unchanged' do
      get api(route(file_path), user), params: get_params

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response['file_path']).to eq(CGI.unescape(file_path))
      expect(json_response['file_name']).to eq(CGI.unescape(file_path))
      expect(json_response['content']).to eq(put_params[:content])
    end
  end

  describe 'POST /projects/:id/repository/files with text encoding' do
    let(:file_path) { 'test%2Etext' }
    let(:put_params) do
      {
        branch: 'master',
        content: 'test',
        commit_message: 'Text file',
        encoding: 'text'
      }
    end

    let(:get_params) do
      {
        ref: 'master'
      }
    end

    before do
      post api(route(file_path), user), params: put_params
    end

    it 'returns base64-encoded text file' do
      get api(route(file_path), user), params: get_params

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response['file_path']).to eq(CGI.unescape(file_path))
      expect(json_response['file_name']).to eq(CGI.unescape(file_path))
      expect(Base64.decode64(json_response['content'])).to eq("test")
    end
  end
end
