# frozen_string_literal: true

module Features
  module MembersHelpers
    def members_table
      page.find('[data-testid="members-table"]')
    end

    def all_rows
      page.within(members_table) do
        page.all('tbody > tr')
      end
    end

    def first_row
      all_rows[0]
    end

    def second_row
      all_rows[1]
    end

    def third_row
      all_rows[2]
    end

    def find_row(name)
      page.within(members_table) do
        page.find('tbody > tr', text: name)
      end
    end

    def find_member_row(user)
      find_row(user.name)
    end

    def find_username_row(user)
      find_row(user.username)
    end

    def find_invited_member_row(email)
      find_row(email)
    end

    def find_group_row(group)
      find_row(group.full_name)
    end

    def fill_in_filtered_search(label, with:)
      page.within '[data-testid="members-filtered-search-bar"]' do
        find_field(label).click
        find('input').native.send_keys(with)
        click_button 'Search'
      end
    end

    def user_action_dropdown
      '[data-testid="user-action-dropdown"]'
    end

    def show_actions
      within user_action_dropdown do
        find('button').click
      end
    end

    def show_actions_for_username(user)
      within find_username_row(user) do
        show_actions
      end
    end
  end
end
