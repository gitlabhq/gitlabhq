# frozen_string_literal: true

RSpec.shared_examples 'cannot search settings' do
  it 'does note have search settings field' do
    expect(page).not_to have_field(placeholder: SearchHelpers::INPUT_PLACEHOLDER)
  end
end

RSpec.shared_examples 'can search settings' do |search_term, non_match_section|
  it_behaves_like 'can highlight results', search_term

  it 'hides unmatching sections on search' do
    expect(page).to have_content(non_match_section)

    fill_in SearchHelpers::INPUT_PLACEHOLDER, with: search_term

    expect(page).to have_content(search_term)
    expect(page).not_to have_content(non_match_section)
  end
end

RSpec.shared_examples 'can highlight results' do |search_term|
  it 'has search settings field' do
    expect(page).to have_field(placeholder: SearchHelpers::INPUT_PLACEHOLDER)
  end

  it 'highlights the search terms' do
    selector = '.gl-bg-orange-100'
    fill_in SearchHelpers::INPUT_PLACEHOLDER, with: search_term

    expect(page).to have_css(selector)

    page.find_all(selector) do |element|
      expect(element).to have_content(search_term)
    end
  end
end
