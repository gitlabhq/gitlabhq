# frozen_string_literal: true

# These helpers fill fields on the "New Release" and "Edit Release" pages.
#
# Usage:
#   describe "..." do
#     include Spec::Support::Helpers::Features::ReleasesHelpers
#     ...
#
#     fill_tag_name("v1.0")
#     select_create_from("my-feature-branch")
#
module Spec
  module Support
    module Helpers
      module Features
        module ReleasesHelpers
          def select_new_tag_name(tag_name)
            page.within '[data-testid="tag-name-field"]' do
              find('button').click

              wait_for_all_requests

              find('input[aria-label="Search or create tag"]').set(tag_name)

              wait_for_all_requests

              click_button("Create tag #{tag_name}")
            end
          end

          def select_create_from(branch_name)
            page.within '[data-testid="create-from-field"]' do
              find('button').click

              wait_for_all_requests

              find('input[aria-label="Search branches, tags, and commits"]').set(branch_name)

              wait_for_all_requests

              click_button("#{branch_name}")
            end
          end

          def fill_release_title(release_title)
            fill_in('Release title', with: release_title)
          end

          def select_milestone(milestone_title)
            page.within '[data-testid="milestones-field"]' do
              find('button').click

              wait_for_all_requests

              find('input[aria-label="Search Milestones"]').set(milestone_title)

              wait_for_all_requests

              find('button', text: milestone_title, match: :first).click
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
        end
      end
    end
  end
end
