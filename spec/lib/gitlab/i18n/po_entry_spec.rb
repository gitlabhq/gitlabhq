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

  describe '#expected_plurals' do
    it 'returns nil when the entry is an actual translation' do
      data = { msgid: 'Hello world', msgstr: 'Bonjour monde' }
      entry = described_class.new(data)

      expect(entry.expected_plurals).to be_nil
    end

    it 'returns the number of plurals' do
      data = {
        msgid: "",
        msgstr: [
          "",
          "Project-Id-Version: gitlab 1.0.0\\n",
          "Report-Msgid-Bugs-To: \\n",
          "PO-Revision-Date: 2017-07-13 12:10-0500\\n",
          "Language-Team: Spanish\\n",
          "Language: es\\n",
          "MIME-Version: 1.0\\n",
          "Content-Type: text/plain; charset=UTF-8\\n",
          "Content-Transfer-Encoding: 8bit\\n",
          "Plural-Forms: nplurals=2; plural=n != 1;\\n",
          "Last-Translator: Bob Van Landuyt <bob@gitlab.com>\\n",
          "X-Generator: Poedit 2.0.2\\n"
        ]
      }
      entry = described_class.new(data)

      expect(entry.expected_plurals).to eq(2)
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
end
