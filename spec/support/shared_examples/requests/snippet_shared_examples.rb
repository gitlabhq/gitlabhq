# frozen_string_literal: true

RSpec.shared_examples 'update with repository actions' do
  context 'when the repository exists' do
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
    end
  end
end

RSpec.shared_examples 'snippet response without repository URLs' do
  it 'skip inclusion of repository URLs' do
    expect(json_response).not_to have_key('ssh_url_to_repo')
    expect(json_response).not_to have_key('http_url_to_repo')
  end
end

RSpec.shared_examples 'snippet blob content' do
  it 'returns content from repository' do
    subject

    expect(response.body).to eq(snippet.blobs.first.data)
  end

  context 'when snippet repository is empty' do
    let(:snippet) { snippet_with_empty_repo }

    it 'returns content from database' do
      subject

      expect(response.body).to eq(snippet.content)
    end
  end
end
