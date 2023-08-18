# frozen_string_literal: true

RSpec.shared_examples 'variable list drawer' do
  it 'adds a new CI variable' do
    click_button('Add variable')

    # For now, we just check that the drawer is displayed
    expect(page).to have_selector('[data-testid="ci-variable-drawer"]')

    # TODO: Add tests for ADDING a variable via drawer when feature is available
  end

  it 'edits a variable' do
    page.within('[data-testid="ci-variable-table"]') do
      click_button('Edit')
    end

    # For now, we just check that the drawer is displayed
    expect(page).to have_selector('[data-testid="ci-variable-drawer"]')

    # TODO: Add tests for EDITING a variable via drawer when feature is available
  end
end
