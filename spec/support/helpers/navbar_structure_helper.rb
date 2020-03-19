# frozen_string_literal: true

module NavbarStructureHelper
  def insert_after_nav_item(before_nav_item_name, new_nav_item:)
    expect(structure).to include(a_hash_including(nav_item: before_nav_item_name))

    index = structure.find_index { |h| h[:nav_item] == before_nav_item_name }
    structure.insert(index + 1, new_nav_item)
  end

  def insert_after_sub_nav_item(before_sub_nav_item_name, within:, new_sub_nav_item_name:)
    expect(structure).to include(a_hash_including(nav_item: within))
    hash = structure.find { |h| h[:nav_item] == within }

    expect(hash).to have_key(:nav_sub_items)
    expect(hash[:nav_sub_items]).to include(before_sub_nav_item_name)

    index = hash[:nav_sub_items].find_index(before_sub_nav_item_name)
    hash[:nav_sub_items].insert(index + 1, new_sub_nav_item_name)
  end
end
