# frozen_string_literal: true

require 'rspec/parameterized'
require 'gitlab/rspec/all'

require_relative '../../../../tooling/lib/tooling/gettext_extractor'
require_relative '../../../support/tmpdir'

RSpec.describe Tooling::GettextExtractor, feature_category: :tooling, quarantine: 'https://gitlab.com/gitlab-org/gitlab/-/issues/486873' do
  include StubENV
  include TmpdirHelper

  let(:base_dir) { mktmpdir }
  let(:instance) { described_class.new(backend_glob: '*.{rb,haml,erb}', glob_base: base_dir) }
  let(:frontend_status) { true }

  let(:files) do
    {
      rb_file: File.join(base_dir, 'ruby.rb'),
      haml_file: File.join(base_dir, 'template.haml'),
      erb_file: File.join(base_dir, 'template.erb')
    }
  end

  before do
    # Disable parallelism in specs in order to suppress some confusing stack traces
    stub_env(
      'PARALLEL_PROCESSOR_COUNT' => 0
    )
    # Mock Backend files
    File.write(files[:rb_file], '[_("RB"), _("All"), n_("Apple", "Apples", size), s_("Context|A"), N_("All2") ]')
    File.write(
      files[:erb_file],
      '<h1><%= _("ERB") + _("All") + n_("Pear", "Pears", size) + s_("Context|B") + N_("All2") %></h1>'
    )
    File.write(
      files[:haml_file],
      '%h1= _("HAML") + _("All") + n_("Cabbage", "Cabbages", size) + s_("Context|C") + N_("All2")'
    )
    # Stub out Frontend file parsing
    status = {}
    allow(status).to receive(:success?).and_return(frontend_status)
    allow(Open3).to receive(:capture2)
                       .with("node scripts/frontend/extract_gettext_all.js --all")
                       .and_return([
                         '{"example.js": [ ["JS"], ["All"], ["Mango\u0000Mangoes"], ["Context|D"], ["All2"] ] }',
                         status
                       ])
  end

  describe '::HamlParser' do
    # Testing with a non-externalized string, as the functionality
    # is properly tested later on
    it '#parse_source' do
      expect(described_class::HamlParser.new(files[:haml_file]).parse_source('%h1= "Test"')).to be_empty
    end
  end

  describe '#parse' do
    it 'collects and merges translatable strings from frontend and backend' do
      expect(instance.parse([]).to_h { |entry| [entry.msgid, entry.msgid_plural] }).to eq({
        'All' => nil,
        'All2' => nil,
        'Context|A' => nil,
        'Context|B' => nil,
        'Context|C' => nil,
        'Context|D' => nil,
        'ERB' => nil,
        'HAML' => nil,
        'JS' => nil,
        'RB' => nil,
        'Apple' => 'Apples',
        'Cabbage' => 'Cabbages',
        'Mango' => 'Mangoes',
        'Pear' => 'Pears'
      })
    end

    it 're-raises error from backend extraction' do
      allow(instance).to receive(:parse_backend_file).and_raise(StandardError)

      expect { instance.parse([]) }.to raise_error(StandardError)
    end

    context 'when frontend extraction raises an error' do
      let(:frontend_status) { false }

      it 'is re-raised' do
        expect { instance.parse([]) }.to raise_error(StandardError, 'Could not parse frontend files')
      end
    end
  end

  describe '#generate_pot' do
    subject { instance.generate_pot }

    it 'produces pot without date headers' do
      expect(subject).not_to include('POT-Creation-Date:')
      expect(subject).not_to include('PO-Revision-Date:')
    end

    it 'produces pot file with all translated strings, sorted by msg id' do
      expect(subject).to eql <<~POT_FILE
        # SOME DESCRIPTIVE TITLE.
        # Copyright (C) YEAR THE PACKAGE'S COPYRIGHT HOLDER
        # This file is distributed under the same license as the gitlab package.
        # FIRST AUTHOR <EMAIL@ADDRESS>, YEAR.
        #
        #, fuzzy
        msgid ""
        msgstr ""
        "Project-Id-Version: gitlab 1.0.0\\n"
        "Report-Msgid-Bugs-To: \\n"
        "Last-Translator: FULL NAME <EMAIL@ADDRESS>\\n"
        "Language-Team: LANGUAGE <LL@li.org>\\n"
        "Language: \\n"
        "MIME-Version: 1.0\\n"
        "Content-Type: text/plain; charset=UTF-8\\n"
        "Content-Transfer-Encoding: 8bit\\n"
        "Plural-Forms: nplurals=INTEGER; plural=EXPRESSION;\\n"

        msgid "All"
        msgstr ""

        msgid "All2"
        msgstr ""

        msgid "Apple"
        msgid_plural "Apples"
        msgstr[0] ""
        msgstr[1] ""

        msgid "Cabbage"
        msgid_plural "Cabbages"
        msgstr[0] ""
        msgstr[1] ""

        msgid "Context|A"
        msgstr ""

        msgid "Context|B"
        msgstr ""

        msgid "Context|C"
        msgstr ""

        msgid "Context|D"
        msgstr ""

        msgid "ERB"
        msgstr ""

        msgid "HAML"
        msgstr ""

        msgid "JS"
        msgstr ""

        msgid "Mango"
        msgid_plural "Mangoes"
        msgstr[0] ""
        msgstr[1] ""

        msgid "Pear"
        msgid_plural "Pears"
        msgstr[0] ""
        msgstr[1] ""

        msgid "RB"
        msgstr ""
      POT_FILE
    end
  end

  # This private methods is tested directly, because unfortunately it is called
  # with the "Parallel" gem. As the parallel gem executes this function in a different
  # thread, our coverage reporting is confused
  #
  # On the other hand, the tests are also more readable, so maybe a win-win
  describe '#parse_backend_file' do
    subject { instance.send(:parse_backend_file, curr_file) }

    where do
      {
        'with ruby file' => {
          invalid_syntax: 'x = {id: _("RB")',
          file: :rb_file,
          result: {
            'All' => nil,
            'All2' => nil,
            'Context|A' => nil,
            'RB' => nil, 'Apple' => 'Apples'
          },
          parser: GetText::RubyParser
        },
        'with haml file' => {
          invalid_syntax: "  %a\n- content = _('HAML')",
          file: :haml_file,
          result: {
            'All' => nil,
            'All2' => nil,
            'Context|C' => nil,
            'HAML' => nil,
            'Cabbage' => 'Cabbages'
          },
          parser: described_class::HamlParser
        },
        'with erb file' => {
          invalid_syntax: "<% x = {id: _('ERB') %>",
          file: :erb_file,
          result: {
            'All' => nil,
            'All2' => nil,
            'Context|B' => nil,
            'ERB' => nil,
            'Pear' => 'Pears'
          },
          parser: GetText::ErbParser
        }
      }
    end

    with_them do
      let(:curr_file) { files[file] }

      context 'when file has valid syntax' do
        before do
          allow(parser).to receive(:new).and_call_original
        end

        it 'parses file and returns extracted strings as POEntries' do
          expect(subject.map(&:class).uniq).to match_array([GetText::POEntry])
          expect(subject.to_h { |entry| [entry.msgid, entry.msgid_plural] }).to eq(result)
          expect(parser).to have_received(:new)
        end
      end

      # We do not worry about syntax errors in these file types, as it is _not_ the job of
      # gettext extractor to ensure correctness of the files. These errors should raise
      # in other places
      context 'when file has invalid syntax' do
        before do
          File.write(curr_file, invalid_syntax)
        end

        it 'does not raise error' do
          expect { subject }.not_to raise_error
        end
      end

      context 'when file does not contain "_("' do
        before do
          allow(parser).to receive(:new).and_call_original
          File.write(curr_file, '"abcdef"')
        end

        it 'never parses the file and returns empty array' do
          expect(subject).to be_empty
          expect(parser).not_to have_received(:new)
        end
      end
    end

    context 'with unsupported file containing "_("' do
      let(:curr_file) { File.join(base_dir, 'foo.unsupported') }

      before do
        File.write(curr_file, '_("Test")')
      end

      it 'raises error' do
        expect { subject }.to raise_error(NotImplementedError)
      end
    end
  end
end
