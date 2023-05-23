# frozen_string_literal: true

RSpec.shared_examples 'milestone with interactive markdown task list items in description' do
  let(:markdown) do
    <<-MARKDOWN.strip_heredoc
    This is a task list:

    - [ ] Incomplete task list item 1
    - [x] Complete task list item 1
    - [ ] Incomplete task list item 2
    - [x] Complete task list item 2
    - [ ] Incomplete task list item 3
    - [ ] Incomplete task list item 4
    MARKDOWN
  end

  before do
    milestone.update!(description: markdown)
  end

  it 'renders task list in description' do
    visit milestone_path

    wait_for_requests

    within('ul.task-list') do
      expect(page).to have_selector('li.task-list-item', count: 6)
      expect(page).to have_selector('li.task-list-item input.task-list-item-checkbox[checked]', count: 2)
    end
  end

  it 'allows interaction with task list item checkboxes' do
    visit milestone_path

    wait_for_requests

    within('ul.task-list') do
      within('li.task-list-item', text: 'Incomplete task list item 1') do
        find('input.task-list-item-checkbox').click
        wait_for_requests
      end

      expect(page).to have_selector('li.task-list-item', count: 6)
      page.all('li.task-list-item input.task-list-item-checkbox') { |element| expect(element).to be_checked }

      # After page reload, the task list items should still be checked
      visit milestone_path

      wait_for_requests

      expect(page).to have_selector('ul input[type="checkbox"][checked]', count: 3)
    end
  end
end
