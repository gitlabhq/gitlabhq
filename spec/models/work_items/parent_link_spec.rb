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
      let_it_be(:issue) { create(:work_item, project: project) }
      let_it_be(:incident) { build(:work_item, :incident, project: project) }
      let_it_be(:task1) { create(:work_item, :task, project: project) }
      let_it_be(:task2) { build(:work_item, :task, project: project) }

      it 'is valid if issue parent has task child' do
        expect(build(:parent_link, work_item: task1, work_item_parent: issue)).to be_valid
      end

      it 'is valid if incident parent has task child' do
        expect(build(:parent_link, work_item: task1, work_item_parent: incident)).to be_valid
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
          it 'validates if child can be added to the parent' do
            parent_type = WorkItems::Type.default_by_type(parent_type_sym)
            child_type = WorkItems::Type.default_by_type(child_type_sym)
            parent = build(:work_item, work_item_type: parent_type, project: project)
            child = build(:work_item, work_item_type: child_type, project: project)
            link = build(:parent_link, work_item: child, work_item_parent: parent)

            expect(link.valid?).to eq(is_valid)
          end
        end
      end

      context 'with nested ancestors' do
        let_it_be(:type1) { create(:work_item_type, :non_default) }
        let_it_be(:type2) { create(:work_item_type, :non_default) }
        let_it_be(:item1) { create(:work_item, work_item_type: type1, project: project) }
        let_it_be(:item2) { create(:work_item, work_item_type: type2, project: project) }
        let_it_be(:item3) { create(:work_item, work_item_type: type2, project: project) }
        let_it_be(:item4) { create(:work_item, work_item_type: type2, project: project) }
        let_it_be(:hierarchy_restriction1) { create(:hierarchy_restriction, parent_type: type1, child_type: type2) }
        let_it_be(:hierarchy_restriction2) { create(:hierarchy_restriction, parent_type: type2, child_type: type1) }

        let_it_be(:hierarchy_restriction3) do
          create(:hierarchy_restriction, parent_type: type2, child_type: type2, maximum_depth: 2)
        end

        let_it_be(:link1) { create(:parent_link, work_item_parent: item1, work_item: item2) }
        let_it_be(:link2) { create(:parent_link, work_item_parent: item3, work_item: item4) }

        describe '#validate_depth' do
          it 'is valid if depth is in limit' do
            link = build(:parent_link, work_item_parent: item1, work_item: item3)

            expect(link).to be_valid
          end

          it 'is not valid when maximum depth is reached' do
            link = build(:parent_link, work_item_parent: item2, work_item: item3)

            expect(link).not_to be_valid
            expect(link.errors[:work_item]).to include('reached maximum depth')
          end
        end

        describe '#validate_cyclic_reference' do
          it 'is not valid if parent and child are same' do
            link1.work_item_parent = item2

            expect(link1).not_to be_valid
            expect(link1.errors[:work_item]).to include('is not allowed to point to itself')
          end

          it 'is not valid if child is already in ancestors' do
            link = build(:parent_link, work_item_parent: item4, work_item: item3)

            expect(link).not_to be_valid
            expect(link.errors[:work_item]).to include("it's already present in this item's hierarchy")
          end
        end
      end

      context 'when assigning parent from different project' do
        let_it_be(:cross_project_issue) { create(:work_item, project: create(:project)) }

        let(:restriction) do
          WorkItems::HierarchyRestriction
            .find_by_parent_type_id_and_child_type_id(cross_project_issue.work_item_type_id, task1.work_item_type_id)
        end

        it 'is valid when cross-hierarchy is enabled' do
          restriction.update!(cross_hierarchy_enabled: true)
          link = build(:parent_link, work_item_parent: cross_project_issue, work_item: task1)

          expect(link).to be_valid
          expect(link.errors).to be_empty
        end

        it 'is not valid when cross-hierarchy is not enabled' do
          restriction.update!(cross_hierarchy_enabled: false)
          link = build(:parent_link, work_item_parent: cross_project_issue, work_item: task1)

          expect(link).not_to be_valid
          expect(link.errors[:work_item_parent]).to include('parent must be in the same project or group as child.')
        end
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

        context 'when parent already exceeds maximum number of links' do
          let_it_be(:task3) { create(:work_item, :task, project: project) }
          let_it_be(:link2) { create(:parent_link, work_item_parent: issue, work_item: task2) }

          it 'only invalidates new links' do
            link3 = build(:parent_link, work_item_parent: issue, work_item: task3)

            expect(link3).not_to be_valid
            expect(link3.errors[:work_item_parent]).to include('parent already has maximum number of children.')

            expect(link1).to be_valid
            expect(link2).to be_valid
          end
        end
      end

      context 'when parent is already linked' do
        shared_examples 'invalid link' do |link_factory|
          let_it_be(:parent_link) { build(:parent_link, work_item_parent: issue, work_item: task1) }
          let(:error_msg) { 'cannot assign a linked work item as a parent' }

          context 'when creating new link' do
            context 'when parent is the link target' do
              before do
                create(link_factory, source_id: task1.id, target_id: issue.id)
              end

              it do
                expect(parent_link).not_to be_valid
                expect(parent_link.errors[:work_item]).to include(error_msg)
              end
            end

            context 'when parent is the link source' do
              before do
                create(link_factory, source_id: issue.id, target_id: task1.id)
              end

              it do
                expect(parent_link).not_to be_valid
                expect(parent_link.errors[:work_item]).to include(error_msg)
              end
            end
          end

          context 'when updating existing link' do
            context 'when parent is the link target' do
              before do
                create(link_factory, source_id: task1.id, target_id: issue.id)
                parent_link.save!(validate: false)
              end

              it do
                expect(parent_link).to be_valid
                expect(parent_link.errors[:work_item]).not_to include(error_msg)
              end
            end

            context 'when parent is the link source' do
              before do
                create(link_factory, source_id: issue.id, target_id: task1.id)
                parent_link.save!(validate: false)
              end

              it do
                expect(parent_link).to be_valid
                expect(parent_link.errors[:work_item]).not_to include(error_msg)
              end
            end
          end
        end

        it_behaves_like 'invalid link', :work_item_link
        it_behaves_like 'invalid link', :issue_link
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

        context 'when parent is confidential' do
          before do
            issue.confidential = true
            task1.confidential = false
          end

          it 'sets the correct error message' do
            link = build(:parent_link, work_item_parent: issue, work_item: task1)

            link.valid?

            expect(link.errors[:work_item]).to include(
              'cannot assign a non-confidential task to a confidential parent. ' \
                'Make the task confidential and try again.')
          end
        end
      end
    end
  end

  describe 'scopes' do
    let_it_be(:project) { create(:project) }
    let_it_be(:issue1) { build(:work_item, project: project) }
    let_it_be(:issue2) { build(:work_item, project: project) }
    let_it_be(:issue3) { build(:work_item, project: project) }
    let_it_be(:task1) { build(:work_item, :task, project: project) }
    let_it_be(:task2) { build(:work_item, :task, project: project) }
    let_it_be(:link1) { create(:parent_link, work_item_parent: issue1, work_item: task1) }
    let_it_be(:link2) { create(:parent_link, work_item_parent: issue2, work_item: task2) }

    describe 'for_parents' do
      it 'includes the correct records' do
        result = described_class.for_parents([issue1.id, issue2.id, issue3.id])

        expect(result).to include(link1, link2)
      end
    end

    describe 'for_children' do
      it 'includes the correct records' do
        result = described_class.for_children([task1.id, task2.id])

        expect(result).to include(link1, link2)
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

  context 'with relative positioning' do
    let_it_be(:group) { create(:group) }
    let_it_be(:project) { create(:project, group: group) }
    let_it_be(:work_item_parent) { create(:work_item, project: project) }

    it_behaves_like "a class that supports relative positioning" do
      let(:factory) { :parent_link }
      let(:default_params) { { work_item_parent: work_item_parent } }
      let(:items_with_nil_position_sample_quantity) { 90 }
    end
  end
end
