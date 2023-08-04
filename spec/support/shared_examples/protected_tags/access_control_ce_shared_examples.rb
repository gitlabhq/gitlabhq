# frozen_string_literal: true

RSpec.shared_examples "protected tags > access control > CE" do
  ProtectedRef::AccessLevel.human_access_levels.each do |(access_type_id, access_type_name)|
    it "allows creating protected tags that #{access_type_name} can create" do
      visit project_protected_tags_path(project)
      click_button('Add tag')

      set_protected_tag_name('master')
      set_allowed_to('create', access_type_name)
      click_on_protect

      expect(ProtectedTag.count).to eq(1)
      expect(ProtectedTag.last.create_access_levels.map(&:access_level)).to eq([access_type_id])
    end

    it "allows updating protected tags so that #{access_type_name} can create them" do
      visit project_protected_tags_path(project)
      click_button('Add tag')

      set_protected_tag_name('master')
      set_allowed_to('create', 'No one')
      click_on_protect

      expect(ProtectedTag.count).to eq(1)

      set_allowed_to('create', access_type_name, form: '.protected-tags-list')

      wait_for_requests

      expect(ProtectedTag.last.create_access_levels.map(&:access_level)).to include(access_type_id)
    end
  end
end
