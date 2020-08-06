# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::I18n::TranslationEntry do
  describe '#singular_translation' do
    it 'returns the normal `msgstr` for translations without plural' do
      data = { msgid: 'Hello world', msgstr: 'Bonjour monde' }
      entry = described_class.new(entry_data: data, nplurals: 2, html_allowed: nil)

      expect(entry.singular_translation).to eq('Bonjour monde')
    end

    it 'returns the first string for entries with plurals' do
      data = {
        msgid: 'Hello world',
        msgid_plural: 'Hello worlds',
        'msgstr[0]' => 'Bonjour monde',
        'msgstr[1]' => 'Bonjour mondes'
      }
      entry = described_class.new(entry_data: data, nplurals: 2, html_allowed: nil)

      expect(entry.singular_translation).to eq('Bonjour monde')
    end
  end

  describe '#all_translations' do
    it 'returns all translations for singular translations' do
      data = { msgid: 'Hello world', msgstr: 'Bonjour monde' }
      entry = described_class.new(entry_data: data, nplurals: 2, html_allowed: nil)

      expect(entry.all_translations).to eq(['Bonjour monde'])
    end

    it 'returns all translations when including plural translations' do
      data = {
        msgid: 'Hello world',
        msgid_plural: 'Hello worlds',
        'msgstr[0]' => 'Bonjour monde',
        'msgstr[1]' => 'Bonjour mondes'
      }
      entry = described_class.new(entry_data: data, nplurals: 2, html_allowed: nil)

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
      entry = described_class.new(entry_data: data, nplurals: 1, html_allowed: nil)

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
      entry = described_class.new(entry_data: data, nplurals: 3, html_allowed: nil)

      expect(entry.plural_translations).to eq(['Bonjour mondes', 'Bonjour tous les mondes'])
    end
  end

  describe '#has_singular_translation?' do
    it 'has a singular when the translation is not pluralized' do
      data = {
        msgid: 'hello world',
        msgstr: 'hello'
      }
      entry = described_class.new(entry_data: data, nplurals: 2, html_allowed: nil)

      expect(entry).to have_singular_translation
    end

    it 'has a singular when plural and singular are separately defined' do
      data = {
        msgid: 'hello world',
        msgid_plural: 'hello worlds',
        "msgstr[0]" => 'hello world',
        "msgstr[1]" => 'hello worlds'
      }
      entry = described_class.new(entry_data: data, nplurals: 2, html_allowed: nil)

      expect(entry).to have_singular_translation
    end

    it 'does not have a separate singular if the plural string only has one translation' do
      data = {
        msgid: 'hello world',
        msgid_plural: 'hello worlds',
        "msgstr[0]" => 'hello worlds'
      }
      entry = described_class.new(entry_data: data, nplurals: 1, html_allowed: nil)

      expect(entry).not_to have_singular_translation
    end
  end

  describe '#msgid_contains_newlines' do
    it 'is true when the msgid is an array' do
      data = { msgid: %w(hello world) }
      entry = described_class.new(entry_data: data, nplurals: 2, html_allowed: nil)

      expect(entry.msgid_has_multiple_lines?).to be_truthy
    end
  end

  describe '#plural_id_contains_newlines' do
    it 'is true when the msgid is an array' do
      data = { msgid_plural: %w(hello world) }
      entry = described_class.new(entry_data: data, nplurals: 2, html_allowed: nil)

      expect(entry.plural_id_has_multiple_lines?).to be_truthy
    end
  end

  describe '#translations_contain_newlines' do
    it 'is true when the msgid is an array' do
      data = { msgstr: %w(hello world) }
      entry = described_class.new(entry_data: data, nplurals: 2, html_allowed: nil)

      expect(entry.translations_have_multiple_lines?).to be_truthy
    end
  end

  describe '#contains_unescaped_chars' do
    let(:data) { { msgid: '' } }
    let(:entry) { described_class.new(entry_data: data, nplurals: 2, html_allowed: nil) }

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
      entry = described_class.new(entry_data: data, nplurals: 2, html_allowed: nil)

      expect(entry).to receive(:contains_unescaped_chars?).and_call_original
      expect(entry.msgid_contains_unescaped_chars?).to be_truthy
    end
  end

  describe '#plural_id_contains_unescaped_chars' do
    it 'is true when the plural msgid contains a `%`' do
      data = { msgid_plural: '「100%確定」' }
      entry = described_class.new(entry_data: data, nplurals: 2, html_allowed: nil)

      expect(entry).to receive(:contains_unescaped_chars?).and_call_original
      expect(entry.plural_id_contains_unescaped_chars?).to be_truthy
    end
  end

  describe '#translations_contain_unescaped_chars' do
    it 'is true when the translation contains a `%`' do
      data = { msgstr: '「100%確定」' }
      entry = described_class.new(entry_data: data, nplurals: 2, html_allowed: nil)

      expect(entry).to receive(:contains_unescaped_chars?).and_call_original
      expect(entry.translations_contain_unescaped_chars?).to be_truthy
    end
  end

  describe '#msgid_contains_potential_html?' do
    subject(:entry) { described_class.new(entry_data: data, nplurals: 2, html_allowed: nil) }

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
    subject(:entry) { described_class.new(entry_data: data, nplurals: 2, html_allowed: nil) }

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
    subject(:entry) { described_class.new(entry_data: data, nplurals: 2, html_allowed: nil) }

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

  describe '#msgid_html_allowed?' do
    subject(:entry) do
      described_class.new(entry_data: { msgid: 'String with a <strong>' }, nplurals: 2, html_allowed: html_todo)
    end

    context 'when the html in the string is in the todolist' do
      let(:html_todo) { { 'plural_id' => nil, 'translations' => [] } }

      it 'returns true' do
        expect(entry.msgid_html_allowed?).to be true
      end
    end

    context 'when the html in the string is not in the todolist' do
      let(:html_todo) { nil }

      it 'returns false' do
        expect(entry.msgid_html_allowed?).to be false
      end
    end
  end

  describe '#plural_id_html_allowed?' do
    subject(:entry) do
      described_class.new(entry_data: { msgid_plural: 'String with many <strong>' }, nplurals: 2, html_allowed: html_todo)
    end

    context 'when the html in the string is in the todolist' do
      let(:html_todo) { { 'plural_id' => 'String with many <strong>', 'translations' => [] } }

      it 'returns true' do
        expect(entry.plural_id_html_allowed?).to be true
      end
    end

    context 'when the html in the string is not in the todolist' do
      let(:html_todo) { { 'plural_id' => 'String with some <strong>', 'translations' => [] } }

      it 'returns false' do
        expect(entry.plural_id_html_allowed?).to be false
      end
    end
  end

  describe '#translations_html_allowed?' do
    subject(:entry) do
      described_class.new(entry_data: { msgstr: 'String with a <strong>' }, nplurals: 2, html_allowed: html_todo)
    end

    context 'when the html in the string is in the todolist' do
      let(:html_todo) { { 'plural_id' => nil, 'translations' => ['String with a <strong>'] } }

      it 'returns true' do
        expect(entry.translations_html_allowed?).to be true
      end
    end

    context 'when the html in the string is not in the todolist' do
      let(:html_todo) { { 'plural_id' => nil, 'translations' => ['String with a different <strong>'] } }

      it 'returns false' do
        expect(entry.translations_html_allowed?).to be false
      end
    end

    context 'when the todolist only has the msgid' do
      let(:html_todo) { { 'plural_id' => nil, 'translations' => nil } }

      it 'returns false' do
        expect(entry.translations_html_allowed?).to be false
      end
    end
  end
end
