# frozen_string_literal: true

RSpec.shared_examples 'wiki routing' do
  it_behaves_like 'resource routing' do
    let(:id) { 'directory/page' }
    let(:actions) { %i[index show new create edit update destroy] }
    let(:additional_actions) do
      {
        pages: [:get, '/pages'],
        history: [:get, '/:id/history'],
        git_access: [:get, '/git_access'],
        preview_markdown: [:post, '/:id/preview_markdown']
      }
    end
  end
end
