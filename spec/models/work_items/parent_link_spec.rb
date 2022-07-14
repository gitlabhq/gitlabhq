# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WorkItems::ParentLink do
  describe 'associations' do
    it { is_expected.to belong_to(:work_item) }
    it { is_expected.to belong_to(:work_item_parent).class_name('WorkItem') }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:work_item) }
    it { is_expected.to validate_presence_of(:work_item_parent) }

    describe 'hierarchy' do
      let_it_be(:project) { create(:project) }
      let_it_be(:issue) { build(:work_item, project: project) }
      let_it_be(:incident) { build(:work_item, :incident, project: project) }
      let_it_be(:task1) { build(:work_item, :task, project: project) }
      let_it_be(:task2) { build(:work_item, :task, project: project) }

      it 'is valid if issue parent has task child' do
        expect(build(:parent_link, work_item: task1, work_item_parent: issue)).to be_valid
      end

      it 'is valid if incident parent has task child' do
        expect(build(:parent_link, work_item: task1, work_item_parent: incident)).to be_valid
      end

      it 'is not valid if child is not task' do
        link = build(:parent_link, work_item: issue)

        expect(link).not_to be_valid
        expect(link.errors[:work_item]).to include('only Task can be assigned as a child in hierarchy.')
      end

      it 'is not valid if parent is task' do
        link = build(:parent_link, work_item_parent: task1)

        expect(link).not_to be_valid
        expect(link.errors[:work_item_parent]).to include('only Issue and Incident can be parent of Task.')
      end

      it 'is not valid if parent is in other project' do
        link = build(:parent_link, work_item_parent: task1, work_item: build(:work_item))

        expect(link).not_to be_valid
        expect(link.errors[:work_item_parent]).to include('parent must be in the same project as child.')
      end

      context 'when parent already has maximum number of links' do
        let_it_be(:link1) { create(:parent_link, work_item_parent: issue, work_item: task1) }

        before do
          stub_const("#{described_class}::MAX_CHILDREN", 1)
        end

        it 'is not valid when another link is added' do
          link2 = build(:parent_link, work_item_parent: issue, work_item: task2)

          expect(link2).not_to be_valid
          expect(link2.errors[:work_item_parent]).to include('parent already has maximum number of children.')
        end

        it 'existing link is still valid' do
          expect(link1).to be_valid
        end
      end
    end
  end
end
