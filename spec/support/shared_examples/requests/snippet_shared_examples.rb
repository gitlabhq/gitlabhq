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

    it 'creates the repository' do
      update_snippet(snippet_id: snippet.id, params: { title: 'foo' })

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
