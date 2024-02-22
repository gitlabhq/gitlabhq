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
    wait_for_requests
  end

  it 'can navigate between pages' do
    page.within('[data-testid="ci-variable-table"]') do
      expect(page.all('.js-ci-variable-row').length).to be(first_page_count)
    end

    click_button 'Next'
    wait_for_requests

    page.within('[data-testid="ci-variable-table"]') do
      expect(page.all('.js-ci-variable-row').length).to be(1)
    end

    click_button 'Previous'
    wait_for_requests

    page.within('[data-testid="ci-variable-table"]') do
      expect(page.all('.js-ci-variable-row').length).to be(first_page_count)
    end
  end

  it 'sorts variables alphabetically in ASC and DESC order' do
    page.within('[data-testid="ci-variable-table"]') do
      expect(find('.js-ci-variable-row:nth-child(1) td[data-label="Key"]')).to have_content(variable.key)
      expect(find('.js-ci-variable-row:nth-child(20) td[data-label="Key"]')).to have_content('test_key_8')
    end

    click_button 'Next'
    wait_for_requests

    page.within('[data-testid="ci-variable-table"]') do
      expect(find('.js-ci-variable-row:nth-child(1) td[data-label="Key"]')).to have_content('test_key_9')
    end

    page.within('[data-testid="ci-variable-table"]') do
      find('[aria-sort="ascending"]').click
    end

    wait_for_requests

    page.within('[data-testid="ci-variable-table"]') do
      expect(find('.js-ci-variable-row:nth-child(1) td[data-label="Key"]')).to have_content('test_key_9')
      expect(find('.js-ci-variable-row:nth-child(20) td[data-label="Key"]')).to have_content('test_key_0')
    end
  end
end
