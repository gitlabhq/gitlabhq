# frozen_string_literal: true

RSpec.shared_examples 'wiki routing' do
  it_behaves_like 'resource routing' do
    let(:id) { 'directory/page' }
    let(:actions) { %i[show new create edit update destroy] }
    let(:additional_actions) do
      {
        pages: [:get, '/pages'],
        history: [:get, '/:id/history'],
        git_access: [:get, '/git_access'],
        preview_markdown: [:post, '/:id/preview_markdown']
      }
    end
  end

  it 'redirects the base path to the home page', type: :request do
    expect(get(base_path)).to redirect_to("#{base_path}/home")
  end
end
