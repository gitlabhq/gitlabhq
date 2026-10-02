# frozen_string_literal: true

RSpec.shared_examples 'BaseLabel' do |factory_name: :label|
  shared_examples_for 'text input field' do |field_name|
    subject { described_class.new(field_name => input) }

    context 'when input contains HTML entities and HTML tags' do
      let(:input) { '&lt;hello&gt;<img src=x onerror=prompt(1)>' }

      it 'leaves the input unchanged' do
        # This field is not ever to be treated as HTML; it is text, never unescaped or sanitised,
        # and is always escaped when inserted into HTML directly.
        # If an XSS occurs in future which would lead you to wanting to "fix" this spec, please
        # instead fix it at the point of display, not by corrupting user input!
        expect(subject.public_send(field_name)).to eq(input)
      end
    end
  end

  describe 'validation' do
    it 'validates color code' do
      is_expected.not_to allow_value('G-ITLAB').for(:color)
      is_expected.not_to allow_value('AABBCC').for(:color)
      is_expected.not_to allow_value('#AABBCCEE').for(:color)
      is_expected.not_to allow_value('GGHHII').for(:color)
      is_expected.not_to allow_value('#').for(:color)
      is_expected.not_to allow_value('').for(:color)

      is_expected.to allow_value('#AABBCC').for(:color)
      is_expected.to allow_value('#abcdef').for(:color)
    end

    it 'validates title' do
      is_expected.not_to allow_value('G,ITLAB').for(:title)
      is_expected.not_to allow_value('').for(:title)
      is_expected.not_to allow_value('s' * 256).for(:title)

      is_expected.to allow_value('GITLAB').for(:title)
      is_expected.to allow_value('gitlab').for(:title)
      is_expected.to allow_value('G?ITLAB').for(:title)
      is_expected.to allow_value('G&ITLAB').for(:title)
      is_expected.to allow_value("customer's request").for(:title)
      is_expected.to allow_value('s' * 255).for(:title)
    end
  end

  describe '#color' do
    it 'strips color' do
      label = described_class.new(color: '   #abcdef   ')
      label.valid?

      expect(label.color).to be_color('#abcdef')
    end

    it 'uses default color if color is missing' do
      label = described_class.new(color: nil)

      expect(label.color).to be_color(Label::DEFAULT_COLOR)
    end
  end

  describe '#text_color' do
    it 'uses default color if color is missing' do
      label = described_class.new(color: nil)

      expect(label.text_color).to eq(Label::DEFAULT_COLOR.contrast)
    end
  end

  describe '#title' do
    it 'strips title' do
      label = described_class.new(title: '   label   ')
      label.valid?

      expect(label.title).to eq('label')
    end

    it_behaves_like 'text input field', :title
  end

  describe '#description' do
    it 'accepts an empty string' do
      label = described_class.new(title: 'foo', description: '')
      label.valid?

      expect(label.errors[:description]).to be_empty
    end

    it_behaves_like 'text input field', :description
  end

  describe '.search' do
    let_it_be(:label, freeze: false) { create(factory_name, title: 'bug', description: 'incorrect behavior') }
    let_it_be(:other_label, freeze: false) { create(factory_name, title: 'test', description: 'bug') }

    it 'returns labels with a partially matching title' do
      expect(described_class.search(label.title[0..2])).to match_array([label, other_label])
    end

    it 'returns labels with a partially matching description' do
      expect(described_class.search(label.description[0..5])).to eq([label])
    end

    it 'returns nothing' do
      expect(described_class.search('feature')).to be_empty
    end

    context 'when search within unknown fields' do
      it 'falls back to search in title and description' do
        labels = described_class.search('bug', search_in: [:created_at])

        expect(labels).to match_array([label, other_label])
      end

      context 'when search known field but as string' do
        it 'falls back to search in title and description' do
          labels = described_class.search('bug', search_in: ['title'])

          expect(labels).to match_array([label, other_label])
        end
      end
    end

    context 'when searching title only' do
      it 'returns only title matches' do
        labels = described_class.search('bug', search_in: [:title])

        expect(labels).to match_array([label])
      end
    end

    context 'when searching description only' do
      it 'returns only description matches' do
        labels = described_class.search('bug', search_in: [:description])

        expect(labels).to match_array([other_label])
      end
    end

    context 'with fuzzy_search' do
      let_it_be(:scoped_label, freeze: false) { create(factory_name, title: 'bug::ux', description: 'design bugs') }

      it 'matches labels containing the searched characters in order' do
        labels = described_class.search('bgux', search_in: [:title], fuzzy_search: true)

        expect(labels).to match_array([scoped_label])
      end

      it 'ignores whitespace in the query' do
        labels = described_class.search('bug ux', search_in: [:title], fuzzy_search: true)

        expect(labels).to match_array([scoped_label])
      end

      it 'escapes LIKE wildcard characters' do
        labels = described_class.search('b%g', search_in: [:title], fuzzy_search: true)

        expect(labels).to be_empty
      end

      it 'does not match when characters are out of order' do
        labels = described_class.search('xugb', search_in: [:title], fuzzy_search: true)

        expect(labels).to be_empty
      end

      it 'is not used when the option is absent' do
        labels = described_class.search('bgux', search_in: [:title])

        expect(labels).to be_empty
      end
    end
  end

  describe '.order_contiguous_matches_first' do
    let_it_be(:caravan, freeze: false) { create(factory_name, title: 'Caravan') }
    let_it_be(:caprice, freeze: false) { create(factory_name, title: 'Caprice') }
    let_it_be(:cellar, freeze: false) { create(factory_name, title: 'Cellar') }

    subject(:ordered) do
      described_class.search('car', search_in: [:title], fuzzy_search: true)
                     .order_contiguous_matches_first('car', search_in: [:title])
    end

    it 'places contiguous matches before subsequence-only matches' do
      expect(ordered.first).to eq(caravan)
    end

    it 'orders each group alphabetically' do
      expect(ordered.map(&:title)).to eq(%w[Caravan Caprice Cellar])
    end

    it 'keeps contiguous matches when the result set is truncated' do
      expect(ordered.limit(1)).to contain_exactly(caravan)
    end

    it 'produces a keyset-paginatable relation' do
      expect(Gitlab::Pagination::Keyset::Order.keyset_aware?(ordered)).to be(true)
    end

    it 'exposes the projected contiguous value for cursor extraction' do
      order = Gitlab::Pagination::Keyset::Order.extract_keyset_order_object(ordered)

      cursor = order.cursor_attributes_for_node(ordered.first)

      expect(cursor.keys).to contain_exactly('contiguous', 'title', 'id')
      expect(cursor['contiguous']).to be_present
    end

    # Regression: a boolean `contiguous` value round-tripped through the JSON
    # cursor as true/false, which the keyset WHERE clause could not compare
    # against the boolean expression without a cast, so the page boundary
    # repeated rows. An integer 1/0 value avoids the ambiguity.
    it 'paginates past the first page without repeating rows' do
      order = Gitlab::Pagination::Keyset::Order.extract_keyset_order_object(ordered)

      first_page = ordered.limit(2).to_a
      cursor = order.cursor_attributes_for_node(first_page.last)
      second_page = order.apply_cursor_conditions(ordered, cursor).limit(2).to_a

      expect(first_page).to eq([caravan, caprice])
      expect(second_page).to eq([cellar])
    end

    it 'escapes LIKE wildcard characters' do
      literal = create(factory_name, title: 'A 100% match')
      labels = described_class.where(id: [literal.id, caravan.id])
                              .order_contiguous_matches_first('100%', search_in: [:title])

      expect(labels.first).to eq(literal)
    end

    context 'when searching description' do
      let_it_be(:described, freeze: false) do
        create(factory_name, title: 'Zebra', description: 'a car we own')
      end

      it 'treats a contiguous description match as contiguous' do
        labels = described_class.search('car', search_in: [:description], fuzzy_search: true)
                                .order_contiguous_matches_first('car', search_in: [:description])

        expect(labels.first).to eq(described)
      end
    end

    context 'when searching the default columns' do
      it 'places contiguous matches first even when description is NULL' do
        labels = described_class.search('car', fuzzy_search: true)
                                .order_contiguous_matches_first('car')

        expect(labels.first).to eq(caravan)
      end
    end

    context 'when a label has a NULL title' do
      let_it_be(:untitled, freeze: false) do
        create(factory_name, title: 'Temp', description: 'a car we own').tap do |label|
          label.update_column(:title, nil)
        end
      end

      it 'paginates past a titled cursor without dropping it' do
        relation = described_class.search('car', fuzzy_search: true).order_contiguous_matches_first('car')
        order = Gitlab::Pagination::Keyset::Order.extract_keyset_order_object(relation)

        first_page = relation.limit(1).to_a
        cursor = order.cursor_attributes_for_node(first_page.last)

        expect(first_page).to eq([caravan])
        expect(order.apply_cursor_conditions(relation, cursor).limit(2).to_a).to eq([untitled, caprice])
      end
    end

    context 'when the query has a space' do
      let_it_be(:global_search, freeze: false) { create(factory_name, title: 'Global Search') }
      let_it_be(:noise, freeze: false) do
        create(factory_name, title: 'Agile: onboarding blockers escalation research')
      end

      it 'places the multi-word contiguous match ahead of fuzzy-only noise' do
        labels = described_class.search('global search', search_in: [:title], fuzzy_search: true)
                                .order_contiguous_matches_first('global search', search_in: [:title])

        expect(labels.first).to eq(global_search)
      end
    end
  end
end
