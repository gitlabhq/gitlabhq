# frozen_string_literal: true

shared_examples_for 'multiple issue boards' do
  dropdown_selector = '.js-boards-selector .dropdown-menu'

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
      click_button board.name

      page.within(dropdown_selector) do
        expect(page).to have_content(board.name)
        expect(page).to have_content(board2.name)
      end
    end

    it 'switches current board' do
      click_button board.name

      page.within(dropdown_selector) do
        click_link board2.name
      end

      wait_for_requests

      page.within('.boards-switcher') do
        expect(page).to have_content(board2.name)
      end
    end

    it 'creates new board without detailed configuration' do
      click_button board.name

      page.within(dropdown_selector) do
        click_button 'Create new board'
      end

      fill_in 'board-new-name', with: 'This is a new board'
      click_button 'Create board'
      wait_for_requests

      expect(page).to have_button('This is a new board')
    end

    it 'deletes board' do
      click_button board.name

      wait_for_requests

      page.within(dropdown_selector) do
        click_button 'Delete board'
      end

      expect(page).to have_content('Are you sure you want to delete this board?')
      click_button 'Delete'

      click_button board2.name
      page.within(dropdown_selector) do
        expect(page).not_to have_content(board.name)
        expect(page).to have_content(board2.name)
      end
    end

    it 'adds a list to the none default board' do
      click_button board.name

      page.within(dropdown_selector) do
        click_link board2.name
      end

      wait_for_requests

      page.within('.boards-switcher') do
        expect(page).to have_content(board2.name)
      end

      click_button 'Add list'

      wait_for_requests

      page.within '.dropdown-menu-issues-board-new' do
        click_link planning.title
      end

      wait_for_requests

      expect(page).to have_selector('.board', count: 3)

      click_button board2.name

      page.within(dropdown_selector) do
        click_link board.name
      end

      wait_for_requests

      expect(page).to have_selector('.board', count: 2)
    end

    it 'maintains sidebar state over board switch' do
      assert_boards_nav_active

      find('.boards-switcher').click
      wait_for_requests
      click_link board2.name

      assert_boards_nav_active
    end
  end

  context 'unauthorized user' do
    before do
      visit boards_path
      wait_for_requests
    end

    it 'does not show action links' do
      click_button board.name

      page.within(dropdown_selector) do
        expect(page).not_to have_content('Create new board')
        expect(page).not_to have_content('Delete board')
      end
    end
  end

  def assert_boards_nav_active
    expect(find('.nav-sidebar .active .active')).to have_selector('a', text: 'Boards')
  end
end
