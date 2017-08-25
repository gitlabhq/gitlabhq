require 'spec_helper'

describe Gitlab::I18n::PoEntry do
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
end
