# frozen_string_literal: true

RSpec.shared_examples 'includes LinkableItem concern' do
  describe 'validation' do
    let_it_be(:task) { create(:work_item, :task, project: project) }
    let_it_be(:issue) { create(:work_item, :issue, project: project) }

    subject(:link) { build(link_factory, source_id: source.id, target_id: target.id) }

    describe '#check_existing_parent_link' do
      context 'for new issuable link' do
        shared_examples 'invalid due to existing link' do
          it do
            is_expected.to be_invalid
            expect(link.errors.messages[:source]).to include("is a parent or child of this #{item_type}")
          end
        end

        context 'without existing link parent' do
          let(:source) { issue }
          let(:target) { task }

          it 'is valid' do
            is_expected.to be_valid
            expect(link.errors).to be_empty
          end
        end

        context 'with existing link parent' do
          let_it_be(:relationship) { create(:parent_link, work_item_parent: issue, work_item: task) }

          it_behaves_like 'invalid due to existing link' do
            let(:source) { issue }
            let(:target) { task }
          end

          it_behaves_like 'invalid due to existing link' do
            let(:source) { task }
            let(:target) { issue }
          end
        end
      end

      context 'for existing issuable link with existing parent link' do
        let(:link) { build(link_factory, source_id: source.id, target_id: target.id) }

        before do
          create(:parent_link, work_item_parent: issue, work_item: task)
          link.save!(validate: false)
        end

        context 'when source is issue' do
          let(:source) { issue }
          let(:target) { task }

          it 'is valid' do
            expect(link).to be_valid
            expect(link.errors).to be_empty
          end
        end

        context 'when source is task' do
          let(:source) { task }
          let(:target) { issue }

          it 'is valid' do
            expect(link).to be_valid
            expect(link.errors).to be_empty
          end
        end
      end
    end
  end

  describe 'Scopes' do
    describe '.for_source' do
      it 'includes linked items for source' do
        source = item
        link_1 = create(link_factory, source: source, target: item1)
        link_2 = create(link_factory, source: source, target: item2)

        result = described_class.for_source(source)

        expect(result).to contain_exactly(link_1, link_2)
      end
    end

    describe '.for_target' do
      it 'includes linked items for target' do
        target = item
        link_1 = create(link_factory, source: item1, target: target)
        link_2 = create(link_factory, source: item2, target: target)

        result = described_class.for_target(target)

        expect(result).to contain_exactly(link_1, link_2)
      end
    end

    describe '.for_items' do
      let_it_be(:source_link) { create(link_factory, source: item, target: item1) }
      let_it_be(:target_link) { create(link_factory, source: item2, target: item) }

      it 'includes links when item is source' do
        expect(described_class.for_items(item, item1)).to contain_exactly(source_link)
      end

      it 'includes links when item is target' do
        expect(described_class.for_items(item, item2)).to contain_exactly(target_link)
      end
    end

    describe '.for_source_and_target' do
      let_it_be(:item3) { create(:work_item, project: project) }
      let_it_be(:link1) { create(link_factory, source: item, target: item1) }
      let_it_be(:link2) { create(link_factory, source: item, target: item2) }
      let_it_be(:link3) { create(link_factory, source: item, target: item3) }

      it 'includes links for provided source and target' do
        expect(described_class.for_source_and_target(item, [item1, item2])).to contain_exactly(link1, link2)
      end
    end
  end
end
