# frozen_string_literal: true

RSpec.shared_examples 'top right search form' do
  it 'does not show top right search form' do
    expect(page).not_to have_selector('.search')
  end
end
