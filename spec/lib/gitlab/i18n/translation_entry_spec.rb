# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Gitlab::I18n::TranslationEntry do
  describe '#singular_translation' do
    it 'returns the normal `msgstr` for translations without plural' do
      data = { msgid: 'Hello world', msgstr: 'Bonjour monde' }
      entry = described_class.new(entry_data: data, nplurals: 2)

      expect(entry.singular_translation).to eq('Bonjour monde')
    end

    it 'returns the first string for entries with plurals' do
      data = {
        msgid: 'Hello world',
        msgid_plural: 'Hello worlds',
        'msgstr[0]' => 'Bonjour monde',
        'msgstr[1]' => 'Bonjour mondes'
      }
      entry = described_class.new(entry_data: data, nplurals: 2)

      expect(entry.singular_translation).to eq('Bonjour monde')
    end
  end

  describe '#all_translations' do
    it 'returns all translations for singular translations' do
      data = { msgid: 'Hello world', msgstr: 'Bonjour monde' }
      entry = described_class.new(entry_data: data, nplurals: 2)

      expect(entry.all_translations).to eq(['Bonjour monde'])
    end

    it 'returns all translations when including plural translations' do
      data = {
        msgid: 'Hello world',
        msgid_plural: 'Hello worlds',
        'msgstr[0]' => 'Bonjour monde',
        'msgstr[1]' => 'Bonjour mondes'
      }
      entry = described_class.new(entry_data: data, nplurals: 2)

      expect(entry.all_translations).to eq(['Bonjour monde', 'Bonjour mondes'])
    end
  end

  describe '#plural_translations' do
    it 'returns all translations if there is only one plural' do
      data = {
        msgid: 'Hello world',
        msgid_plural: 'Hello worlds',
        'msgstr[0]' => 'Bonjour monde'
      }
      entry = described_class.new(entry_data: data, nplurals: 1)

      expect(entry.plural_translations).to eq(['Bonjour monde'])
    end

    it 'returns all translations except for the first one if there are multiple' do
      data = {
        msgid: 'Hello world',
        msgid_plural: 'Hello worlds',
        'msgstr[0]' => 'Bonjour monde',
        'msgstr[1]' => 'Bonjour mondes',
        'msgstr[2]' => 'Bonjour tous les mondes'
      }
      entry = described_class.new(entry_data: data, nplurals: 3)

      expect(entry.plural_translations).to eq(['Bonjour mondes', 'Bonjour tous les mondes'])
    end
  end

  describe '#has_singular_translation?' do
    it 'has a singular when the translation is not pluralized' do
      data = {
        msgid: 'hello world',
        msgstr: 'hello'
      }
      entry = described_class.new(entry_data: data, nplurals: 2)

      expect(entry).to have_singular_translation
    end

    it 'has a singular when plural and singular are separately defined' do
      data = {
        msgid: 'hello world',
        msgid_plural: 'hello worlds',
        "msgstr[0]" => 'hello world',
        "msgstr[1]" => 'hello worlds'
      }
      entry = described_class.new(entry_data: data, nplurals: 2)

      expect(entry).to have_singular_translation
    end

    it 'does not have a separate singular if the plural string only has one translation' do
      data = {
        msgid: 'hello world',
        msgid_plural: 'hello worlds',
        "msgstr[0]" => 'hello worlds'
      }
      entry = described_class.new(entry_data: data, nplurals: 1)

      expect(entry).not_to have_singular_translation
    end
  end

  describe '#msgid_contains_newlines' do
    it 'is true when the msgid is an array' do
      data = { msgid: %w[hello world] }
      entry = described_class.new(entry_data: data, nplurals: 2)

      expect(entry.msgid_has_multiple_lines?).to be_truthy
    end
  end

  describe '#plural_id_contains_newlines' do
    it 'is true when the msgid is an array' do
      data = { msgid_plural: %w[hello world] }
      entry = described_class.new(entry_data: data, nplurals: 2)

      expect(entry.plural_id_has_multiple_lines?).to be_truthy
    end
  end

  describe '#translations_contain_newlines' do
    it 'is true when the msgid is an array' do
      data = { msgstr: %w[hello world] }
      entry = described_class.new(entry_data: data, nplurals: 2)

      expect(entry.translations_have_multiple_lines?).to be_truthy
    end
  end

  describe '#translations_contain_leading_space' do
    it 'is true when msgstr starts with a space and msgid does not' do
      data = {
        msgid: 'Hello world',
        msgstr: ' Ahoj světe'
      }
      entry = described_class.new(entry_data: data, nplurals: 2)

      expect(entry.translations_contain_leading_space?).to be_truthy
    end

    it 'is true when msgstr starts with a space, msgid does not and msgid contains namespace' do
      data = {
        msgid: 'General|Hello world',
        msgstr: ' Ahoj světe'
      }
      entry = described_class.new(entry_data: data, nplurals: 2)

      expect(entry.translations_contain_leading_space?).to be_truthy
    end

    it 'is false when msgstr and msgid both start with a space and msgid contains namespace' do
      data = {
        msgid: 'General| Hello world',
        msgstr: ' Ahoj světe'
      }
      entry = described_class.new(entry_data: data, nplurals: 2)

      expect(entry.translations_contain_leading_space?).to be_falsy
    end

    it 'is false when msgstr and msgid both start with a space' do
      data = {
        msgid: ' Hello world',
        msgstr: ' Ahoj světe'
      }
      entry = described_class.new(entry_data: data, nplurals: 2)

      expect(entry.translations_contain_leading_space?).to be_falsy
    end

    it 'is false when msgstr starts with a space and msgid starts with a comma followed by space' do
      data = {
        msgid: ', or ',
        msgstr: ' eller '
      }
      entry = described_class.new(entry_data: data, nplurals: 2)

      expect(entry.translations_contain_leading_space?).to be_falsy
    end

    it 'is false when msgstr and msgid both start with a comma followed by space' do
      data = {
        msgid: ', or ',
        msgstr: ', eller '
      }
      entry = described_class.new(entry_data: data, nplurals: 2)

      expect(entry.translations_contain_leading_space?).to be_falsy
    end

    it 'is false when msgstr starts with a comma and a space and msgid starts with a comma' do
      data = {
        msgid: ' or ',
        msgstr: ', eller '
      }
      entry = described_class.new(entry_data: data, nplurals: 2)

      expect(entry.translations_contain_leading_space?).to be_falsy
    end

    it 'is false when msgstr and msgid both do not start with a space' do
      data = {
        msgid: 'Hello world',
        msgstr: 'Ahoj světe'
      }
      entry = described_class.new(entry_data: data, nplurals: 2)

      expect(entry.translations_contain_leading_space?).to be_falsy
    end

    it 'is false when msgstr does not contain a space but msgid does' do
      data = {
        msgid: 'Hello world',
        msgstr: 'Ahojsvěte'
      }
      entry = described_class.new(entry_data: data, nplurals: 2)

      expect(entry.translations_contain_leading_space?).to be_falsy
    end
  end

  describe '#translations_contain_trailing_space' do
    it 'is true when msgstr ends with a space and msgid does not' do
      data = {
        msgid: 'Hello world',
        msgstr: 'Ahoj světe '
      }
      entry = described_class.new(entry_data: data, nplurals: 2)

      expect(entry.translations_contain_trailing_space?).to be_truthy
    end

    it 'is true when msgstr ends with a space, msgid does not and msgid contains namespace' do
      data = {
        msgid: 'General|Hello world',
        msgstr: 'Ahoj světe '
      }
      entry = described_class.new(entry_data: data, nplurals: 2)

      expect(entry.translations_contain_trailing_space?).to be_truthy
    end

    it 'is false when msgstr and msgid both end with a space and msgid contains namespace' do
      data = {
        msgid: 'General|Hello world ',
        msgstr: 'Ahoj světe '
      }
      entry = described_class.new(entry_data: data, nplurals: 2)

      expect(entry.translations_contain_trailing_space?).to be_falsy
    end

    it 'is false when msgstr and msgid both end with a space' do
      data = {
        msgid: 'Hello world ',
        msgstr: 'Ahoj světe '
      }
      entry = described_class.new(entry_data: data, nplurals: 2)

      expect(entry.translations_contain_trailing_space?).to be_falsy
    end

    it 'is false when msgstr and msgid both do not end with a space' do
      data = {
        msgid: 'Hello world',
        msgstr: 'Ahoj světe'
      }
      entry = described_class.new(entry_data: data, nplurals: 2)

      expect(entry.translations_contain_trailing_space?).to be_falsy
    end

    it 'is false when msgstr does not contain a space but msgid does' do
      data = {
        msgid: 'Hello world',
        msgstr: 'Ahojsvěte'
      }
      entry = described_class.new(entry_data: data, nplurals: 2)

      expect(entry.translations_contain_trailing_space?).to be_falsy
    end
  end

  describe '#translations_contain_multiple_spaces' do
    it 'is true when msgstr contains multiple spaces and msgid does not' do
      data = {
        msgid: 'Hello world',
        msgstr: 'Ahoj  světe'
      }
      entry = described_class.new(entry_data: data, nplurals: 2)

      expect(entry.translations_contain_multiple_spaces?).to be_truthy
    end

    it 'is true when msgstr and msgid contain different amounts of multiple consecutive spaces' do
      data = {
        msgid: 'Hello  world   and  all',
        msgstr: 'Ahoj  světe  a    všichni'
      }
      entry = described_class.new(entry_data: data, nplurals: 2)

      expect(entry.translations_contain_multiple_spaces?).to be_truthy
    end

    it 'is true when msgstr and msgid contain different amounts of multiple consecutive spaces and chunks' do
      data = {
        msgid: 'Hello  world   and  all',
        msgstr: 'Ahoj  světe a    všichni'
      }
      entry = described_class.new(entry_data: data, nplurals: 2)

      expect(entry.translations_contain_multiple_spaces?).to be_truthy
    end

    it 'is false when msgstr and msgid contain the same chunks of multiple spaces at different places' do
      data = {
        msgid: 'Hello  world   and  all',
        msgstr: "Ahoj  světe  a   všichni"
      }
      entry = described_class.new(entry_data: data, nplurals: 2)

      expect(entry.translations_contain_multiple_spaces?).to be_falsy
    end

    it 'is false when msgstr and msgid contain the same chunks of multiple spaces at the same places' do
      data = {
        msgid: 'Hello  world   and  all',
        msgstr: 'Ahoj  světe   a  všichni'
      }
      entry = described_class.new(entry_data: data, nplurals: 2)

      expect(entry.translations_contain_multiple_spaces?).to be_falsy
    end

    it 'is false when msgstr and msgid contain one chunk of multiple spaces at the same place' do
      data = {
        msgid: 'Hello  world',
        msgstr: 'Ahoj  světe'
      }
      entry = described_class.new(entry_data: data, nplurals: 2)

      expect(entry.translations_contain_multiple_spaces?).to be_falsy
    end
  end

  describe '#translations_contain_namespace' do
    it 'is true when the msgstr contains namespace' do
      data = {
        msgid: '404|Not found',
        msgstr: '404|No encontrado'
      }
      entry = described_class.new(entry_data: data, nplurals: 2)

      expect(entry.translations_contain_namespace?).to be_truthy
    end

    it 'is true when one plural translation contains namespace' do
      data = {
        msgid: 'Test|hello world',
        msgid_plural: 'Test|hello worlds',
        "msgstr[0]" => 'Test|hello world',
        "msgstr[1]" => 'hello worlds'
      }
      entry = described_class.new(entry_data: data, nplurals: 2)

      expect(entry.translations_contain_namespace?).to be_truthy
    end

    it 'is true when all plural translation contains namespace' do
      data = {
        msgid: 'Test|hello world',
        msgid_plural: 'Test|hello worlds',
        "msgstr[0]" => 'Test|hello world',
        "msgstr[1]" => 'Test|hello worlds'
      }
      entry = described_class.new(entry_data: data, nplurals: 2)

      expect(entry.translations_contain_namespace?).to be_truthy
    end

    it "is false when the msgstr doesn't contain namespace" do
      data = {
        msgid: '404|Not found',
        msgstr: 'No encontrado'
      }
      entry = described_class.new(entry_data: data, nplurals: 2)

      expect(entry.translations_contain_namespace?).to be_falsy
    end

    it "is false when the msgstr contains namespace but source is from list of false positives" do
      data = {
        msgid: 'Example: (jar|exe)$',
        msgstr: 'Ejemplo: (jar|exe)$'
      }
      entry = described_class.new(entry_data: data, nplurals: 2)

      data_two = {
        msgid: 'Example: (feature|hotfix)\\\\/.*',
        msgstr: 'Ejemplo: (feature|hotfix)\\\\/.*'
      }
      entry_two = described_class.new(entry_data: data_two, nplurals: 2)

      expect(entry_two.translations_contain_namespace?).to be_falsy
      expect(entry.translations_contain_namespace?).to be_falsy
    end

    it 'is false when no plural translation contains namespace' do
      data = {
        msgid: 'Test|hello world',
        msgid_plural: 'Test|hello worlds',
        "msgstr[0]" => 'hello world',
        "msgstr[1]" => 'hello worlds'
      }
      entry = described_class.new(entry_data: data, nplurals: 2)

      expect(entry.translations_contain_namespace?).to be_falsy
    end
  end

  describe '#contains_namespace' do
    let(:data) { { msgid: '' } }
    let(:entry) { described_class.new(entry_data: data, nplurals: 2) }

    it 'is true when the string contains a namespace' do
      string = '404|Not found'

      expect(entry.contains_namespace?(string)).to be_truthy
    end

    it 'is true when the string contains a namespace with leading spaces' do
      string = ' 404|Not found'

      expect(entry.contains_namespace?(string)).to be_truthy
    end

    it 'is true when the string contains a namespace with trailing spaces' do
      string = '404 |Not found'

      expect(entry.contains_namespace?(string)).to be_truthy
    end

    it 'is true when the string contains a namespace with leading and trailing spaces' do
      string = ' 404 |Not found'

      expect(entry.contains_namespace?(string)).to be_truthy
    end

    it 'is true when the string contains a namespace with a space' do
      string = '40 4|Not found'

      expect(entry.contains_namespace?(string)).to be_truthy
    end

    it 'is true when the string contains a namespace with unicode characters' do
      string = 'ZobrazeníČasu|System'

      expect(entry.contains_namespace?(string)).to be_truthy
    end

    it 'is true when the string contains a namespace with unicode characters and a space' do
      string = 'Zobrazení Času|System'

      expect(entry.contains_namespace?(string)).to be_truthy
    end

    it 'is false when the string contains a pipe, but not a namespace' do
      string = 'Example: (jar|exe)$'

      expect(entry.contains_namespace?(string)).to be_falsy
    end

    it 'is false when the string does not contain a namespace' do
      string = 'Not found'

      expect(entry.contains_namespace?(string)).to be_falsy
    end
  end

  describe '#contains_unescaped_chars' do
    let(:data) { { msgid: '' } }
    let(:entry) { described_class.new(entry_data: data, nplurals: 2) }

    it 'is true when the msgid is an array' do
      string = '「100%確定」'

      expect(entry.contains_unescaped_chars?(string)).to be_truthy
    end

    it 'is false when the `%` char is escaped' do
      string = '「100%%確定」'

      expect(entry.contains_unescaped_chars?(string)).to be_falsy
    end

    it 'is false when using an unnamed variable' do
      string = '「100%d確定」'

      expect(entry.contains_unescaped_chars?(string)).to be_falsy
    end

    it 'is false when using a named variable' do
      string = '「100%{named}確定」'

      expect(entry.contains_unescaped_chars?(string)).to be_falsy
    end

    it 'is true when an unnamed variable is not closed' do
      string = '「100%{named確定」'

      expect(entry.contains_unescaped_chars?(string)).to be_truthy
    end

    it 'is true when the string starts with a `%`' do
      string = '%10'

      expect(entry.contains_unescaped_chars?(string)).to be_truthy
    end
  end

  describe '#msgid_contains_unescaped_chars' do
    it 'is true when the msgid contains a `%`' do
      data = { msgid: '「100%確定」' }
      entry = described_class.new(entry_data: data, nplurals: 2)

      expect(entry).to receive(:contains_unescaped_chars?).and_call_original
      expect(entry.msgid_contains_unescaped_chars?).to be_truthy
    end
  end

  describe '#plural_id_contains_unescaped_chars' do
    it 'is true when the plural msgid contains a `%`' do
      data = { msgid_plural: '「100%確定」' }
      entry = described_class.new(entry_data: data, nplurals: 2)

      expect(entry).to receive(:contains_unescaped_chars?).and_call_original
      expect(entry.plural_id_contains_unescaped_chars?).to be_truthy
    end
  end

  describe '#translations_contain_unescaped_chars' do
    it 'is true when the translation contains a `%`' do
      data = { msgstr: '「100%確定」' }
      entry = described_class.new(entry_data: data, nplurals: 2)

      expect(entry).to receive(:contains_unescaped_chars?).and_call_original
      expect(entry.translations_contain_unescaped_chars?).to be_truthy
    end
  end

  describe '#msgid_contains_potential_html?' do
    subject(:entry) { described_class.new(entry_data: data, nplurals: 2) }

    context 'when there are no angle brackets in the msgid' do
      let(:data) { { msgid: 'String with no brackets' } }

      it 'returns false' do
        expect(entry.msgid_contains_potential_html?).to be_falsey
      end
    end

    context 'when there are angle brackets in the msgid' do
      let(:data) { { msgid: 'String with <strong> tag' } }

      it 'returns true' do
        expect(entry.msgid_contains_potential_html?).to be_truthy
      end
    end
  end

  describe '#plural_id_contains_potential_html?' do
    subject(:entry) { described_class.new(entry_data: data, nplurals: 2) }

    context 'when there are no angle brackets in the plural_id' do
      let(:data) { { msgid_plural: 'String with no brackets' } }

      it 'returns false' do
        expect(entry.plural_id_contains_potential_html?).to be_falsey
      end
    end

    context 'when there are angle brackets in the plural_id' do
      let(:data) { { msgid_plural: 'This string has a <strong>' } }

      it 'returns true' do
        expect(entry.plural_id_contains_potential_html?).to be_truthy
      end
    end
  end

  describe '#translations_contain_potential_html?' do
    subject(:entry) { described_class.new(entry_data: data, nplurals: 2) }

    context 'when there are no angle brackets in the translations' do
      let(:data) { { msgstr: 'This string has no angle brackets' } }

      it 'returns false' do
        expect(entry.translations_contain_potential_html?).to be_falsey
      end
    end

    context 'when there are angle brackets in the translations' do
      let(:data) { { msgstr: 'This string has a <strong>' } }

      it 'returns true' do
        expect(entry.translations_contain_potential_html?).to be_truthy
      end
    end
  end
end
