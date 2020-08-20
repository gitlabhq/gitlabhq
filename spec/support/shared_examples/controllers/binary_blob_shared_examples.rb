# frozen_string_literal: true

RSpec.shared_examples 'editing snippet checks blob is binary' do
  let(:snippets_binary_blob_value) { true }

  before do
    sign_in(user)

    allow_next_instance_of(Blob) do |blob|
      allow(blob).to receive(:binary?).and_return(binary)
    end

    stub_feature_flags(snippets_binary_blob: snippets_binary_blob_value)

    subject
  end

  context 'when blob is text' do
    let(:binary) { false }

    it 'responds with status 200' do
      expect(response).to have_gitlab_http_status(:ok)
      expect(response).to render_template(:edit)
    end
  end

  context 'when blob is binary' do
    let(:binary) { true }

    it 'responds with status 200' do
      expect(response).to have_gitlab_http_status(:ok)
      expect(response).to render_template(:edit)
    end

    context 'when feature flag :snippets_binary_blob is disabled' do
      let(:snippets_binary_blob_value) { false }

      it 'redirects away' do
        expect(response).to redirect_to(gitlab_snippet_path(snippet))
      end
    end
  end
end

RSpec.shared_examples 'updating snippet checks blob is binary' do
  let(:snippets_binary_blob_value) { true }

  before do
    sign_in(user)

    allow_next_instance_of(Blob) do |blob|
      allow(blob).to receive(:binary?).and_return(binary)
    end

    stub_feature_flags(snippets_binary_blob: snippets_binary_blob_value)

    subject
  end

  context 'when blob is text' do
    let(:binary) { false }

    it 'updates successfully' do
      expect(snippet.reload.title).to eq title
      expect(response).to redirect_to(gitlab_snippet_path(snippet))
    end
  end

  context 'when blob is binary' do
    let(:binary) { true }

    it 'updates successfully' do
      expect(snippet.reload.title).to eq title
      expect(response).to redirect_to(gitlab_snippet_path(snippet))
    end

    context 'when feature flag :snippets_binary_blob is disabled' do
      let(:snippets_binary_blob_value) { false }

      it 'redirects away without updating' do
        expect(response).to redirect_to(gitlab_snippet_path(snippet))
        expect(snippet.reload.title).not_to eq title
      end
    end
  end
end
