require 'spec_helper'
require 'simple_po_parser'

describe Gitlab::I18n::PoLinter do
  let(:linter) { described_class.new(po_path) }
  let(:po_path) { 'spec/fixtures/valid.po' }

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
        message_id = 'You are going to transfer %{project_name_with_namespace} to another owner. Are you ABSOLUTELY sure?'
        expected_error = 'translation contains unescaped `%`, escape it using `%%`'

        expect(errors[message_id]).to include(expected_error)
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
      fake_invalid_entry = Gitlab::I18n::TranslationEntry.new(
        { msgid: "Hello %{world}", msgstr: "Bonjour %{monde}" }, 2
      )
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

      linter.validate_entry(fake_entry)
    end
  end

  describe '#validate_number_of_plurals' do
    it 'validates when there are an incorrect number of translations' do
      fake_metadata = double
      allow(fake_metadata).to receive(:expected_plurals).and_return(2)
      allow(linter).to receive(:metadata_entry).and_return(fake_metadata)

      fake_entry = Gitlab::I18n::TranslationEntry.new(
        { msgid: 'the singular', msgid_plural: 'the plural', 'msgstr[0]' => 'the singular' },
        2
      )
      errors = []

      linter.validate_number_of_plurals(errors, fake_entry)

      expect(errors).to include('should have 2 translations')
    end
  end

  describe '#validate_variables' do
    it 'validates both signular and plural in a pluralized string when the entry has a singular' do
      pluralized_entry = Gitlab::I18n::TranslationEntry.new(
        { msgid: 'Hello %{world}',
          msgid_plural: 'Hello all %{world}',
          'msgstr[0]' => 'Bonjour %{world}',
          'msgstr[1]' => 'Bonjour tous %{world}' },
        2
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
      pluralized_entry = Gitlab::I18n::TranslationEntry.new(
        { msgid: 'Hello %{world}',
          msgid_plural: 'Hello all %{world}',
          'msgstr[0]' => 'Bonjour %{world}' },
        1
      )

      expect(linter).to receive(:validate_variables_in_message)
                          .with([], 'Hello all %{world}', 'Bonjour %{world}')

      linter.validate_variables([], pluralized_entry)
    end

    it 'validates the message variables' do
      entry = Gitlab::I18n::TranslationEntry.new(
        { msgid: 'Hello', msgstr: 'Bonjour' },
        2
      )

      expect(linter).to receive(:validate_variables_in_message)
                          .with([], 'Hello', 'Bonjour')

      linter.validate_variables([], entry)
    end
  end

  describe '#validate_variables_in_message' do
    it 'detects when a variables are used incorrectly' do
      errors = []

      expected_errors = ['<hello %{world} %d> is missing: [%{hello}]',
                         '<hello %{world} %d> is using unknown variables: [%{world}]',
                         'is combining multiple unnamed variables']

      linter.validate_variables_in_message(errors, '%{hello} world %d', 'hello %{world} %d')

      expect(errors).to include(*expected_errors)
    end
  end

  describe '#validate_translation' do
    it 'succeeds with valid variables' do
      errors = []

      linter.validate_translation(errors, 'Hello %{world}',  ['%{world}'])

      expect(errors).to be_empty
    end

    it 'adds an error message when translating fails' do
      errors = []

      expect(FastGettext::Translation).to receive(:_) { raise 'broken' }

      linter.validate_translation(errors, 'Hello', [])

      expect(errors).to include('Failure translating to en with []: broken')
    end

    it 'adds an error message when translating fails when translating with context' do
      errors = []

      expect(FastGettext::Translation).to receive(:s_) { raise 'broken' }

      linter.validate_translation(errors, 'Tests|Hello', [])

      expect(errors).to include('Failure translating to en with []: broken')
    end

    it "adds an error when trying to translate with incorrect variables when using unnamed variables" do
      errors = []

      linter.validate_translation(errors, 'Hello %d', ['%s'])

      expect(errors.first).to start_with("Failure translating to en with")
    end

    it "adds an error when trying to translate with named variables when unnamed variables are expected" do
      errors = []

      linter.validate_translation(errors, 'Hello %d', ['%{world}'])

      expect(errors.first).to start_with("Failure translating to en with")
    end

    it 'adds an error when translated with incorrect variables using named variables' do
      errors = []

      linter.validate_translation(errors, 'Hello %{thing}', ['%d'])

      expect(errors.first).to start_with("Failure translating to en with")
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
