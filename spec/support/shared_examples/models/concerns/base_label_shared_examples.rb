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
    let_it_be(:label) { create(factory_name, title: 'bug', description: 'incorrect behavior') }
    let_it_be(:other_label) { create(factory_name, title: 'test', description: 'bug') }

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
  end
end
