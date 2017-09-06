require 'spec_helper'

describe Gitlab::I18n::MetadataEntry do
  describe '#expected_plurals' do
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

    it 'returns 0 for the POT-metadata' do
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
          "Plural-Forms: nplurals=INTEGER; plural=EXPRESSION;\n",
          "Last-Translator: Bob Van Landuyt <bob@gitlab.com>\\n",
          "X-Generator: Poedit 2.0.2\\n"
        ]
      }
      entry = described_class.new(data)

      expect(entry.expected_plurals).to eq(0)
    end
  end
end
