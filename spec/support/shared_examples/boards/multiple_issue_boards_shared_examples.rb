# frozen_string_literal: true

RSpec.shared_examples 'multiple issue boards' do
  context 'authorized user' do
    before do
      stub_feature_flags(board_new_list: false)

      parent.add_maintainer(user)

      login_as(user)

      stub_feature_flags(board_new_list: false)

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
        click_link board2.name
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

      in_boards_switcher_dropdown do
        click_link board.name
      end

      wait_for_requests

      expect(page).to have_selector('.board', count: 2)
    end

    it 'maintains sidebar state over board switch' do
      assert_boards_nav_active

      in_boards_switcher_dropdown do
        click_link board2.name
      end

      assert_boards_nav_active
    end
  end

  context 'unauthorized user' do
    before do
      visit boards_path
      wait_for_requests
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

    dropdown_selector = '.js-boards-selector .dropdown-menu'
    page.within(dropdown_selector) do
      yield
    end
  end

  def assert_boards_nav_active
    expect(find('.nav-sidebar .active .active')).to have_selector('a', text: 'Boards')
  end
end
