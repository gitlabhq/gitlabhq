# frozen_string_literal: true

RSpec.shared_examples 'raw snippet files' do
  let_it_be(:unauthorized_user) { create(:user) }
  let(:snippet_id) { snippet.id }
  let(:user)       { snippet.author }
  let(:file_path)  { '%2Egitattributes' }
  let(:ref)        { 'master' }

  context 'with no user' do
    it 'requires authentication' do
      get api(api_path)

      expect(response).to have_gitlab_http_status(:unauthorized)
    end
  end

  shared_examples 'not found' do
    it 'returns 404' do
      get api(api_path, user)

      expect(response).to have_gitlab_http_status(:not_found)
      expect(json_response['message']).to eq('404 Snippet Not Found')
    end
  end

  context 'when not authorized' do
    let(:user) { unauthorized_user }

    it_behaves_like 'not found'
  end

  context 'with an invalid snippet ID' do
    let(:snippet_id) { 'invalid' }

    it_behaves_like 'not found'
  end

  context 'with valid params' do
    it 'returns the raw file info' do
      expect(Gitlab::Workhorse).to receive(:send_git_blob).and_call_original

      get api(api_path, user)

      aggregate_failures do
        expect(response).to have_gitlab_http_status(:ok)
        expect(response.media_type).to eq 'text/plain'
        expect(response.header[Gitlab::Workhorse::DETECT_HEADER]).to eq 'true'
        expect(response.header[Gitlab::Workhorse::SEND_DATA_HEADER]).to start_with('git-blob:')
        expect(response.header['Content-Disposition']).to match 'filename=".gitattributes"'
      end
    end
  end

  context 'with invalid params' do
    using RSpec::Parameterized::TableSyntax

    where(:file_path, :ref, :status, :key, :message) do
      '%2Egitattributes'      | 'invalid-ref' | :not_found   | 'message' | '404 Reference Not Found'
      '%2Egitattributes'      | nil           | :not_found   | 'error'   | '404 Not Found'
      '%2Egitattributes'      | ''            | :not_found   | 'error'   | '404 Not Found'

      'doesnotexist.rb'       | 'master'      | :not_found   | 'message' | '404 File Not Found'
      '/does/not/exist.rb'    | 'master'      | :not_found   | 'error'   | '404 Not Found'
      '%2E%2E%2Fetc%2Fpasswd' | 'master'      | :bad_request | 'error'   | 'file_path should be a valid file path'
      '%2Fetc%2Fpasswd'       | 'master'      | :bad_request | 'error'   | 'file_path should be a valid file path'
      '../../etc/passwd'      | 'master'      | :not_found   | 'error'   | '404 Not Found'
    end

    with_them do
      before do
        get api(api_path, user)
      end

      it { expect(response).to have_gitlab_http_status(status) }
      it { expect(json_response[key]).to eq(message) }
    end
  end
end

