# frozen_string_literal: true

RSpec.shared_examples 'snippets sort order' do
  let(:params) { {} }
  let(:sort_argument) { {} }
  let(:sort_params) { params.merge(sort_argument) }

  before do
    sign_in(user)

    stub_snippet_counter
  end

  subject { get :index, params: sort_params }

  context 'when no sort param is provided' do
    it 'calls SnippetsFinder with updated_at sort option' do
      expect(SnippetsFinder).to receive(:new)
        .with(user, hash_including(sort: 'updated_desc'))
        .and_call_original

      subject
    end
  end

  context 'when sort param is provided' do
    let(:order) { 'created_desc' }
    let(:sort_argument) { { sort: order } }

    it 'calls SnippetsFinder with the given sort param' do
      expect(SnippetsFinder).to receive(:new)
        .with(user, hash_including(sort: order))
        .and_call_original

      subject
    end
  end

  def stub_snippet_counter
    allow(Snippets::CountService)
      .to receive(:new).and_return(double(:count_service, execute: {}))
  end
end
