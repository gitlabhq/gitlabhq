# frozen_string_literal: true

# These helpers fill fields on the "New Release" and "Edit Release" pages.
#
# Usage:
#   describe "..." do
#     include Features::ReleasesHelpers
#     ...
#
#     fill_tag_name("v1.0")
#     select_create_from("my-feature-branch")
#
module Features
  module ReleasesHelpers
    include ListboxHelpers

    def select_new_tag_name(tag_name)
      open_tag_popover

      page.within '[data-testid="tag-name-search"]' do
        find('input[type="search"]').set(tag_name)
        wait_for_all_requests

        click_button("Create tag #{tag_name}")
      end
    end

    def select_create_from(branch_name)
      open_tag_popover

      page.within '[data-testid="create-from-field"]' do
        find('.ref-selector button').click

        wait_for_all_requests

        find('input[aria-label="Search branches, tags, and commits"]').set(branch_name)

        wait_for_all_requests

        select_listbox_item(branch_name.to_s, exact_text: true)

        click_button _('Save')
      end
    end

    def fill_release_title(release_title)
      fill_in('release-title', with: release_title)
    end

    def select_milestones(*milestone_titles)
      within_testid 'milestones-field' do
        find_by_testid('base-dropdown-toggle').click

        wait_for_all_requests

        milestone_titles.each do |milestone_title|
          find('input[type="search"]').set(milestone_title)

          wait_for_all_requests

          find('[role="option"]', text: milestone_title).click
        end
      end
    end

    def fill_release_notes(release_notes)
      fill_in('Release notes', with: release_notes)
    end

    def fill_asset_link(link)
      all('input[name="asset-url"]').last.set(link[:url])
      all('input[name="asset-link-name"]').last.set(link[:title])
      all('select[name="asset-type"]').last.find("option[value=\"#{link[:type]}\"").select_option
    end

    # Click "Add another link" and tab back to the beginning of the new row
    def add_another_asset_link
      click_button('Add another link')
    end

    def open_tag_popover(name = s_('Release|Search or create tag name'))
      return if page.has_css? '.release-tag-selector'

      click_button name
      wait_for_all_requests
    end
  end
end
