# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WikiDirectory do
  subject(:directory) { build(:wiki_directory) }

  describe 'validations' do
    it { is_expected.to validate_presence_of(:slug) }
  end

  describe '.group_pages' do
    let_it_be(:toplevel1) { build(:wiki_page, title: 'aaa-toplevel1') }
    let_it_be(:toplevel2) { build(:wiki_page, title: 'zzz-toplevel2') }
    let_it_be(:toplevel3) { build(:wiki_page, title: 'zzz-toplevel3') }
    let_it_be(:home) { build(:wiki_page, title: 'home') }
    let_it_be(:homechild) { build(:wiki_page, title: 'Home/homechild') }
    let_it_be(:parent1) { build(:wiki_page, title: 'parent1') }
    let_it_be(:parent2) { build(:wiki_page, title: 'parent2') }
    let_it_be(:child1) { build(:wiki_page, title: 'parent1/child1') }
    let_it_be(:child2) { build(:wiki_page, title: 'parent1/child2') }
    let_it_be(:child3) { build(:wiki_page, title: 'parent2/child3') }
    let_it_be(:subparent) { build(:wiki_page, title: 'parent1/subparent') }
    let_it_be(:grandchild1) { build(:wiki_page, title: 'parent1/subparent/grandchild1') }
    let_it_be(:grandchild2) { build(:wiki_page, title: 'parent1/subparent/grandchild2') }

    it 'returns a nested array of entries' do
      entries = described_class.group_pages(
        [toplevel1, toplevel2, toplevel3, home, homechild,
          parent1, parent2, child1, child2, child3,
          subparent, grandchild1, grandchild2].sort_by(&:title)
      )

      expect(entries).to match(
        [
          a_kind_of(described_class).and(
            having_attributes(
              slug: 'Home', entries: [homechild]
            )
          ),
          toplevel1,
          a_kind_of(described_class).and(
            having_attributes(
              slug: 'parent1', entries: [
                child1,
                child2,
                a_kind_of(described_class).and(
                  having_attributes(
                    slug: 'parent1/subparent',
                    entries: [grandchild1, grandchild2]
                  )
                )
              ]
            )
          ),
          a_kind_of(described_class).and(
            having_attributes(
              slug: 'parent2',
              entries: [child3]
            )
          ),
          toplevel2,
          toplevel3
        ])
    end
  end

  describe '#initialize' do
    context 'when there are entries' do
      let(:entries) { [build(:wiki_page)] }
      let(:directory) { described_class.new('/path_up_to/dir', entries) }

      it 'sets the slug attribute' do
        expect(directory.slug).to eq('/path_up_to/dir')
      end

      it 'sets the entries attribute' do
        expect(directory.entries).to eq(entries)
      end
    end

    context 'when there are no entries' do
      let(:directory) { described_class.new('/path_up_to/dir') }

      it 'sets the slug attribute' do
        expect(directory.slug).to eq('/path_up_to/dir')
      end

      it 'sets the entries attribute to an empty array' do
        expect(directory.entries).to eq([])
      end
    end
  end

  describe '#title' do
    it 'returns the basename of the directory, with hyphens replaced by spaces' do
      directory.slug = 'parent'
      expect(directory.title).to eq('parent')

      directory.slug = 'parent/child'
      expect(directory.title).to eq('child')

      directory.slug = 'parent/child-foo'
      expect(directory.title).to eq('child foo')
    end
  end

  describe '#to_partial_path' do
    it 'returns the relative path to the partial to be used' do
      expect(directory.to_partial_path).to eq('shared/wikis/wiki_directory')
    end
  end
end
