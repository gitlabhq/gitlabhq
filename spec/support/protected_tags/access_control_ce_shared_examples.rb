RSpec.shared_examples "protected tags > access control > CE" do
  ProtectedRefAccess::HUMAN_ACCESS_LEVELS.each do |(access_type_id, access_type_name)|
    it "allows creating protected tags that #{access_type_name} can create" do
      visit project_protected_tags_path(project)

      set_protected_tag_name('master')

      within('.js-new-protected-tag') do
        allowed_to_create_button = find(".js-allowed-to-create")

        unless allowed_to_create_button.text == access_type_name
          allowed_to_create_button.click
          find('.create_access_levels-container .dropdown-menu li', match: :first)
          within('.create_access_levels-container .dropdown-menu') { click_on access_type_name }
        end
      end

      click_on "Protect"

      expect(ProtectedTag.count).to eq(1)
      expect(ProtectedTag.last.create_access_levels.map(&:access_level)).to eq([access_type_id])
    end

    it "allows updating protected tags so that #{access_type_name} can create them" do
      visit project_protected_tags_path(project)

      set_protected_tag_name('master')

      click_on "Protect"

      expect(ProtectedTag.count).to eq(1)

      within(".protected-tags-list") do
        find(".js-allowed-to-create").click

        within('.js-allowed-to-create-container') do
          expect(first("li")).to have_content("Roles")
          click_on access_type_name
        end
      end

      wait_for_requests

      expect(ProtectedTag.last.create_access_levels.map(&:access_level)).to include(access_type_id)
    end
  end
end
