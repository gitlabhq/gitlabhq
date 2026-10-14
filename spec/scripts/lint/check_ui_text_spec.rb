# frozen_string_literal: true

require 'fast_spec_helper'
require 'tmpdir'
require_relative '../../../scripts/lint/check_ui_text'

RSpec.describe Lint::CheckUiText, feature_category: :tooling do
  let(:temp_dir) { Dir.mktmpdir }
  let(:docs_dir) { File.join(temp_dir, 'doc') }
  let(:pot_path) { File.join(temp_dir, 'gitlab.pot') }

  # A minimal pot file. `Type name` is quoted in the product, so it exercises
  # the unescaping the parser leaves to us.
  let(:pot_contents) do
    <<~POT
      msgid ""
      msgstr ""
      "Content-Type: text/plain; charset=UTF-8\\n"

      msgid "Cancel"
      msgstr ""

      msgid "Job|Cancel"
      msgstr ""

      msgid "Search or go to…"
      msgstr ""

      msgid "Webhooks|Secret token"
      msgstr ""

      msgid "\\"Type name\\""
      msgstr ""

    POT
  end

  before do
    FileUtils.mkdir_p(docs_dir)
    File.write(pot_path, pot_contents)
    stub_const("#{described_class}::POT_FILE", pot_path)
  end

  after do
    FileUtils.rm_rf(temp_dir)
  end

  def write_doc(content, name: 'page.md')
    File.write(File.join(docs_dir, name), content)
  end

  def offences_for(content)
    write_doc(content)
    described_class.new(docs_dir).send(:check_file, File.join(docs_dir, 'page.md'))
  end

  describe '#run' do
    it 'passes and reports the file count when every shortcode is valid' do
      write_doc('Select {{< ui text="Cancel" >}}.')

      result = nil
      expect { result = described_class.new(docs_dir).run }
        .to output(/UI text check passed\. Checked 1 file\(s\)/).to_stdout
      expect(result).to eq(0)
    end

    it 'fails when a string is missing from the pot file' do
      write_doc('Select {{< ui text="Not A Real Label" >}}.')

      result = nil
      expect { result = described_class.new(docs_dir).run }
        .to output(%r{Documented UI text not found in locale/gitlab\.pot}).to_stderr
      expect(result).to eq(1)
    end

    it 'returns 1 when the pot file is missing' do
      allow(File).to receive(:exist?).and_call_original
      allow(File).to receive(:exist?).with(pot_path).and_return(false)

      result = nil
      expect { result = described_class.new(docs_dir).run }
        .to output(/gitlab\.pot not found/).to_stderr
      expect(result).to eq(1)
    end

    it 'returns 0 when there is no Markdown to check' do
      result = nil
      expect { result = described_class.new(docs_dir).run }
        .to output(/No Markdown files to check/).to_stderr
      expect(result).to eq(0)
    end
  end

  describe 'matching against the pot file' do
    it 'accepts a label that exists without a namespace' do
      expect(offences_for('Select {{< ui text="Cancel" >}}.')).to be_empty
    end

    it 'accepts a namespaced label that matches exactly' do
      expect(offences_for('Select {{< ui text="Job|Cancel" >}}.')).to be_empty
    end

    it 'rejects a bare label that only exists with a namespace' do
      offences = offences_for('Paste the {{< ui text="Secret token" >}}.')

      expect(offences.map(&:reason)).to eq([:unknown_msgid])
      expect(offences.first.text).to eq('Secret token')
    end

    it 'accepts that label once it carries its namespace' do
      expect(offences_for('Paste the {{< ui text="Webhooks|Secret token" >}}.')).to be_empty
    end

    it 'names the namespaced msgid to use instead' do
      write_doc('Paste the {{< ui text="Secret token" >}}.')

      expect { described_class.new(docs_dir).run }
        .to output(/Did you mean "Webhooks\|Secret token"\?/).to_stderr
    end

    it 'rejects a namespaced label whose namespace does not exist' do
      offences = offences_for('Select {{< ui text="Nope|Cancel" >}}.')

      expect(offences.map(&:reason)).to eq([:unknown_msgid])
      expect(offences.first.text).to eq('Nope|Cancel')
    end

    it 'ignores a trailing ellipsis that the product shows but the docs omit' do
      expect(offences_for('Select {{< ui text="Search or go to" >}}.')).to be_empty
    end

    it 'unescapes quoting applied by gettext' do
      expect(described_class.new(docs_dir).send(:known?, '"Type name"')).to be(true)
    end
  end

  describe 'shortcode syntax' do
    it 'accepts the documented syntax' do
      expect(offences_for('Select {{< ui text="Cancel" >}}.')).to be_empty
    end

    {
      'self-closing' => '{{< ui text="Cancel" />}}',
      'percent delimiters' => '{{% ui text="Cancel" %}}',
      'spaces around the equals' => '{{< ui  text = "Cancel" >}}',
      'no space after the delimiter' => '{{<ui text="Cancel">}}'
    }.each do |label, shortcode|
      # Every label here is in the pot file, so the offence can only be about
      # the syntax.
      it "flags the #{label} form" do
        offences = offences_for("Select #{shortcode}.")

        expect(offences.map(&:reason)).to eq([:bad_syntax])
        expect(offences.first.text).to eq(shortcode)
      end
    end

    it 'explains how to fix it and fails the run' do
      write_doc('Select {{% ui text="Cancel" %}}.')

      result = nil
      expect { result = described_class.new(docs_dir).run }
        .to output(/UI text shortcodes with an unsupported syntax:.*Use the/m).to_stderr
      expect(result).to eq(1)
    end
  end

  describe 'shortcodes with no text' do
    [
      '{{< ui text="" >}}',
      '{{< ui text="" />}}',
      '{{< ui />}}',
      '{{< ui text />}}',
      '{{< external-ui text="" >}}'
    ].each do |shortcode|
      it "flags #{shortcode}" do
        offences = offences_for("Select #{shortcode}.")

        expect(offences.map(&:reason)).to eq([:missing_text])
        expect(offences.first.text).to eq(shortcode)
      end
    end

    it 'explains how to fix it and fails the run' do
      write_doc('Select {{< ui />}}.')

      result = nil
      expect { result = described_class.new(docs_dir).run }
        .to output(/UI text shortcodes with no text:.*Give every/m).to_stderr
      expect(result).to eq(1)
    end
  end

  describe 'external-ui' do
    it 'does not check its text against the pot file' do
      expect(offences_for('Select {{< external-ui text="New Item" >}}.')).to be_empty
    end
  end

  describe 'text that must not be treated as a shortcode' do
    it 'ignores the escaped form used in documentation examples' do
      expect(offences_for('For example, {{</* ui text="Unknown Label" */>}}.')).to be_empty
    end

    it 'ignores the escaped form of external-ui' do
      expect(offences_for('For example, {{</* external-ui text="" */>}}.')).to be_empty
    end

    it 'ignores a shortcode whose name merely starts with ui' do
      expect(offences_for('Select {{< ui-foo text="Unknown Label" >}}.')).to be_empty
    end

    it 'ignores other shortcodes' do
      expect(offences_for('Select {{< icon name="plus" >}}.')).to be_empty
    end
  end
end
