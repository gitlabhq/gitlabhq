# frozen_string_literal: true

require 'fast_spec_helper'
require 'gitlab/rspec/next_instance_of'

require_relative '../../../../scripts/lib/glfm/update_specification'

# IMPORTANT NOTE: See https://docs.gitlab.com/ee/development/gitlab_flavored_markdown/specification_guide/#update-specificationrb-script
# for details on the implementation and usage of the `update_specification.rb` script being tested.
# This developers guide contains diagrams and documentation of the script,
# including explanations and examples of all files it reads and writes.
#
# Note that this test is not structured in a traditional way, with multiple examples
# to cover all different scenarios. Instead, the content of the stubbed test fixture
# files are crafted to cover multiple scenarios with in a single example run.
#
# This is because the invocation of the full script is slow, because it executes
# a subshell for processing, which runs a full Rails environment.
# This results in each full run of the script taking between 30-60 seconds.
# The majority of this is spent loading the Rails environment.
#
# However, only the `with generation of spec.html` context is used
# to test this slow sub-process, and it only contains one example.
#
# All other tests currently in the file pass the `skip_spec_html_generation: true`
# flag to `#process`, which skips the slow sub-process. All of these other tests
# should run in sub-second time when the Spring pre-loader is used. This allows
# logic which is not directly related to the slow sub-processes to be TDD'd with a
# very rapid feedback cycle.
RSpec.describe Glfm::UpdateSpecification, '#process', feature_category: :team_planning do
  include NextInstanceOf

  subject { described_class.new }

  let(:ghfm_spec_txt_uri) { described_class::GHFM_SPEC_TXT_URI }
  let(:ghfm_spec_txt_uri_parsed) { instance_double(URI::HTTPS, :ghfm_spec_txt_uri_parsed) }
  let(:ghfm_spec_txt_uri_io) { StringIO.new(ghfm_spec_txt_contents) }
  let(:ghfm_spec_md_path) { described_class::GHFM_SPEC_MD_PATH }
  let(:ghfm_spec_txt_local_io) { StringIO.new(ghfm_spec_txt_contents) }

  let(:glfm_official_specification_md_path) { described_class::GLFM_OFFICIAL_SPECIFICATION_MD_PATH }
  let(:glfm_official_specification_md_io) { StringIO.new(glfm_official_specification_md_contents) }
  let(:glfm_internal_extensions_md_path) { described_class::GLFM_INTERNAL_EXTENSIONS_MD_PATH }
  let(:glfm_internal_extensions_md_io) { StringIO.new(glfm_internal_extensions_md_contents) }
  let(:glfm_spec_txt_path) { described_class::GLFM_SPEC_TXT_PATH }
  let(:glfm_spec_txt_io) { StringIO.new }
  let(:glfm_spec_html_path) { described_class::GLFM_SPEC_HTML_PATH }
  let(:glfm_spec_html_io) { StringIO.new }
  let(:es_snapshot_spec_md_path) { described_class::ES_SNAPSHOT_SPEC_MD_PATH }
  let(:es_snapshot_spec_md_io) { StringIO.new }
  let(:es_snapshot_spec_html_path) { described_class::ES_SNAPSHOT_SPEC_HTML_PATH }
  let(:es_snapshot_spec_html_io) { StringIO.new }
  let(:markdown_tempfile_io) { StringIO.new }

  let(:ghfm_spec_txt_examples) do
    <<~MARKDOWN
      # Section with examples

      ## Emphasis and strong

      ```````````````````````````````` example
      _EMPHASIS LINE 1_
      _EMPHASIS LINE 2_
      .
      <p><em>EMPHASIS LINE 1</em>
      <em>EMPHASIS LINE 2</em></p>
      ````````````````````````````````

      ```````````````````````````````` example
      __STRONG!__
      .
      <p><strong>STRONG!</strong></p>
      ````````````````````````````````

      End of last GitHub examples section.
    MARKDOWN
  end

  let(:ghfm_spec_txt_contents) do
    <<~MARKDOWN
      ---
      title: GitHub Flavored Markdown Spec
      version: 0.29
      date: '2019-04-06'
      license: '[CC-BY-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0/)'
      ...

      # Introduction

      GHFM Intro.

      #{ghfm_spec_txt_examples}
      <!-- END TESTS -->

      # Appendix

      Appendix text.
    MARKDOWN
  end

  let(:glfm_official_specification_md_examples) do
    <<~MARKDOWN
      # Official Specification Section with Examples

      ```````````````````````````````` example
      official example
      .
      <p>official example</p>
      ````````````````````````````````

    MARKDOWN
  end

  let(:glfm_official_specification_md_contents) do
    <<~MARKDOWN
      GLFM official text before examples

      #{described_class::BEGIN_TESTS_COMMENT_LINE_TEXT}
      #{glfm_official_specification_md_examples}
      #{described_class::END_TESTS_COMMENT_LINE_TEXT}

      GLFM official text after examples
    MARKDOWN
  end

  let(:glfm_internal_extensions_md_examples) do
    <<~MARKDOWN
      # Internal Extension Section with Examples

      ```````````````````````````````` example
      internal example
      .
      <p>internal extension example</p>
      ````````````````````````````````
    MARKDOWN
  end

  let(:glfm_internal_extensions_md_contents) do
    <<~MARKDOWN
      #{described_class::BEGIN_TESTS_COMMENT_LINE_TEXT}
      #{glfm_internal_extensions_md_examples}
      #{described_class::END_TESTS_COMMENT_LINE_TEXT}
    MARKDOWN
  end

  before do
    # Mock default ENV var values
    stub_env('UPDATE_GHFM_SPEC_MD')

    # We mock out the URI and local file IO objects with real StringIO, instead of just mock
    # objects. This gives better and more realistic coverage, while still avoiding
    # actual network and filesystem I/O during the spec run.

    # input files
    allow(URI).to receive(:parse).with(ghfm_spec_txt_uri).and_return(ghfm_spec_txt_uri_parsed)
    allow(ghfm_spec_txt_uri_parsed).to receive(:open).and_return(ghfm_spec_txt_uri_io)
    allow(File).to receive(:open).with(ghfm_spec_md_path) { ghfm_spec_txt_local_io }
    allow(File).to receive(:open).with(glfm_official_specification_md_path) do
      glfm_official_specification_md_io
    end
    allow(File).to receive(:open).with(glfm_internal_extensions_md_path) do
      glfm_internal_extensions_md_io
    end

    # output files
    allow(File).to receive(:open).with(glfm_spec_txt_path, 'w') { glfm_spec_txt_io }
    allow(File).to receive(:open).with(glfm_spec_html_path, 'w') { glfm_spec_html_io }
    allow(File).to receive(:open).with(es_snapshot_spec_md_path, 'w') { es_snapshot_spec_md_io }
    allow(File).to receive(:open).with(es_snapshot_spec_html_path, 'w') { es_snapshot_spec_html_io }

    # Allow normal opening of Tempfile files created during script execution.
    tempfile_basenames = [
      described_class::MARKDOWN_TEMPFILE_BASENAME[0],
      described_class::STATIC_HTML_TEMPFILE_BASENAME[0]
    ].join('|')
    # NOTE: This approach with a single regex seems to be the only way this can work. If you
    # attempt to have multiple `allow...and_call_original` with `any_args`, the mocked
    # parameter matching will fail to match the second one.
    tempfiles_regex = /(#{tempfile_basenames})/
    allow(File).to receive(:open).with(tempfiles_regex, any_args).and_call_original

    # Prevent console output when running tests
    allow(subject).to receive(:output)
  end

  describe 'retrieving latest GHFM spec.txt' do
    context 'when UPDATE_GHFM_SPEC_MD is not true (default)' do
      it 'does not download' do
        expect(URI).not_to receive(:parse).with(ghfm_spec_txt_uri)

        subject.process(skip_spec_html_generation: true)

        expect(reread_io(ghfm_spec_txt_local_io)).to eq(ghfm_spec_txt_contents)
      end
    end

    context 'when UPDATE_GHFM_SPEC_MD is true' do
      let(:ghfm_spec_txt_local_io) { StringIO.new }

      before do
        stub_env('UPDATE_GHFM_SPEC_MD', 'true')
        allow(File).to receive(:open).with(ghfm_spec_md_path, 'w') { ghfm_spec_txt_local_io }
      end

      context 'with success' do
        it 'downloads and saves' do
          subject.process(skip_spec_html_generation: true)

          expect(reread_io(ghfm_spec_txt_local_io)).to eq(ghfm_spec_txt_contents)
        end
      end

      context 'with error handling' do
        context 'with a version mismatch' do
          let(:ghfm_spec_txt_contents) do
            <<~MARKDOWN
              ---
              title: GitHub Flavored Markdown Spec
              version: 0.30
              ...
            MARKDOWN
          end

          it 'raises an error' do
            expect do
              subject.process(skip_spec_html_generation: true)
            end.to raise_error /version mismatch.*expected.*29.*got.*30/i
          end
        end

        context 'with a failed read of file lines' do
          let(:ghfm_spec_txt_contents) { '' }

          it 'raises an error if lines cannot be read' do
            expect { subject.process(skip_spec_html_generation: true) }.to raise_error /unable to read lines/i
          end
        end

        context 'with a failed re-read of file string' do
          before do
            allow(ghfm_spec_txt_uri_io).to receive(:read).and_return(nil)
          end

          it 'raises an error if file is blank' do
            expect { subject.process(skip_spec_html_generation: true) }.to raise_error /unable to read string/i
          end
        end
      end
    end
  end

  describe 'writing output_spec/spec.txt' do
    let(:glfm_spec_txt_contents) { reread_io(glfm_spec_txt_io) }

    before do
      subject.process(skip_spec_html_generation: true)
    end

    it 'includes only the header and official examples' do
      expected = described_class::GLFM_SPEC_TXT_HEADER + glfm_official_specification_md_contents
      expect(glfm_spec_txt_contents).to eq(expected)
    end
  end

  describe 'writing output_example_snapshots/snapshot_spec.md' do
    let(:es_snapshot_spec_md_contents) { reread_io(es_snapshot_spec_md_io) }

    context 'with valid glfm_internal_extensions.md' do
      before do
        subject.process(skip_spec_html_generation: true)
      end

      it 'replaces the header text with the GitLab version' do
        expect(es_snapshot_spec_md_contents).not_to match(/GitHub Flavored Markdown Spec/m)
        expect(es_snapshot_spec_md_contents).not_to match(/^version: \d\.\d/m)
        expect(es_snapshot_spec_md_contents).not_to match(/^date: /m)

        expect(es_snapshot_spec_md_contents).to match(/#{Regexp.escape(described_class::ES_SNAPSHOT_SPEC_MD_HEADER)}/mo)
      end

      it 'includes header and all examples', :unlimited_max_formatted_output_length do
        # rubocop:disable Style/StringConcatenation -- string contatenation is more readable
        expected = described_class::ES_SNAPSHOT_SPEC_MD_HEADER +
          ghfm_spec_txt_examples +
          "\n" +
          glfm_official_specification_md_examples +
          "\n\n" + # NOTE: We want a blank line between the official and internal examples
          glfm_internal_extensions_md_examples +
          "\n"
        # rubocop:enable Style/StringConcatenation
        expect(es_snapshot_spec_md_contents).to eq(expected)
      end
    end

    context 'with invalid non-example content in glfm_internal_extensions.md' do
      let(:glfm_internal_extensions_md_contents) do
        <<~MARKDOWN
          THIS TEXT IS NOT ALLOWED IN THIS FILE, ONLY EXAMPLES IN BEGIN/END TEST BLOCK ARE ALLOWED
          #{described_class::BEGIN_TESTS_COMMENT_LINE_TEXT}
          #{glfm_internal_extensions_md_examples}
          #{described_class::END_TESTS_COMMENT_LINE_TEXT}
        MARKDOWN
      end

      it 'raises an error' do
        expect { subject.process(skip_spec_html_generation: true) }.to raise_error /no content is allowed outside/i
      end
    end
  end

  # rubocop:disable RSpec/MultipleMemoizedHelpers
  describe 'writing output html files' do
    let(:spec_html_contents) { reread_io(glfm_spec_html_io) }
    let(:snapshot_spec_html_contents) { reread_io(es_snapshot_spec_html_io) }

    before do
      subject.process
    end

    it 'renders expected HTML', :unlimited_max_formatted_output_length do
      # NOTE: We do all assertions for both output HTML files in this same `it` example block,
      #       because calling a full `subject.process` without `skip_spec_html_generation: true`
      #       is very slow, and want to avoid doing it multiple times
      #
      #       We also do fairly loose and minimal assertions around the basic structure of the files.
      #       Otherwise, if we asserted the complete exact structure of the HTML, this would be a
      #       brittle test which would breaks every time that something minor changed around the
      #       GLFM rendering. E.g. classes, ids, attribute ordering, etc. All of this behavior
      #       should be thoroughly covered elsewhere by other testing. If there are regressions
      #       in the update specification logic in the future which are not caught by this example,
      #       additional test coverage can be added as necessary.

      # --------------------
      # spec.html assertions
      # --------------------

      # correct title should in a header
      expect(spec_html_contents).to match(%r{<h1.*#{described_class::GLFM_SPEC_TXT_TITLE}</h1>}o)

      # correct text should be included with correct ordering
      expect(spec_html_contents)
        .to match(%r{official text before.*official example.*official text after}m)

      # -----------------------------
      # snapshot_spec.html assertions
      # -----------------------------

      # correct title should in a header
      expect(snapshot_spec_html_contents).to match(%r{<h1.*#{described_class::ES_SNAPSHOT_SPEC_TITLE}</h1>}o)

      # correct example text should be included
      expect(snapshot_spec_html_contents)
        .to match(%r{internal example}m)

      # -----------------------------
      # general formatting assertions
      # -----------------------------

      md = '_EMPHASIS LINE 1_'
      html = '&lt;em&gt;EMPHASIS LINE 1&lt;/em&gt;'

      # examples should have markdown and HTML in separate pre+code blocks
      expected_example_1_regex = "<pre.*<code.*#{md}.*</code></pre>.*<pre.*<code.*#{html}.*</code></pre>"
      expect(snapshot_spec_html_contents).to match(%r{#{expected_example_1_regex}}m)

      # examples should have proper divs prepended for numbering, links, and styling
      empty_div_for_example_class = '<div>'
      examplenum_div = '<div><a href="#example-1">Example 1</a></div>'
      expect(snapshot_spec_html_contents)
        .to match(%r{#{empty_div_for_example_class}\n#{examplenum_div}.*#{expected_example_1_regex}.*}m)
    end
  end
  # rubocop:enable RSpec/MultipleMemoizedHelpers

  def reread_io(io)
    # Reset the io StringIO to the beginning position of the buffer
    io.seek(0)
    io.read
  end
end
