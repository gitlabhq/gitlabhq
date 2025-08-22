# frozen_string_literal: true

RSpec.shared_examples 'validates hierarchy depth' do |work_item_type, max_depth|
  describe "#{work_item_type} hierarchy" do
    it "allows creating hierarchies up to maximum depth of #{max_depth}" do
      work_items = (1..max_depth).map { create(:work_item, work_item_type, project: project) }

      (max_depth - 2).times do |i|
        create(:parent_link, work_item_parent: work_items[i], work_item: work_items[i + 1])
      end

      link = build(:parent_link, work_item_parent: work_items[max_depth - 2], work_item: work_items[max_depth - 1])
      expect(link).to be_valid
    end

    it "is not valid when maximum depth of #{max_depth} is exceeded" do
      work_items = create_list(:work_item, max_depth + 1, work_item_type, project: project)

      (max_depth - 1).times do |i|
        create(:parent_link, work_item_parent: work_items[i], work_item: work_items[i + 1])
      end

      link = build(:parent_link, work_item_parent: work_items[max_depth - 1], work_item: work_items[max_depth])

      expect(link).not_to be_valid
      expect(link.errors[:work_item]).to include('reached maximum depth')
    end
  end
end
