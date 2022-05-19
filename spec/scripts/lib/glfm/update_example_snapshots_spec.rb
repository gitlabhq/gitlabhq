# frozen_string_literal: true
require 'fast_spec_helper'
require_relative '../../../../scripts/lib/glfm/update_example_snapshots'

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
  let(:es_html_yml_io) { StringIO.new }
  let(:es_prosemirror_json_yml_path) { described_class::ES_PROSEMIRROR_JSON_YML_PATH }
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

      ```````````````````````````````` example strikethrough
      __bold with more text__
      .
      <p><strong>bold with more text</strong></p>
      ````````````````````````````````

      <div class="extension">

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

      <!-- END TESTS -->

      # Appendix

      Appendix text.
    GLFM_SPEC_TXT_CONTENTS
  end

  let(:glfm_example_status_yml_contents) do
    <<~GLFM_EXAMPLE_STATUS_YML_CONTENTS
      ---
      - 07_01_first_gitlab_specific_section_with_examples_strong_but_with_two_asterisks:
        skip_update_example_snapshots: false
        skip_running_snapshot_static_html_tests: false
        skip_running_snapshot_wysiwyg_html_tests: false
        skip_running_snapshot_prosemirror_json_tests: false
        skip_running_conformance_static_tests: false
        skip_running_conformance_wysiwyg_tests: false
      - 07_02_first_gitlab_specific_section_with_examples_strong_but_with_html:
        skip_update_example_snapshots: false
        skip_running_snapshot_static_html_tests: false
        skip_running_snapshot_wysiwyg_html_tests: false
        skip_running_snapshot_prosemirror_json_tests: false
        skip_running_conformance_static_tests: false
        skip_running_conformance_wysiwyg_tests: false
    GLFM_EXAMPLE_STATUS_YML_CONTENTS
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
    allow(File).to receive(:open).with(es_html_yml_path, 'w') { es_html_yml_io }
    allow(File).to receive(:open).with(es_prosemirror_json_yml_path, 'w') { es_prosemirror_json_yml_io }

    # output files which are also input files
    allow(File).to receive(:open).with(es_markdown_yml_path, 'w') { es_markdown_yml_io }
    allow(File).to receive(:open).with(es_markdown_yml_path) { es_markdown_yml_io }

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

  describe 'writing examples_index.yml' do
    let(:es_examples_index_yml_contents) { reread_io(es_examples_index_yml_io) }
    let(:expected_examples_index_yml_contents) do
      <<~ES_EXAMPLES_INDEX_YML_CONTENTS
        ---
        02_01__inlines__strong__01:
          spec_txt_example_position: 1
          source_specification: commonmark
        02_01__inlines__strong__02:
          spec_txt_example_position: 2
          source_specification: github
        02_02__inlines__strikethrough_extension__01:
          spec_txt_example_position: 3
          source_specification: github
        03_01__first_gitlab_specific_section_with_examples__strong_but_with_two_asterisks__01:
          spec_txt_example_position: 4
          source_specification: gitlab
        04_01__second_gitlab_specific_section_with_examples__strong_but_with_html__01:
          spec_txt_example_position: 5
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
      <<~ES_MARKDOWN_YML_CONTENTS
        ---
        02_01__inlines__strong__01: |
          __bold__
        02_01__inlines__strong__02: |
          __bold with more text__
        02_02__inlines__strikethrough_extension__01: |
          ~~Hi~~ Hello, world!
        03_01__first_gitlab_specific_section_with_examples__strong_but_with_two_asterisks__01: |
          **bold**
        04_01__second_gitlab_specific_section_with_examples__strong_but_with_html__01: |
          <strong>
          bold
          </strong>
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

    let(:glfm_example_status_yml_contents) do
      <<~GLFM_EXAMPLE_STATUS_YML_CONTENTS
        ---
        - 02_01_gitlab_specific_section_with_examples_strong_but_with_two_asterisks:
          skip_update_example_snapshots: false
          skip_running_snapshot_static_html_tests: false
          skip_running_snapshot_wysiwyg_html_tests: false
          skip_running_snapshot_prosemirror_json_tests: false
          skip_running_conformance_static_tests: false
          skip_running_conformance_wysiwyg_tests: false
      GLFM_EXAMPLE_STATUS_YML_CONTENTS
    end

    let(:glfm_spec_txt_contents) do
      <<~GLFM_SPEC_TXT_CONTENTS
        ---
        title: GitLab Flavored Markdown Spec
        ...

        # Introduction

        # GitLab-Specific Section with Examples

        ## Strong but with two asterisks

        ```````````````````````````````` example gitlab strong
        **bold**
        .
        <p><strong>bold</strong></p>
        ````````````````````````````````
        <!-- END TESTS -->

        # Appendix

        Appendix text.
      GLFM_SPEC_TXT_CONTENTS
    end

    let(:expected_html_yml_contents) do
      <<~ES_HTML_YML_CONTENTS
        ---
        02_01__gitlab_specific_section_with_examples__strong_but_with_two_asterisks__01:
          canonical: |
            <p><strong>bold</strong></p>
          static: |-
            <p data-sourcepos="1:1-1:8" dir="auto"><strong>bold</strong></p>
          wysiwyg: |-
            <p><strong>bold</strong></p>
      ES_HTML_YML_CONTENTS
    end

    let(:expected_prosemirror_json_contents) do
      <<~ES_PROSEMIRROR_JSON_YML_CONTENTS
        ---
        02_01__gitlab_specific_section_with_examples__strong_but_with_two_asterisks__01: |-
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
    it 'writes the correct content' do
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