RSpec.shared_examples 'snippet file updates' do
  let(:create_action)     { { action: 'create', file_path: 'foo.txt', content: 'bar' } }
  let(:update_action)     { { action: 'update', file_path: 'CHANGELOG', content: 'bar' } }
  let(:move_action)       { { action: 'move',   file_path: '.old-gitattributes', previous_path: '.gitattributes' } }
  let(:delete_action)     { { action: 'delete', file_path: 'CONTRIBUTING.md' } }
  let(:bad_file_path)     { { action: 'create', file_path: '../../etc/passwd', content: 'bar' } }
  let(:bad_previous_path) { { action: 'create', previous_path: '../../etc/passwd', file_path: 'CHANGELOG', content: 'bar' } }
  let(:invalid_move)      { { action: 'move',   file_path: 'missing_previous_path.txt' } }

  context 'with various snippet file changes' do
    using RSpec::Parameterized::TableSyntax

    where(:is_multi_file, :file_name, :content, :files, :status) do
      true  | nil       | nil   | [create_action]                | :success
      true  | nil       | nil   | [update_action]                | :success
      true  | nil       | nil   | [move_action]                  | :success
      true  | nil       | nil   | [delete_action]                | :success
      true  | nil       | nil   | [create_action, update_action] | :success
      true  | 'foo.txt' | 'bar' | [create_action]                | :bad_request
      true  | 'foo.txt' | 'bar' | nil                            | :bad_request
      true  | nil       | nil   | nil                            | :bad_request
      true  | 'foo.txt' | nil   | [create_action]                | :bad_request
      true  | nil       | 'bar' | [create_action]                | :bad_request
      true  | ''        | nil   | [create_action]                | :bad_request
      true  | nil       | ''    | [create_action]                | :bad_request
      true  | nil       | nil   | [bad_file_path]                | :bad_request
      true  | nil       | nil   | [bad_previous_path]            | :bad_request
      true  | nil       | nil   | [invalid_move]                 | :unprocessable_entity

      false | 'foo.txt' | 'bar' | nil                            | :success
      false | 'foo.txt' | nil   | nil                            | :success
      false | nil       | 'bar' | nil                            | :success
      false | 'foo.txt' | 'bar' | [create_action]                | :bad_request
      false | nil       | nil   | nil                            | :bad_request
      false | nil       | ''    | nil                            | :bad_request
      false | nil       | nil   | [bad_file_path]                | :bad_request
      false | nil       | nil   | [bad_previous_path]            | :bad_request
    end

    with_them do
      before do
        allow_any_instance_of(Snippet).to receive(:multiple_files?).and_return(is_multi_file)
      end

      it 'has the correct response' do
        update_params = {}.tap do |params|
          params[:files]     = files     if files
          params[:file_name] = file_name if file_name
          params[:content]   = content   if content
        end

        update_snippet(params: update_params)

        expect(response).to have_gitlab_http_status(status)
      end
    end

    context 'when save fails due to a repository commit error' do
      before do
        allow_next_instance_of(Repository) do |instance|
          allow(instance).to receive(:multi_action).and_raise(Gitlab::Git::CommitError)
        end

        update_snippet(params: { files: [create_action] })
      end

      it 'returns a bad request response' do
        expect(response).to have_gitlab_http_status(:bad_request)
      end
    end
  end
end

RSpec.shared_examples 'snippet non-file updates' do
  it 'updates a snippet non-file attributes' do
    new_description = 'New description'
    new_title       = 'New title'
    new_visibility  = 'internal'

    update_snippet(params: { title: new_title, description: new_description, visibility: new_visibility })

    snippet.reload

    aggregate_failures do
      expect(response).to have_gitlab_http_status(:ok)
      expect(snippet.description).to eq(new_description)
      expect(snippet.visibility).to eq(new_visibility)
      expect(snippet.title).to eq(new_title)
    end
  end
end

RSpec.shared_examples 'snippet individual non-file updates' do
  using RSpec::Parameterized::TableSyntax

  where(:attribute, :updated_value) do
    :description | 'new description'
    :title       | 'new title'
    :visibility  | 'private'
  end

  with_them do
    it 'updates the attribute' do
      params = { attribute => updated_value }

      expect { update_snippet(params: params) }
        .to change { snippet.reload.send(attribute) }.to(updated_value)
    end
  end
end

RSpec.shared_examples 'invalid snippet updates' do
  it 'returns 404 for invalid snippet id' do
    update_snippet(snippet_id: non_existing_record_id, params: { title: 'foo' })

    expect(response).to have_gitlab_http_status(:not_found)
    expect(json_response['message']).to eq('404 Snippet Not Found')
  end

  it 'returns 400 for missing parameters' do
    update_snippet

    expect(response).to have_gitlab_http_status(:bad_request)
  end

  it 'returns 400 if content is blank' do
    update_snippet(params: { content: '' })

    expect(response).to have_gitlab_http_status(:bad_request)
  end

  it 'returns 400 if title is blank' do
    update_snippet(params: { title: '' })

    expect(response).to have_gitlab_http_status(:bad_request)
    expect(json_response['error']).to eq 'title is empty'
  end
end
