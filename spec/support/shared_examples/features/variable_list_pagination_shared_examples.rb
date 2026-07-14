# frozen_string_literal: true

RSpec.shared_examples 'variable list pagination' do |variable_type|
  first_page_count = 20

  before do
    first_page_count.times do |i|
      case variable_type
      when :ci_variable
        create(variable_type, key: "test_key_#{i}", value: 'test_value', masked: true, project: project)
      when :ci_group_variable
        create(variable_type, key: "test_key_#{i}", value: 'test_value', masked: true, group: group)
      else
        create(variable_type, key: "test_key_#{i}", value: 'test_value', masked: true)
      end
    end

    visit page_path
  end

  it 'can navigate between pages' do
    page.within('[data-testid="ci-variable-table"]') do
      expect(page).to have_selector('.js-ci-variable-row', count: first_page_count)
    end

    click_button 'Next'

    page.within('[data-testid="ci-variable-table"]') do
      expect(page).to have_selector('.js-ci-variable-row', count: 1)
    end

    click_button 'Previous'

    page.within('[data-testid="ci-variable-table"]') do
      expect(page).to have_selector('.js-ci-variable-row', count: first_page_count)
    end
  end

  it 'sorts variables alphabetically in ASC and DESC order' do
    page.within('[data-testid="ci-variable-table"]') do
      expect(page).to have_selector('.js-ci-variable-row:nth-child(1) td[data-label="Key"]', text: variable.key)
      expect(page).to have_selector('.js-ci-variable-row:nth-child(20) td[data-label="Key"]', text: 'test_key_8')
    end

    click_button 'Next'

    page.within('[data-testid="ci-variable-table"]') do
      expect(page).to have_selector('.js-ci-variable-row:nth-child(1) td[data-label="Key"]', text: 'test_key_9')
    end

    page.within('[data-testid="ci-variable-table"]') do
      find('[aria-sort="ascending"]').click
    end

    page.within('[data-testid="ci-variable-table"]') do
      expect(page).to have_selector('.js-ci-variable-row:nth-child(1) td[data-label="Key"]', text: 'test_key_9')
      expect(page).to have_selector('.js-ci-variable-row:nth-child(20) td[data-label="Key"]', text: 'test_key_0')
    end
  end
end
