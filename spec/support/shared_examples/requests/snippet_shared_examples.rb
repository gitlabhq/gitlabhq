# frozen_string_literal: true

RSpec.shared_examples 'update with repository actions' do
  context 'when the repository exists' do
    before do
      allow_any_instance_of(Snippet).to receive(:multiple_files?).and_return(false)
    end

    it 'commits the changes to the repository' do
      existing_blob = snippet.blobs.first
      new_file_name = existing_blob.path + '_new'
      new_content = 'New content'

      update_snippet(params: { content: new_content, file_name: new_file_name })

      aggregate_failures do
        expect(response).to have_gitlab_http_status(:ok)
        expect(snippet.repository.blob_at('master', existing_blob.path)).to be_nil

        blob = snippet.repository.blob_at('master', new_file_name)
        expect(blob).not_to be_nil
        expect(blob.data).to eq(new_content)
      end
    end
  end

  context 'when the repository does not exist' do
    let(:snippet) { snippet_without_repo }

    context 'when update attributes does not include file_name or content' do
      it 'does not create the repository' do
        update_snippet(snippet_id: snippet.id, params: { title: 'foo' })

        expect(snippet.repository).not_to exist
      end
    end

    context 'when update attributes include file_name or content' do
      it 'creates the repository' do
        update_snippet(snippet_id: snippet.id, params: { title: 'foo', file_name: 'foo' })

        expect(snippet.repository).to exist
      end

      it 'commits the file to the repository' do
        content = 'New Content'
        file_name = 'file_name.rb'

        update_snippet(snippet_id: snippet.id, params: { content: content, file_name: file_name })

        blob = snippet.repository.blob_at('master', file_name)
        expect(blob).not_to be_nil
        expect(blob.data).to eq content
      end

      context 'when save fails due to a repository creation error' do
        let(:content) { 'File content' }
        let(:file_name) { 'test.md' }

        before do
          allow_next_instance_of(Snippets::UpdateService) do |instance|
            allow(instance).to receive(:create_repository_for).with(snippet).and_raise(Snippets::UpdateService::CreateRepositoryError)
          end

          update_snippet(snippet_id: snippet.id, params: { content: content, file_name: file_name })
        end

        it 'returns 400' do
          expect(response).to have_gitlab_http_status(:bad_request)
        end

        it 'does not save the changes to the snippet object' do
          expect(snippet.content).not_to eq(content)
          expect(snippet.file_name).not_to eq(file_name)
        end
      end
    end
  end
end

RSpec.shared_examples 'snippet blob content' do
  it 'returns content from repository' do
    expect(Gitlab::Workhorse).to receive(:send_git_blob).and_call_original

    subject

    expect(response.header[Gitlab::Workhorse::DETECT_HEADER]).to eq 'true'
    expect(response.header[Gitlab::Workhorse::SEND_DATA_HEADER]).to start_with('git-blob:')
    expect(response.parsed_body).to be_empty
  end

  context 'when snippet repository is empty' do
    let(:snippet) { snippet_with_empty_repo }

    it 'returns content from database' do
      subject

      expect(response.body).to eq(snippet.content)
    end
  end
end

RSpec.shared_examples 'snippet creation with files parameter' do
  using RSpec::Parameterized::TableSyntax

  where(:path, :content, :status, :error) do
    '.gitattributes'      | 'file content' | :created     | nil
    'valid/path/file.rb'  | 'file content' | :created     | nil

    '.gitattributes'      | nil            | :bad_request | 'files[0][content] is empty'
    '.gitattributes'      | ''             | :bad_request | 'files[0][content] is empty'

    ''                    | 'file content' | :bad_request | 'files[0][file_path] is empty'
    nil                   | 'file content' | :bad_request | 'files[0][file_path] should be a valid file path, files[0][file_path] is empty'
    '../../etc/passwd'    | 'file content' | :bad_request | 'files[0][file_path] should be a valid file path'
  end

  with_them do
    let(:file_path)    { path }
    let(:file_content) { content }

    before do
      subject
    end

    it 'responds correctly' do
      expect(response).to have_gitlab_http_status(status)
      expect(json_response['error']).to eq(error)
    end
  end

  it 'returns 400 if both files and content are provided' do
    params[:file_name] = 'foo.rb'
    params[:content] = 'bar'

    subject

    expect(response).to have_gitlab_http_status(:bad_request)
    expect(json_response['error']).to eq 'files, content are mutually exclusive'
  end

  it 'returns 400 when neither files or content are provided' do
    params.delete(:files)

    subject

    expect(response).to have_gitlab_http_status(:bad_request)
    expect(json_response['error']).to eq 'files, content are missing, exactly one parameter must be provided'
  end
end

RSpec.shared_examples 'snippet creation without files parameter' do
  let(:file_params) { { file_name: 'testing.rb', content: 'snippet content' } }

  it 'allows file_name and content parameters' do
    subject

    expect(response).to have_gitlab_http_status(:created)
  end

  it 'returns 400 if file_name and content are not both provided' do
    params.delete(:file_name)

    subject

    expect(response).to have_gitlab_http_status(:bad_request)
    expect(json_response['error']).to eq 'file_name is missing'
  end

  it 'returns 400 if content is blank' do
    params[:content] = ''

    subject

    expect(response).to have_gitlab_http_status(:bad_request)
    expect(json_response['error']).to eq 'content is empty'
  end
end
