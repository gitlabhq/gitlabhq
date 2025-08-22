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

    describe 'hierarchy validations' do
      let_it_be(:issue) { create(:work_item, project: project) }
      let_it_be(:task1) { create(:work_item, :task, project: project) }
      let_it_be(:task2) { build(:work_item, :task, project: project) }

      describe '#validate_hierarchy_restrictions' do
        it 'prevents invalid parent-child type combinations' do
          task = create(:work_item, :task, project: project)
          issue = create(:work_item, :issue, project: project)
          link = build(:parent_link, work_item_parent: task, work_item: issue)

          expect(link).not_to be_valid
          expect(link.errors[:work_item]).to include("it's not allowed to add this type of parent item")
        end
      end

      describe '#validate_depth' do
        it_behaves_like 'validates hierarchy depth', :epic, 7
        it_behaves_like 'validates hierarchy depth', :objective, 9

        context 'with cross-type hierarchies (objective to key_result)' do
          let_it_be(:objective1) { create(:work_item, :objective, project: project) }
          let_it_be(:key_result) { create(:work_item, :key_result, project: project) }
          let_it_be(:objective3) { create(:work_item, :objective, project: project) }

          it 'validates maximum depth of 1 for key_results under objectives' do
            create(:parent_link, work_item_parent: objective1, work_item: key_result)

            key_result2 = create(:work_item, :key_result, project: project)
            link = build(:parent_link, work_item_parent: key_result, work_item: key_result2)

            expect(link).not_to be_valid
          end
        end
      end

      describe '#validate_cyclic_reference' do
        let_it_be(:epic_a) { create(:work_item, :epic, project: project) }
        let_it_be(:epic_b) { create(:work_item, :epic, project: project) }
        let_it_be(:epic_c) { create(:work_item, :epic, project: project) }

        before do
          # Create a chain: epic_a -> epic_b -> epic_c
          create(:parent_link, work_item_parent: epic_a, work_item: epic_b)
          create(:parent_link, work_item_parent: epic_b, work_item: epic_c)
        end

        it 'is not valid if parent and child are same' do
          link = build(:parent_link, work_item_parent: epic_a, work_item: epic_a)

          expect(link).not_to be_valid
          expect(link.errors[:work_item]).to include('is not allowed to point to itself')
        end

        it 'is not valid if child is already in ancestors' do
          # epic_c is a descendant of epic_a, so epic_a cannot be a child of epic_c
          link = build(:parent_link, work_item_parent: epic_c, work_item: epic_a)

          expect(link).not_to be_valid
          expect(link.errors[:work_item]).to include("it's already present in this item's hierarchy")
        end
      end

      describe '#validate_max_children' do
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

      describe '#check_existing_related_link' do
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

      describe '#validate_confidentiality' do
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
