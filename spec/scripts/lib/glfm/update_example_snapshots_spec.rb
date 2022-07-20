# frozen_string_literal: true
require 'fast_spec_helper'
require_relative '../../../../scripts/lib/glfm/update_example_snapshots'

# IMPORTANT NOTE: See https://docs.gitlab.com/ee/development/gitlab_flavored_markdown/specification_guide/
# for details on the implementation and usage of the `update_example_snapshots` script being tested.
# This developers guide contains diagrams and documentation of the script,
# including explanations and examples of all files it reads and writes.
#
# Note that this test is not structured in a traditional way, with multiple examples
# to cover all different scenarios. Instead, the content of the stubbed test fixture
# files are crafted to cover multiple scenarios with in a single example run.
#
# This is because the invocation of the full script is slow, because it executes
# two subshells for processing, one which runs a full Rails environment, and one
# which runs a jest test environment. This results in each full run of the script
# taking between 30-60 seconds. The majority of this is spent loading the Rails environment.
#
# However, only the `writing html.yml and prosemirror_json.yml` context is used
# to test these slow sub-processes, and it only contains a single example.
#
# All other tests currently in the file pass the `skip_static_and_wysiwyg: true`
# flag to `#process`, which skips the slow sub-processes. All of these tests
# should run in sub-second time when the Spring pre-loader is used. This allows
# logic which is not directly related to the slow sub-processes to be TDD'd with a
# very rapid feedback cycle.
#
# Also, the textual content of the individual fixture file entries is also crafted to help
# indicate which scenarios which they are covering.
RSpec.describe Glfm::UpdateExampleSnapshots, '#process' do
  subject { described_class.new }

  # GLFM input files
  let(:glfm_spec_txt_path) { described_class::GLFM_SPEC_TXT_PATH }
  let(:glfm_spec_txt_local_io) { StringIO.new(glfm_spec_txt_contents) }
  let(:glfm_example_status_yml_path) { described_class::GLFM_EXAMPLE_STATUS_YML_PATH }
  let(:glfm_example_status_yml_io) { StringIO.new(glfm_example_status_yml_contents) }

  # Example Snapshot (ES) output files
  let(:es_examples_index_yml_path) { described_class::ES_EXAMPLES_INDEX_YML_PATH }
  let(:es_examples_index_yml_io) { StringIO.new }
  let(:es_markdown_yml_path) { described_class::ES_MARKDOWN_YML_PATH }
  let(:es_markdown_yml_io) { StringIO.new }
  let(:es_html_yml_path) { described_class::ES_HTML_YML_PATH }
  let(:es_html_yml_io_existing) { StringIO.new(es_html_yml_io_existing_contents) }
  let(:es_html_yml_io) { StringIO.new }
  let(:es_prosemirror_json_yml_path) { described_class::ES_PROSEMIRROR_JSON_YML_PATH }
  let(:es_prosemirror_json_yml_io_existing) { StringIO.new(es_prosemirror_json_yml_io_existing_contents) }
  let(:es_prosemirror_json_yml_io) { StringIO.new }

  # Internal tempfiles
  let(:static_html_tempfile_path) { Tempfile.new.path }

  let(:glfm_spec_txt_contents) do
    <<~GLFM_SPEC_TXT_CONTENTS
      ---
      title: GitLab Flavored Markdown Spec
      ...

      # Introduction

      GLFM intro text...

      # Inlines

      ## Strong

      ```````````````````````````````` example
      __bold__
      .
      <p><strong>bold</strong></p>
      ````````````````````````````````

      ```````````````````````````````` example strong
      __bold with more text__
      .
      <p><strong>bold with more text</strong></p>
      ````````````````````````````````

      <div class="extension">

      ### Motivation

      This is a third-level heading with no examples, as exists in the actual GHFM
      specification. It exists to drive a fix for a bug where this caused the
      indexing and ordering to in examples_index.yml to be incorrect.

      ### Another H3

      This is a second consecutive third-level heading. It exists to drive full code coverage
      for this scenario, although it doesn't (yet) exist in the actual spec.txt.

      ## An H2 with all disabled examples

      In the GHFM specification, the 'Task list items (extension)' contains only "disabled"
      examples, which are ignored by the GitHub fork of `spec_test.py`, and thus not part of the
      Markdown conformance tests, but are part of the HTML-rendered version of the specification.
      We also exclude them from our GLFM specification for consistency, but we may add
      GitLab-specific examples for the behavior instead.

      ```````````````````````````````` example disabled
      this example is disabled during conformance testing
      .
      <p>this example is disabled during conformance testing</p>
      ````````````````````````````````

      ## Strikethrough (extension)

      GFM enables the `strikethrough` extension.

      ```````````````````````````````` example strikethrough
      ~~Hi~~ Hello, world!
      .
      <p><del>Hi</del> Hello, world!</p>
      ````````````````````````````````

      </div>

      End of last GitHub examples section.

      # First GitLab-Specific Section with Examples

      ## Strong but with two asterisks

      ```````````````````````````````` example gitlab strong
      **bold**
      .
      <p><strong>bold</strong></p>
      ````````````````````````````````

      # Second GitLab-Specific Section with Examples

      ## Strong but with HTML

      ```````````````````````````````` example gitlab strong
      <strong>
      bold
      </strong>
      .
      <p><strong>
      bold
      </strong></p>
      ````````````````````````````````

      # Third GitLab-Specific Section with skipped Examples

      ## Strong but skipped

      ```````````````````````````````` example gitlab strong
      **this example will be skipped**
      .
      <p><strong>this example will be skipped</strong></p>
      ````````````````````````````````

      ## Strong but manually modified and skipped

      ```````````````````````````````` example gitlab strong
      **This example will have its manually modified static HTML, WYSIWYG HTML, and ProseMirror JSON preserved**
      .
      <p><strong>This example will have its manually modified static HTML, WYSIWYG HTML, and ProseMirror JSON preserved</strong></p>
      ````````````````````````````````

      <!-- END TESTS -->

      # Appendix

      Appendix text.
    GLFM_SPEC_TXT_CONTENTS
  end

  let(:glfm_example_status_yml_contents) do
    # language=YAML
    <<~GLFM_EXAMPLE_STATUS_YML_CONTENTS
      ---
      02_01__inlines__strong__001:
        # The skip_update_example_snapshots key is present, but false, so this example is not skipped
        skip_update_example_snapshots: false
      02_01__inlines__strong__002:
        # It is OK to have an empty (nil) value for an example statuses entry, it means they will all be false.
      05_01__third_gitlab_specific_section_with_skipped_examples__strong_but_skipped__001:
        # Always skip this example
        skip_update_example_snapshots: 'skipping this example because it is very bad'
      05_02__third_gitlab_specific_section_with_skipped_examples__strong_but_manually_modified_and_skipped__001:
        # Always skip this example, but preserve the existing manual modifications
        skip_update_example_snapshots: 'skipping this example because we have manually modified it'
    GLFM_EXAMPLE_STATUS_YML_CONTENTS
  end

  let(:es_html_yml_io_existing_contents) do
    # language=YAML
    <<~ES_HTML_YML_IO_EXISTING_CONTENTS
      ---
      00_00__obsolete_entry_to_be_deleted__001:
        canonical: |
          This entry is no longer exists in the spec.txt, and is not skipped, so it will be deleted.
        static: |-
          This entry is no longer exists in the spec.txt, and is not skipped, so it will be deleted.
        wysiwyg: |-
          This entry is no longer exists in the spec.txt, and is not skipped, so it will be deleted.
      02_01__inlines__strong__001:
        canonical: |
          This entry is existing, but not skipped, so it will be overwritten.
        static: |-
          This entry is existing, but not skipped, so it will be overwritten.
        wysiwyg: |-
          This entry is existing, but not skipped, so it will be overwritten.
      05_02__third_gitlab_specific_section_with_skipped_examples__strong_but_manually_modified_and_skipped__001:
        canonical: |
          <p><strong>This example will have its manually modified static HTML, WYSIWYG HTML, and ProseMirror JSON preserved</strong></p>
        static: |-
          <p>This is the manually modified static HTML which will be preserved</p>
        wysiwyg: |-
          <p>This is the manually modified WYSIWYG HTML which will be preserved</p>
    ES_HTML_YML_IO_EXISTING_CONTENTS
  end

  let(:es_prosemirror_json_yml_io_existing_contents) do
    # language=YAML
    <<~ES_PROSEMIRROR_JSON_YML_IO_EXISTING_CONTENTS
      ---
      00_00__obsolete_entry_to_be_deleted__001:
        {
          "obsolete": "This entry is no longer exists in the spec.txt, and is not skipped, so it will be deleted."
        }
      02_01__inlines__strong__001: |-
        {
          "existing": "This entry is existing, but not skipped, so it will be overwritten."
        }
      # 02_01__inlines__strong__002: is omitted from the existing file and skipped, to test that scenario.
      02_03__inlines__strikethrough_extension__001: |-
        {
          "type": "doc",
          "content": [
            {
              "type": "paragraph",
              "content": [
                {
                  "type": "text",
                  "text": "~~Hi~~ Hello, world!"
                }
              ]
            }
          ]
        }
      04_01__second_gitlab_specific_section_with_examples__strong_but_with_html__001: |-
        {
          "existing": "This entry is manually modified and preserved because skip_update_example_snapshot_prosemirror_json will be truthy"
        }
      05_02__third_gitlab_specific_section_with_skipped_examples__strong_but_manually_modified_and_skipped__001: |-
        {
          "existing": "This entry is manually modified and preserved because skip_update_example_snapshots will be truthy"
        }
    ES_PROSEMIRROR_JSON_YML_IO_EXISTING_CONTENTS
  end

  before do
    # We mock out the URI and local file IO objects with real StringIO, instead of just mock
    # objects. This gives better and more realistic coverage, while still avoiding
    # actual network and filesystem I/O during the spec run.

    # input files
    allow(File).to receive(:open).with(glfm_spec_txt_path) { glfm_spec_txt_local_io }
    allow(File).to receive(:open).with(glfm_example_status_yml_path) { glfm_example_status_yml_io }

    # output files
    allow(File).to receive(:open).with(es_examples_index_yml_path, 'w') { es_examples_index_yml_io }

    # output files which are also input files
    allow(File).to receive(:open).with(es_markdown_yml_path, 'w') { es_markdown_yml_io }
    allow(File).to receive(:open).with(es_markdown_yml_path) { es_markdown_yml_io }
    allow(File).to receive(:open).with(es_html_yml_path, 'w') { es_html_yml_io }
    allow(File).to receive(:open).with(es_html_yml_path) { es_html_yml_io_existing }
    allow(File).to receive(:open).with(es_prosemirror_json_yml_path, 'w') { es_prosemirror_json_yml_io }
    allow(File).to receive(:open).with(es_prosemirror_json_yml_path) { es_prosemirror_json_yml_io_existing }

    # Allow normal opening of Tempfile files created during script execution.
    tempfile_basenames = [
      described_class::MARKDOWN_TEMPFILE_BASENAME[0],
      described_class::STATIC_HTML_TEMPFILE_BASENAME[0],
      described_class::WYSIWYG_HTML_AND_JSON_TEMPFILE_BASENAME[0]
    ].join('|')
    # NOTE: This approach with a single regex seems to be the only way this can work. If you
    # attempt to have multiple `allow...and_call_original` with `any_args`, the mocked
    # parameter matching will fail to match the second one.
    tempfiles_regex = /(#{tempfile_basenames})/
    allow(File).to receive(:open).with(tempfiles_regex, any_args).and_call_original

    # Prevent console output when running tests
    allow(subject).to receive(:output)
  end

  describe 'when skip_update_example_snapshots is truthy' do
    let(:es_examples_index_yml_contents) { reread_io(es_examples_index_yml_io) }
    let(:es_markdown_yml_contents) { reread_io(es_markdown_yml_io) }
    let(:expected_unskipped_example) do
      /05_01__third_gitlab_specific_section_with_skipped_examples__strong_but_skipped__001/
    end

    it 'still writes the example to examples_index.yml' do
      subject.process(skip_static_and_wysiwyg: true)

      expect(es_examples_index_yml_contents).to match(expected_unskipped_example)
    end

    it 'still writes the example to markdown.yml' do
      subject.process(skip_static_and_wysiwyg: true)

      expect(es_markdown_yml_contents).to match(expected_unskipped_example)
    end

    describe 'when any other skip_update_example_* is also truthy' do
      let(:glfm_example_status_yml_contents) do
        # language=YAML
        <<~GLFM_EXAMPLE_STATUS_YML_CONTENTS
          ---
          02_01__inlines__strong__001:
            skip_update_example_snapshots: 'if the skip_update_example_snapshots key is truthy...'
            skip_update_example_snapshot_html_static: '...then no other skip_update_example_* keys can be truthy'
        GLFM_EXAMPLE_STATUS_YML_CONTENTS
      end

      it 'raises an error' do
        expected_msg = "Error: '02_01__inlines__strong__001' must not have any 'skip_update_example_snapshot_*' " \
          "values specified if 'skip_update_example_snapshots' is truthy"
        expect { subject.process }.to raise_error(/#{Regexp.escape(expected_msg)}/)
      end
    end
  end

  describe 'writing examples_index.yml' do
    let(:es_examples_index_yml_contents) { reread_io(es_examples_index_yml_io) }
    let(:expected_examples_index_yml_contents) do
      # language=YAML
      <<~ES_EXAMPLES_INDEX_YML_CONTENTS
        ---
        02_01__inlines__strong__001:
          spec_txt_example_position: 1
          source_specification: commonmark
        02_01__inlines__strong__002:
          spec_txt_example_position: 2
          source_specification: github
        02_03__inlines__strikethrough_extension__001:
          spec_txt_example_position: 4
          source_specification: github
        03_01__first_gitlab_specific_section_with_examples__strong_but_with_two_asterisks__001:
          spec_txt_example_position: 5
          source_specification: gitlab
        04_01__second_gitlab_specific_section_with_examples__strong_but_with_html__001:
          spec_txt_example_position: 6
          source_specification: gitlab
        05_01__third_gitlab_specific_section_with_skipped_examples__strong_but_skipped__001:
          spec_txt_example_position: 7
          source_specification: gitlab
        05_02__third_gitlab_specific_section_with_skipped_examples__strong_but_manually_modified_and_skipped__001:
          spec_txt_example_position: 8
          source_specification: gitlab
      ES_EXAMPLES_INDEX_YML_CONTENTS
    end

    it 'writes the correct content' do
      subject.process(skip_static_and_wysiwyg: true)

      expect(es_examples_index_yml_contents).to eq(expected_examples_index_yml_contents)
    end
  end

  describe 'writing markdown.yml' do
    let(:es_markdown_yml_contents) { reread_io(es_markdown_yml_io) }
    let(:expected_markdown_yml_contents) do
      # language=YAML
      <<~ES_MARKDOWN_YML_CONTENTS
        ---
        02_01__inlines__strong__001: |
          __bold__
        02_01__inlines__strong__002: |
          __bold with more text__
        02_03__inlines__strikethrough_extension__001: |
          ~~Hi~~ Hello, world!
        03_01__first_gitlab_specific_section_with_examples__strong_but_with_two_asterisks__001: |
          **bold**
        04_01__second_gitlab_specific_section_with_examples__strong_but_with_html__001: |
          <strong>
          bold
          </strong>
        05_01__third_gitlab_specific_section_with_skipped_examples__strong_but_skipped__001: |
          **this example will be skipped**
        05_02__third_gitlab_specific_section_with_skipped_examples__strong_but_manually_modified_and_skipped__001: |
          **This example will have its manually modified static HTML, WYSIWYG HTML, and ProseMirror JSON preserved**
      ES_MARKDOWN_YML_CONTENTS
    end

    it 'writes the correct content' do
      subject.process(skip_static_and_wysiwyg: true)

      expect(es_markdown_yml_contents).to eq(expected_markdown_yml_contents)
    end
  end

  describe 'writing html.yml and prosemirror_json.yml' do
    let(:es_html_yml_contents) { reread_io(es_html_yml_io) }
    let(:es_prosemirror_json_yml_contents) { reread_io(es_prosemirror_json_yml_io) }

    # NOTE: This example_status.yml is crafted in conjunction with expected_html_yml_contents
    # to test the behavior of the `skip_update_*` flags
    let(:glfm_example_status_yml_contents) do
      # language=YAML
      <<~GLFM_EXAMPLE_STATUS_YML_CONTENTS
        ---
        02_01__inlines__strong__002:
          skip_update_example_snapshot_prosemirror_json: "skipping because JSON isn't cool enough"
        03_01__first_gitlab_specific_section_with_examples__strong_but_with_two_asterisks__001:
          skip_update_example_snapshot_html_static: "skipping because there's too much static"
        04_01__second_gitlab_specific_section_with_examples__strong_but_with_html__001:
          skip_update_example_snapshot_html_wysiwyg: 'skipping because what you see is NOT what you get'
          skip_update_example_snapshot_prosemirror_json: "skipping because JSON still isn't cool enough"
        05_01__third_gitlab_specific_section_with_skipped_examples__strong_but_skipped__001:
          skip_update_example_snapshots: 'skipping this example because it is very bad'
        05_02__third_gitlab_specific_section_with_skipped_examples__strong_but_manually_modified_and_skipped__001:
          skip_update_example_snapshots: 'skipping this example because we have manually modified it'
      GLFM_EXAMPLE_STATUS_YML_CONTENTS
    end

    let(:expected_html_yml_contents) do
      # language=YAML
      <<~ES_HTML_YML_CONTENTS
        ---
        02_01__inlines__strong__001:
          canonical: |
            <p><strong>bold</strong></p>
          static: |-
            <p data-sourcepos="1:1-1:8" dir="auto"><strong>bold</strong></p>
          wysiwyg: |-
            <p><strong>bold</strong></p>
        02_01__inlines__strong__002:
          canonical: |
            <p><strong>bold with more text</strong></p>
          static: |-
            <p data-sourcepos="1:1-1:23" dir="auto"><strong>bold with more text</strong></p>
          wysiwyg: |-
            <p><strong>bold with more text</strong></p>
        02_03__inlines__strikethrough_extension__001:
          canonical: |
            <p><del>Hi</del> Hello, world!</p>
          static: |-
            <p data-sourcepos="1:1-1:20" dir="auto"><del>Hi</del> Hello, world!</p>
          wysiwyg: |-
            <p><s>Hi</s> Hello, world!</p>
        03_01__first_gitlab_specific_section_with_examples__strong_but_with_two_asterisks__001:
          canonical: |
            <p><strong>bold</strong></p>
          wysiwyg: |-
            <p><strong>bold</strong></p>
        04_01__second_gitlab_specific_section_with_examples__strong_but_with_html__001:
          canonical: |
            <p><strong>
            bold
            </strong></p>
          static: |-
            <strong>
            bold
            </strong>
        05_02__third_gitlab_specific_section_with_skipped_examples__strong_but_manually_modified_and_skipped__001:
          canonical: |
            <p><strong>This example will have its manually modified static HTML, WYSIWYG HTML, and ProseMirror JSON preserved</strong></p>
          static: |-
            <p>This is the manually modified static HTML which will be preserved</p>
          wysiwyg: |-
            <p>This is the manually modified WYSIWYG HTML which will be preserved</p>
      ES_HTML_YML_CONTENTS
    end

    let(:expected_prosemirror_json_contents) do
      # language=YAML
      <<~ES_PROSEMIRROR_JSON_YML_CONTENTS
        ---
        02_01__inlines__strong__001: |-
          {
            "type": "doc",
            "content": [
              {
                "type": "paragraph",
                "content": [
                  {
                    "type": "text",
                    "marks": [
                      {
                        "type": "bold"
                      }
                    ],
                    "text": "bold"
                  }
                ]
              }
            ]
          }
        02_03__inlines__strikethrough_extension__001: |-
          {
            "type": "doc",
            "content": [
              {
                "type": "paragraph",
                "content": [
                  {
                    "type": "text",
                    "marks": [
                      {
                        "type": "strike"
                      }
                    ],
                    "text": "Hi"
                  },
                  {
                    "type": "text",
                    "text": " Hello, world!"
                  }
                ]
              }
            ]
          }
        03_01__first_gitlab_specific_section_with_examples__strong_but_with_two_asterisks__001: |-
          {
            "type": "doc",
            "content": [
              {
                "type": "paragraph",
                "content": [
                  {
                    "type": "text",
                    "marks": [
                      {
                        "type": "bold"
                      }
                    ],
                    "text": "bold"
                  }
                ]
              }
            ]
          }
        04_01__second_gitlab_specific_section_with_examples__strong_but_with_html__001: |-
          {
            "existing": "This entry is manually modified and preserved because skip_update_example_snapshot_prosemirror_json will be truthy"
          }
        05_02__third_gitlab_specific_section_with_skipped_examples__strong_but_manually_modified_and_skipped__001: |-
          {
            "existing": "This entry is manually modified and preserved because skip_update_example_snapshots will be truthy"
          }
      ES_PROSEMIRROR_JSON_YML_CONTENTS
    end

    before do
      # NOTE: This is a necessary to avoid an `error Couldn't find an integrity file` error
      #   when invoking `yarn jest ...` on CI from within an RSpec job. It could be solved by
      #   adding `.yarn-install` to be included in the RSpec CI job, but that would be a performance
      #   hit to all RSpec jobs. We could also make a dedicate job just for this spec. However,
      #   since this is just a single script, those options may not be justified.
      described_class.new.run_external_cmd('yarn install') if ENV['CI']
    end

    # NOTE: Both `html.yml` and `prosemirror_json.yml` generation are tested in a single example, to
    # avoid slower tests, because generating the static HTML is slow due to the need to invoke
    # the rails environment. We could have separate sections, but this would require an extra flag
    # to the `process` method to independently skip static vs. WYSIWYG, which is not worth the effort.
    it 'writes the correct content', :unlimited_max_formatted_output_length do
      # expectation that skipping message is only output once per example
      expect(subject).to receive(:output).once.with(/reason.*skipping this example because it is very bad/i)

      subject.process

      expect(es_html_yml_contents).to eq(expected_html_yml_contents)
      expect(es_prosemirror_json_yml_contents).to eq(expected_prosemirror_json_contents)
    end
  end

  def reread_io(io)
    # Reset the io StringIO to the beginning position of the buffer
    io.seek(0)
    io.read
  end
end
