require 'spec_helper'

describe Gitlab::I18n::TranslationEntry do
  describe '#singular_translation' do
    it 'returns the normal `msgstr` for translations without plural' do
      data = { msgid: 'Hello world', msgstr: 'Bonjour monde' }
      entry = described_class.new(data)

      expect(entry.singular_translation).to eq('Bonjour monde')
    end

    it 'returns the first string for entries with plurals' do
      data = {
        msgid: 'Hello world',
        msgid_plural: 'Hello worlds',
        'msgstr[0]' => 'Bonjour monde',
        'msgstr[1]' => 'Bonjour mondes'
      }
      entry = described_class.new(data)

      expect(entry.singular_translation).to eq('Bonjour monde')
    end
  end

  describe '#all_translations' do
    it 'returns all translations for singular translations' do
      data = { msgid: 'Hello world', msgstr: 'Bonjour monde' }
      entry = described_class.new(data)

      expect(entry.all_translations).to eq(['Bonjour monde'])
    end

    it 'returns all translations when including plural translations' do
      data = {
        msgid: 'Hello world',
        msgid_plural: 'Hello worlds',
        'msgstr[0]' => 'Bonjour monde',
        'msgstr[1]' => 'Bonjour mondes'
      }
      entry = described_class.new(data)

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
      entry = described_class.new(data)

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
      entry = described_class.new(data)

      expect(entry.plural_translations).to eq(['Bonjour mondes', 'Bonjour tous les mondes'])
    end
  end

  describe '#has_singular?' do
    it 'has a singular when the translation is not pluralized' do
      data = {
        msgid: 'hello world',
        msgstr: 'hello'
      }
      entry = described_class.new(data)

      expect(entry).to have_singular
    end

    it 'has a singular when plural and singular are separately defined' do
      data = {
        msgid: 'hello world',
        msgid_plural: 'hello worlds',
        "msgstr[0]" => 'hello world',
        "msgstr[1]" => 'hello worlds'
      }
      entry = described_class.new(data)

      expect(entry).to have_singular
    end

    it 'does not have a separate singular if the plural string only has one translation' do
      data = {
        msgid: 'hello world',
        msgid_plural: 'hello worlds',
        "msgstr[0]" => 'hello worlds'
      }
      entry = described_class.new(data)

      expect(entry).not_to have_singular
    end
  end

  describe '#msgid_contains_newlines'do
    it 'is true when the msgid is an array' do
      data = { msgid: %w(hello world) }
      entry = described_class.new(data)

      expect(entry.msgid_contains_newlines?).to be_truthy
    end
  end

  describe '#plural_id_contains_newlines'do
    it 'is true when the msgid is an array' do
      data = { plural_id: %w(hello world) }
      entry = described_class.new(data)

      expect(entry.plural_id_contains_newlines?).to be_truthy
    end
  end

  describe '#translations_contain_newlines'do
    it 'is true when the msgid is an array' do
      data = { msgstr: %w(hello world) }
      entry = described_class.new(data)

      expect(entry.translations_contain_newlines?).to be_truthy
    end
  end
end
