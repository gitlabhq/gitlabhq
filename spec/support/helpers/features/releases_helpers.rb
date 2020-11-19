# frozen_string_literal: true

# These helpers fill fields on the "New Release" and
# "Edit Release" pages. They use the keyboard to navigate
# from one field to the next and assume that when
# they are called, the field to be filled out is already focused.
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
          # Returns the element that currently has keyboard focus.
          # Reminder that this returns a Selenium::WebDriver::Element
          # _not_ a Capybara::Node::Element
          def focused_element
            page.driver.browser.switch_to.active_element
          end

          def fill_tag_name(tag_name, and_tab: true)
            expect(focused_element).to eq(find_field('Tag name').native)

            focused_element.send_keys(tag_name)

            focused_element.send_keys(:tab) if and_tab
          end

          def select_create_from(branch_name, and_tab: true)
            expect(focused_element).to eq(find('[data-testid="create-from-field"] button').native)

            focused_element.send_keys(:enter)

            # Wait for the dropdown to be rendered
            page.find('.ref-selector .dropdown-menu')

            # Pressing Enter in the search box shouldn't submit the form
            focused_element.send_keys(branch_name, :enter)

            # Wait for the search to return
            page.find('.ref-selector .dropdown-item', text: branch_name, match: :first)

            focused_element.send_keys(:arrow_down, :enter)

            focused_element.send_keys(:tab) if and_tab
          end

          def fill_release_title(release_title, and_tab: true)
            expect(focused_element).to eq(find_field('Release title').native)

            focused_element.send_keys(release_title)

            focused_element.send_keys(:tab) if and_tab
          end

          def select_milestone(milestone_title, and_tab: true)
            expect(focused_element).to eq(find('[data-testid="milestones-field"] button').native)

            focused_element.send_keys(:enter)

            # Wait for the dropdown to be rendered
            page.find('.milestone-combobox .dropdown-menu')

            # Clear any existing input
            focused_element.attribute('value').length.times { focused_element.send_keys(:backspace) }

            # Pressing Enter in the search box shouldn't submit the form
            focused_element.send_keys(milestone_title, :enter)

            # Wait for the search to return
            page.find('.milestone-combobox .dropdown-item', text: milestone_title, match: :first)

            focused_element.send_keys(:arrow_down, :arrow_down, :enter)

            focused_element.send_keys(:tab) if and_tab
          end

          def fill_release_notes(release_notes, and_tab: true)
            expect(focused_element).to eq(find_field('Release notes').native)

            focused_element.send_keys(release_notes)

            # Tab past the links at the bottom of the editor
            focused_element.send_keys(:tab, :tab, :tab) if and_tab
          end

          def fill_asset_link(link, and_tab: true)
            expect(focused_element['id']).to start_with('asset-url-')

            focused_element.send_keys(link[:url], :tab, link[:title], :tab, link[:type])

            # Tab past the "Remove asset link" button
            focused_element.send_keys(:tab, :tab) if and_tab
          end

          # Click "Add another link" and tab back to the beginning of the new row
          def add_another_asset_link
            expect(focused_element).to eq(find_button('Add another link').native)

            focused_element.send_keys(:enter,
                                      [:shift, :tab],
                                      [:shift, :tab],
                                      [:shift, :tab],
                                      [:shift, :tab])
          end
        end
      end
    end
  end
end
