# frozen_string_literal: true

RSpec.shared_examples 'handling feature network errors with the container registry' do
  it 'displays the error message' do
    visit_container_registry

    expect(page).to have_content 'We are having trouble connecting to the Container Registry'
  end
end
