# frozen_string_literal: true

RSpec.shared_examples 'merge request author auto assign' do
  it 'populates merge request author as assignee' do
    expect(find('.js-assignee-search')).to have_content(user.name)
    expect(page).not_to have_content 'Assign yourself'
  end
end
