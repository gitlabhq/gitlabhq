# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WorkItems::ParentLink, feature_category: :portfolio_management do
  let_it_be(:project) { create(:project) }

  describe 'associations' do
    it { is_expected.to belong_to(:work_item) }
    it { is_expected.to belong_to(:work_item_parent).class_name('WorkItem') }
  end

  describe 'validations' do
    subject { build(:parent_link) }

    it { is_expected.to validate_presence_of(:work_item) }
    it { is_expected.to validate_presence_of(:work_item_parent) }
    it { is_expected.to validate_uniqueness_of(:work_item) }

    describe 'hierarchy' do
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

      shared_examples_for 'checks valid types' do
        it 'validates if child can be added to the parent' do
          parent_type = WorkItems::Type.default_by_type(parent_type_sym)
          child_type = WorkItems::Type.default_by_type(child_type_sym)
          parent = build(:work_item, issue_type: parent_type_sym, work_item_type: parent_type, project: project)
          child = build(:work_item, issue_type: child_type_sym, work_item_type: child_type, project: project)
          link = build(:parent_link, work_item: child, work_item_parent: parent)

          expect(link.valid?).to eq(is_valid)
        end
      end

      context 'when assigning to various parent types' do
        using RSpec::Parameterized::TableSyntax

        where(:parent_type_sym, :child_type_sym, :is_valid) do
          :issue      | :task       | true
          :incident   | :task       | true
          :task       | :issue      | false
          :issue      | :issue      | false
          :objective  | :objective  | true
          :objective  | :key_result | true
          :key_result | :objective  | false
          :key_result | :key_result | false
          :objective  | :issue      | false
          :task       | :objective  | false
        end

        with_them do
          it_behaves_like 'checks valid types'
        end
      end

      context 'when hierarchy_db_restrictions is disabled' do
        before do
          stub_feature_flags(hierarchy_db_restrictions: false)
        end

        using RSpec::Parameterized::TableSyntax

        where(:parent_type_sym, :child_type_sym, :is_valid) do
          :issue      | :task       | true
          :incident   | :task       | true
          :task       | :issue      | false
          :issue      | :issue      | false
          :objective  | :objective  | false
          :objective  | :key_result | false
          :key_result | :objective  | false
          :key_result | :key_result | false
          :objective  | :issue      | false
          :task       | :objective  | false
        end

        with_them do
          it_behaves_like 'checks valid types'
        end
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

      context 'when setting confidentiality' do
        using RSpec::Parameterized::TableSyntax

        where(:confidential_parent, :confidential_child, :valid) do
          false | false | true
          true  | true  | true
          false | true  | true
          true  | false | false
        end

        with_them do
          before do
            issue.confidential = confidential_parent
            task1.confidential = confidential_child
          end

          it 'validates if child confidentiality is compatible with parent' do
            link = build(:parent_link, work_item_parent: issue, work_item: task1)

            expect(link.valid?).to eq(valid)
          end
        end
      end
    end
  end

  context 'with confidential work items' do
    let_it_be(:confidential_child) { create(:work_item, :task, confidential: true, project: project) }
    let_it_be(:putlic_child) { create(:work_item, :task, project: project) }
    let_it_be(:confidential_parent) { create(:work_item, confidential: true, project: project) }
    let_it_be(:public_parent) { create(:work_item, project: project) }

    describe '.has_public_children?' do
      subject { described_class.has_public_children?(public_parent.id) }

      context 'with confidential child' do
        let_it_be(:link) { create(:parent_link, work_item_parent: public_parent, work_item: confidential_child) }

        it { is_expected.to be_falsey }

        context 'with also public child' do
          let_it_be(:link) { create(:parent_link, work_item_parent: public_parent, work_item: putlic_child) }

          it { is_expected.to be_truthy }
        end
      end
    end

    describe '.has_confidential_parent?' do
      subject { described_class.has_confidential_parent?(confidential_child.id) }

      context 'with confidential parent' do
        let_it_be(:link) { create(:parent_link, work_item_parent: confidential_parent, work_item: confidential_child) }

        it { is_expected.to be_truthy }
      end

      context 'with public parent' do
        let_it_be(:link) { create(:parent_link, work_item_parent: public_parent, work_item: confidential_child) }

        it { is_expected.to be_falsey }
      end
    end
  end
end
