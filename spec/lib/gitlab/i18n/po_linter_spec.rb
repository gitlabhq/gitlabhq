require 'spec_helper'

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
        expected_message = "<#{message_id}> is defined over multiple lines, this breaks some tooling."

        expect(errors[message_id]).to include(expected_message)
      end

      it 'has an error when a translation is defined over multiple lines' do
        message_id = "You are going to remove %{group_name}.\\nRemoved groups CANNOT be restored!\\nAre you ABSOLUTELY sure?"
        expected_message = "<#{message_id}> has translations defined over multiple lines, this breaks some tooling."

        expect(errors[message_id]).to include(expected_message)
      end

      it 'raises an error when a plural translation is defined over multiple lines' do
        message_id = 'With plural'
        expected_message = "<#{message_id}> has translations defined over multiple lines, this breaks some tooling."

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
      let(:po_path) { 'spec/fixtures/no_plurals.po' }

      it 'has no errors' do
        is_expected.to be_empty
      end
    end

    context 'with multiple plurals' do
      let(:po_path) { 'spec/fixtures/multiple_plurals.po' }

      it 'has no errors' do
        is_expected.not_to be_empty
      end
    end
  end

  describe '#parse_po' do
    context 'with a valid po' do
      it 'fills in the entries' do
        linter.parse_po

        expect(linter.entries).not_to be_empty
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

        expect(linter.entries).to eq([])
      end
    end
  end

  describe '#validate_entries' do
    it 'skips entries without a `msgid`' do
      allow(linter).to receive(:entries) { [Gitlab::I18n::PoEntry.new({ msgid: "" })] }

      expect(linter.validate_entries).to be_empty
    end

    it 'keeps track of errors for entries' do
      fake_invalid_entry = Gitlab::I18n::PoEntry.new({ msgid: "Hello %{world}", msgstr: "Bonjour %{monde}" })
      allow(linter).to receive(:entries) { [fake_invalid_entry] }

      expect(linter).to receive(:validate_entry)
                          .with(fake_invalid_entry)
                          .and_call_original

      expect(linter.validate_entries).to include("Hello %{world}" => an_instance_of(Array))
    end
  end

  describe '#validate_entry' do
    it 'validates the flags, variable usage, and newlines' do
      fake_entry = double

      expect(linter).to receive(:validate_flags).with([], fake_entry)
      expect(linter).to receive(:validate_variables).with([], fake_entry)
      expect(linter).to receive(:validate_newlines).with([], fake_entry)

      linter.validate_entry(fake_entry)
    end
  end

  describe '#validate_variables' do
    it 'validates both signular and plural in a pluralized string' do
      pluralized_entry = Gitlab::I18n::PoEntry.new({
        msgid: 'Hello %{world}',
        msgid_plural: 'Hello all %{world}',
        'msgstr[0]' => 'Bonjour %{world}',
        'msgstr[1]' => 'Bonjour tous %{world}'
      })

      expect(linter).to receive(:validate_variables_in_message)
                          .with([], 'Hello %{world}', 'Bonjour %{world}')
      expect(linter).to receive(:validate_variables_in_message)
                          .with([], 'Hello all %{world}', 'Bonjour tous %{world}')

      linter.validate_variables([], pluralized_entry)
    end

    it 'validates the message variables' do
      entry = Gitlab::I18n::PoEntry.new({ msgid: 'Hello', msgstr: 'Bonjour' })

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
