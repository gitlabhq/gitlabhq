# frozen_string_literal: true

require 'spec_helper'
require 'simple_po_parser'

# Disabling this cop to allow for multi-language examples in comments
# rubocop:disable Style/AsciiComments
RSpec.describe Gitlab::I18n::PoLinter do
  let(:linter) { described_class.new(po_path: po_path) }
  let(:po_path) { 'spec/fixtures/valid.po' }

  def fake_translation(msgid:, translation:, plural_id: nil, plurals: [])
    data = { msgid: msgid, msgid_plural: plural_id }

    if plural_id
      [translation, *plurals].each_with_index do |plural, index|
        allow(FastGettext::Translation).to receive(:n_).with(msgid, plural_id, index).and_return(plural)
        data.merge!("msgstr[#{index}]" => plural)
      end
    else
      allow(FastGettext::Translation).to receive(:_).with(msgid).and_return(translation)
      data[:msgstr] = translation
    end

    Gitlab::I18n::TranslationEntry.new(
      entry_data: data,
      nplurals: plurals.size + 1
    )
  end

  describe '#errors' do
    it 'only calls validation once' do
      expect(linter).to receive(:validate_po).once.and_call_original

      2.times { linter.errors }
    end
  end

  describe '#validate_po' do
    subject(:errors) { linter.validate_po }

    context 'for a fuzzy message' do
      let(:po_path) { 'spec/fixtures/fuzzy.po' }

      it 'has an error' do
        is_expected.to include('PipelineSchedules|Remove variable row' => ['is marked fuzzy'])
      end
    end

    context 'for a translations with namespaces' do
      let(:po_path) { 'spec/fixtures/namespaces.po' }

      it 'has an error for translation with namespace' do
        message_id = "404|Not found"
        expected_message = "contains a namespace. Remove it from the translation. For more information see https://docs.gitlab.com/ee/development/i18n/translation.html#namespaced-strings"

        expect(errors[message_id]).to include(expected_message)
      end

      it 'has an error for plural translation with namespace' do
        message_id = "CommitHistory|1 commit"
        expected_message = "contains a namespace. Remove it from the translation. For more information see https://docs.gitlab.com/ee/development/i18n/translation.html#namespaced-strings"

        expect(errors[message_id]).to include(expected_message)
      end
    end

    context 'for a translations with spaces' do
      let(:po_path) { 'spec/fixtures/spaces.po' }

      it 'has an error for translation with a leading space' do
        message_id = "1 commit"
        expected_message = "has leading space. Remove it from the translation"

        expect(errors[message_id]).to include(expected_message)
      end

      it 'has an error for plural translation with a leading space' do
        message_id = "With plural"
        expected_message = "has leading space. Remove it from the translation"

        expect(errors[message_id]).to include(expected_message)
      end

      it 'has an error for translation with a trailing space' do
        message_id = "User"
        expected_message = "has trailing space. Remove it from the translation"

        expect(errors[message_id]).to include(expected_message)
      end

      it 'has an error for translation with a multiple spaces not present in source string' do
        message_id = "Hello there  world"
        expected_message = "has different sets of consecutive multiple spaces. Make them consistent with source string"

        expect(errors[message_id]).to include(expected_message)
      end
    end

    context 'for a translations with newlines' do
      let(:po_path) { 'spec/fixtures/newlines.po' }

      it 'has an error for a normal string' do
        message_id = "You are going to remove %{group_name}.\\nRemoved groups CANNOT be restored!\\nAre you ABSOLUTELY sure?"
        expected_message = "is defined over multiple lines, this breaks some tooling."

        expect(errors[message_id]).to include(expected_message)
      end

      it 'has an error when a translation is defined over multiple lines' do
        message_id = "You are going to remove %{group_name}.\\nRemoved groups CANNOT be restored!\\nAre you ABSOLUTELY sure?"
        expected_message = "has translations defined over multiple lines, this breaks some tooling."

        expect(errors[message_id]).to include(expected_message)
      end

      it 'raises an error when a plural translation is defined over multiple lines' do
        message_id = 'With plural'
        expected_message = "has translations defined over multiple lines, this breaks some tooling."

        expect(errors[message_id]).to include(expected_message)
      end

      it 'raises an error when the plural id is defined over multiple lines' do
        message_id = 'multiline plural id'
        expected_message = "plural is defined over multiple lines, this breaks some tooling."

        expect(errors[message_id]).to include(expected_message)
      end
    end

    context 'with an invalid po' do
      let(:po_path) { 'spec/fixtures/invalid.po' }

      it 'returns the error' do
        is_expected.to include('PO-syntax errors' => a_kind_of(Array))
      end

      it 'does not validate entries' do
        expect(linter).not_to receive(:validate_entries)

        linter.validate_po
      end
    end

    context 'with missing metadata' do
      let(:po_path) { 'spec/fixtures/missing_metadata.po' }

      it 'returns the an error' do
        is_expected.to include('PO-syntax errors' => a_kind_of(Array))
      end
    end

    context 'with a valid po' do
      it 'parses the file' do
        expect(linter).to receive(:parse_po).and_call_original

        linter.validate_po
      end

      it 'validates the entries' do
        expect(linter).to receive(:validate_entries).and_call_original

        linter.validate_po
      end

      it 'has no errors' do
        is_expected.to be_empty
      end
    end

    context 'with missing plurals' do
      let(:po_path) { 'spec/fixtures/missing_plurals.po' }

      it 'has errors' do
        is_expected.not_to be_empty
      end
    end

    context 'with multiple plurals' do
      let(:po_path) { 'spec/fixtures/multiple_plurals.po' }

      it 'has errors' do
        is_expected.not_to be_empty
      end
    end

    context 'with unescaped chars' do
      let(:po_path) { 'spec/fixtures/unescaped_chars.po' }

      it 'contains an error' do
        message_id = 'You are going to transfer %{project_name_with_namespace} to another namespace. Are you ABSOLUTELY sure?'
        expected_error = 'translation contains unescaped `%`, escape it using `%%`'

        expect(errors[message_id]).to include(expected_error)
      end
    end

    context 'when an entry contains html' do
      let(:po_path) { 'spec/fixtures/potential_html.po' }

      it 'presents an error for each component containing angle brackets' do
        message_id = 'String with some <strong>emphasis</strong>'

        expect(errors[message_id]).to match_array [
          a_string_starting_with('contains < or >.'),
          a_string_starting_with('plural id contains < or >.'),
          a_string_starting_with('translation contains < or >.')
        ]
      end
    end
  end

  describe '#parse_po' do
    context 'with a valid po' do
      it 'fills in the entries' do
        linter.parse_po

        expect(linter.translation_entries).not_to be_empty
        expect(linter.metadata_entry).to be_kind_of(Gitlab::I18n::MetadataEntry)
      end

      it 'does not have errors' do
        expect(linter.parse_po).to be_nil
      end
    end

    context 'with an invalid po' do
      let(:po_path) { 'spec/fixtures/invalid.po' }

      it 'contains an error' do
        expect(linter.parse_po).not_to be_nil
      end

      it 'sets the entries to an empty array' do
        linter.parse_po

        expect(linter.translation_entries).to eq([])
      end
    end
  end

  describe '#validate_entries' do
    it 'keeps track of errors for entries' do
      fake_invalid_entry = fake_translation(msgid: "Hello %{world}",
        translation: "Bonjour %{monde}")
      allow(linter).to receive(:translation_entries) { [fake_invalid_entry] }

      expect(linter).to receive(:validate_entry)
                          .with(fake_invalid_entry)
                          .and_call_original

      expect(linter.validate_entries).to include("Hello %{world}" => an_instance_of(Array))
    end
  end

  describe '#validate_entry' do
    it 'validates the flags, variable usage, newlines, and unescaped chars' do
      fake_entry = double

      expect(linter).to receive(:validate_flags).with([], fake_entry)
      expect(linter).to receive(:validate_variables).with([], fake_entry)
      expect(linter).to receive(:validate_newlines).with([], fake_entry)
      expect(linter).to receive(:validate_number_of_plurals).with([], fake_entry)
      expect(linter).to receive(:validate_unescaped_chars).with([], fake_entry)
      expect(linter).to receive(:validate_translation).with([], fake_entry)
      expect(linter).to receive(:validate_namespace).with([], fake_entry)
      expect(linter).to receive(:validate_spaces).with([], fake_entry)
      expect(linter).to receive(:validate_html).with([], fake_entry)

      linter.validate_entry(fake_entry)
    end
  end

  describe '#validate_number_of_plurals' do
    it 'validates when there are an incorrect number of translations' do
      fake_metadata = double
      allow(fake_metadata).to receive(:expected_forms).and_return(2)
      allow(linter).to receive(:metadata_entry).and_return(fake_metadata)

      fake_entry = Gitlab::I18n::TranslationEntry.new(
        entry_data: { msgid: 'the singular', msgid_plural: 'the plural', 'msgstr[0]' => 'the singular' },
        nplurals: 2
      )
      errors = []

      linter.validate_number_of_plurals(errors, fake_entry)

      expect(errors).to include('should have 2 translations')
    end
  end

  describe '#validate_variables' do
    before do
      allow(linter).to receive(:validate_variables_in_message).and_call_original
    end

    it 'validates both singular and plural in a pluralized string when the entry has a singular' do
      pluralized_entry = fake_translation(
        msgid: 'Hello %{world}',
        translation: 'Bonjour %{world}',
        plural_id: 'Hello all %{world}',
        plurals: ['Bonjour tous %{world}']
      )

      expect(linter).to receive(:validate_variables_in_message)
                          .with([], 'Hello %{world}', 'Bonjour %{world}')
                          .and_call_original
      expect(linter).to receive(:validate_variables_in_message)
                          .with([], 'Hello all %{world}', 'Bonjour tous %{world}')
                          .and_call_original

      linter.validate_variables([], pluralized_entry)
    end

    it 'only validates plural when there is no separate singular' do
      pluralized_entry = fake_translation(
        msgid: 'Hello %{world}',
        translation: 'Bonjour %{world}',
        plural_id: 'Hello all %{world}'
      )

      expect(linter).to receive(:validate_variables_in_message)
                          .with([], 'Hello all %{world}', 'Bonjour %{world}')

      linter.validate_variables([], pluralized_entry)
    end

    it 'validates the message variables' do
      entry = fake_translation(msgid: 'Hello', translation: 'Bonjour')

      expect(linter).to receive(:validate_variables_in_message)
                          .with([], 'Hello', 'Bonjour')

      linter.validate_variables([], entry)
    end

    it 'validates variable usage in message ids' do
      entry = fake_translation(
        msgid: 'Hello %{world}',
        translation: 'Bonjour %{world}',
        plural_id: 'Hello all %{world}',
        plurals: ['Bonjour tous %{world}']
      )

      expect(linter).to receive(:validate_variables_in_message)
                          .with([], 'Hello %{world}', 'Hello %{world}')
                          .and_call_original
      expect(linter).to receive(:validate_variables_in_message)
                          .with([], 'Hello all %{world}', 'Hello all %{world}')
                          .and_call_original

      linter.validate_variables([], entry)
    end
  end

  describe '#validate_variables_in_message' do
    it 'detects when a variables are used incorrectly' do
      errors = []

      expected_errors = ['<%d hello %{world} %s> is missing: [%{hello}]',
                         '<%d hello %{world} %s> is using unknown variables: [%{world}]',
                         'is combining multiple unnamed variables',
                         'is combining named variables with unnamed variables']

      linter.validate_variables_in_message(errors, '%d %{hello} world %s', '%d hello %{world} %s')

      expect(errors).to include(*expected_errors)
    end

    it 'does not allow combining 1 `%d` unnamed variable with named variables' do
      errors = []

      linter.validate_variables_in_message(errors,
        '%{type} detected %d vulnerability',
        '%{type} detecteerde %d kwetsbaarheid')

      expect(errors).not_to be_empty
    end
  end

  describe '#validate_translation' do
    let(:entry) { fake_translation(msgid: 'Hello %{world}', translation: 'Bonjour %{world}') }

    it 'succeeds with valid variables' do
      errors = []

      linter.validate_translation(errors, entry)

      expect(errors).to be_empty
    end

    it 'adds an error message when translating fails' do
      errors = []

      expect(FastGettext::Translation).to receive(:_) { raise 'broken' }

      linter.validate_translation(errors, entry)

      expect(errors).to include('Failure translating to en: broken')
    end

    it 'adds an error message when translating fails when translating with context' do
      entry = fake_translation(msgid: 'Tests|Hello', translation: 'broken')
      errors = []

      expect(FastGettext::Translation).to receive(:s_) { raise 'broken' }

      linter.validate_translation(errors, entry)

      expect(errors).to include('Failure translating to en: broken')
    end

    it "adds an error when trying to translate with incorrect variables when using unnamed variables" do
      entry = fake_translation(msgid: 'Hello %s', translation: 'Hello %d')
      errors = []

      linter.validate_translation(errors, entry)

      expect(errors.first).to start_with("Failure translating to en")
    end

    it "adds an error when trying to translate with named variables when unnamed variables are expected" do
      entry = fake_translation(msgid: 'Hello %s', translation: 'Hello %{thing}')
      errors = []

      linter.validate_translation(errors, entry)

      expect(errors.first).to start_with("Failure translating to en")
    end

    it 'tests translation for all given forms' do
      # Fake a language that has 3 forms to translate
      fake_metadata = double
      allow(fake_metadata).to receive(:forms_to_test).and_return(3)
      allow(linter).to receive(:metadata_entry).and_return(fake_metadata)
      entry = fake_translation(
        msgid: '%d exception',
        translation: '%d uitzondering',
        plural_id: '%d exceptions',
        plurals: ['%d uitzonderingen', '%d uitzonderingetjes']
      )

      # Make each count use a different index
      allow(linter).to receive(:index_for_pluralization).with(0).and_return(0)
      allow(linter).to receive(:index_for_pluralization).with(1).and_return(1)
      allow(linter).to receive(:index_for_pluralization).with(2).and_return(2)

      expect(FastGettext::Translation).to receive(:n_).with('%d exception', '%d exceptions', 0).and_call_original
      expect(FastGettext::Translation).to receive(:n_).with('%d exception', '%d exceptions', 1).and_call_original
      expect(FastGettext::Translation).to receive(:n_).with('%d exception', '%d exceptions', 2).and_call_original

      linter.validate_translation([], entry)
    end
  end

  describe '#numbers_covering_all_plurals' do
    it 'can correctly find all required numbers to translate to Polish' do
      # Polish used as an example with 3 different forms:
      # 0, all plurals except the ones ending in 2,3,4: Kotów
      # 1: Kot
      # 2-3-4: Koty
      # So translating with [0, 1, 2] will give us all different posibilities
      fake_metadata = double
      allow(fake_metadata).to receive(:forms_to_test).and_return(4)
      allow(linter).to receive(:metadata_entry).and_return(fake_metadata)

      numbers = Gitlab::I18n.with_locale('pl_PL') do
        linter.numbers_covering_all_plurals
      end

      expect(numbers).to contain_exactly(0, 1, 2)
    end
  end

  describe '#fill_in_variables' do
    it 'builds an array for %d translations' do
      result = linter.fill_in_variables(['%d'])

      expect(result).to contain_exactly(a_kind_of(Integer))
    end

    it 'builds an array for %s translations' do
      result = linter.fill_in_variables(['%s'])

      expect(result).to contain_exactly(a_kind_of(String))
    end

    it 'builds a hash for named variables' do
      result = linter.fill_in_variables(['%{hello}'])

      expect(result).to be_a(Hash)
      expect(result).to include('hello' => an_instance_of(String))
    end
  end
end
# rubocop:enable Style/AsciiComments
