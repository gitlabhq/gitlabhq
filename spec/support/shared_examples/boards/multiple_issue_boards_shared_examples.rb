# frozen_string_literal: true

RSpec.shared_examples 'multiple issue boards' do
  include ListboxHelpers

  context 'authorized user' do
    before do
      parent.add_maintainer(user)

      login_as(user)

      visit boards_path
      wait_for_requests
    end

    it 'shows current board name' do
      page.within('.boards-switcher') do
        expect(page).to have_content(board.name)
      end
    end

    it 'shows a list of boards' do
      in_boards_switcher_dropdown do
        expect(page).to have_content(board.name)
        expect(page).to have_content(board2.name)
      end
    end

    it 'switches current board' do
      in_boards_switcher_dropdown do
        select_listbox_item(board2.name)
      end

      wait_for_requests

      page.within('.boards-switcher') do
        expect(page).to have_content(board2.name)
      end
    end

    it 'creates new board without detailed configuration' do
      in_boards_switcher_dropdown do
        click_button 'Create new board'
      end

      fill_in 'board-new-name', with: 'This is a new board'
      click_button 'Create board'
      wait_for_requests

      expect(page).to have_button('This is a new board')
    end

    it 'deletes board', quarantine: 'https://gitlab.com/gitlab-org/gitlab/-/issues/280554' do
      in_boards_switcher_dropdown do
        click_button 'Delete board'
      end

      expect(page).to have_content('Are you sure you want to delete this board?')
      click_button 'Delete'

      wait_for_requests

      in_boards_switcher_dropdown do
        expect(page).not_to have_content(board.name)
        expect(page).to have_content(board2.name)
      end
    end

    it 'adds a list to the none default board' do
      in_boards_switcher_dropdown do
        select_listbox_item(board2.name)
      end

      wait_for_requests

      page.within('.boards-switcher') do
        expect(page).to have_content(board2.name)
      end

      click_button 'New list'

      click_button 'Select a label'

      find('label', text: planning.title).click

      click_button 'Add to board'

      wait_for_requests

      expect(page).to have_selector('.board', count: 3)

      in_boards_switcher_dropdown do
        select_listbox_item(board.name)
      end

      wait_for_requests

      expect(page).to have_selector('.board', count: 2)
    end

    it 'maintains sidebar state over board switch' do
      assert_boards_nav_active

      in_boards_switcher_dropdown do
        select_listbox_item(board2.name)
      end

      assert_boards_nav_active
    end

    it 'switches current board back' do
      in_boards_switcher_dropdown do
        select_listbox_item(board.name)
      end

      wait_for_requests

      page.within('.boards-switcher') do
        expect(page).to have_content(board.name)
      end
    end
  end

  context 'unauthorized user' do
    before do
      visit boards_path
      wait_for_requests
    end

    it 'shows current board name' do
      page.within('.boards-switcher') do
        expect(page).to have_content(board.name)
      end
    end

    it 'shows a list of boards' do
      in_boards_switcher_dropdown do
        expect(page).to have_content(board.name)
        expect(page).to have_content(board2.name)
      end
    end

    it 'switches current board' do
      in_boards_switcher_dropdown do
        select_listbox_item(board2.name)
      end

      wait_for_requests

      page.within('.boards-switcher') do
        expect(page).to have_content(board2.name)
      end
    end

    it 'does not show action links' do
      in_boards_switcher_dropdown do
        expect(page).not_to have_content('Create new board')
        expect(page).not_to have_content('Delete board')
      end
    end
  end

  def in_boards_switcher_dropdown
    find('.boards-switcher').click

    wait_for_requests

    dropdown_selector = '[data-testid="boards-selector"] .gl-new-dropdown'
    page.within(dropdown_selector) do
      yield
    end
  end

  def assert_boards_nav_active
    within_testid('super-sidebar') do
      expect(page).to have_selector('[aria-current="page"]', text: 'Issue boards')
    end
  end
end
