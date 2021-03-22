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

RSpec.shared_examples 'can search settings with feature flag check' do |search_term, non_match_section|
  let(:flag) { true }

  before do
    stub_feature_flags(search_settings_in_page: flag)

    visit(visit_path)
  end

  context 'with feature flag on' do
    it_behaves_like 'can search settings', search_term, non_match_section
  end

  context 'with feature flag off' do
    let(:flag) { false }

    it_behaves_like 'cannot search settings'
  end
end
