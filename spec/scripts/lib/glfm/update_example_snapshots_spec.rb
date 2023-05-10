# frozen_string_literal: true
require 'fast_spec_helper'
require_relative '../../../../scripts/lib/glfm/update_example_snapshots'

# IMPORTANT NOTE: See https://docs.gitlab.com/ee/development/gitlab_flavored_markdown/specification_guide/#update-example-snapshotsrb-script
# for details on the implementation and usage of the `update_example_snapshots.rb` script being tested.
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
# However, only the `with full processing of static and WYSIWYG HTML` context is used
# to test these slow sub-processes, and it only contains two examples.
#
# All other tests currently in the file pass the `skip_static_and_wysiwyg: true`
# flag to `#process`, which skips the slow sub-processes. All of these other tests
# should run in sub-second time when the Spring pre-loader is used. This allows
# logic which is not directly related to the slow sub-processes to be TDD'd with a
# very rapid feedback cycle.
#
# Also, the textual content of the individual fixture file entries is also crafted to help
# indicate which scenarios which they are covering.
# rubocop:disable RSpec/MultipleMemoizedHelpers
RSpec.describe Glfm::UpdateExampleSnapshots, '#process', feature_category: :team_planning do
  subject { described_class.new }

  # GLFM input files
  let(:es_snapshot_spec_md_path) { described_class::ES_SNAPSHOT_SPEC_MD_PATH }
  let(:es_snapshot_spec_md_local_io) { StringIO.new(es_snapshot_spec_md_contents) }
  let(:glfm_example_status_yml_path) { described_class::GLFM_EXAMPLE_STATUS_YML_PATH }
  let(:glfm_example_metadata_yml_path) { described_class::GLFM_EXAMPLE_METADATA_YML_PATH }
  let(:glfm_example_normalizations_yml_path) { described_class::GLFM_EXAMPLE_NORMALIZATIONS_YML_PATH }

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

  let(:es_snapshot_spec_md_contents) do
    <<~MARKDOWN
      ---
      title: GitLab Flavored Markdown Spec
      ...
      # Inlines

      ## Strong

      This example doesn't have an extension after the `example` keyword, so its
      `source_specification` will be `commonmark`.

      ```````````````````````````````` example
      __bold__
      .
      <p><strong>bold</strong></p>
      ````````````````````````````````

      This example has an extension after the `example` keyword, so its
      `source_specification` will be `github`.

      ```````````````````````````````` example some_extension_name
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
      for this scenario, although it doesn't (yet) exist in the actual snapshot_spec.md.

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

      ```````````````````````````````` example gitlab
      **bold**
      .
      <p><strong>bold</strong></p>
      ````````````````````````````````

      ## H2 which contains an H3

      ### Example in an H3

      The CommonMark and GHFM specifications don't have any examples inside an H3, but it is
      supported for the GLFM specification.

      ```````````````````````````````` example gitlab
      Example in an H3
      .
      <p>Example in an H3</p>
      ````````````````````````````````

      # Second GitLab-Specific Section with Examples

      ## Strong but with HTML

      This example has the `gitlab` keyword after the `example` keyword, so its
      `source_specification` will be `gitlab`.


      ```````````````````````````````` example gitlab
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

      ```````````````````````````````` example gitlab
      **this example will be skipped**
      .
      <p><strong>this example will be skipped</strong></p>
      ````````````````````````````````

      ## Strong but manually modified and skipped

      ```````````````````````````````` example gitlab
      **This example will have its manually modified static HTML, WYSIWYG HTML, and ProseMirror JSON preserved**
      .
      <p><strong>This example will have its manually modified static HTML, WYSIWYG HTML, and ProseMirror JSON preserved</strong></p>
      ````````````````````````````````

      # API Request Overrides

      This section contains examples which verify that all of the fixture models which are set up
      in `render_static_html.rb` are correctly configured. They exercise various `preview_markdown`
      endpoints via `glfm_example_metadata.yml`.

      ## Group Upload Link

      `preview_markdown` exercising `groups` API endpoint and `UploadLinkFilter`:

      ```````````````````````````````` example gitlab
      [groups-test-file](/uploads/groups-test-file)
      .
      <p><a href="groups-test-file">groups-test-file</a></p>
      ````````````````````````````````

      ## Project Repo Link

      `preview_markdown` exercising `projects` API endpoint and `RepositoryLinkFilter`:

      ```````````````````````````````` example gitlab
      [projects-test-file](projects-test-file)
      .
      <p><a href="projects-test-file">projects-test-file</a></p>
      ````````````````````````````````

      ## Project Snippet Ref

      `preview_markdown` exercising `projects` API endpoint and `SnippetReferenceFilter`:

      ```````````````````````````````` example gitlab
      This project snippet ID reference IS filtered: $88888
      .
      <p>This project snippet ID reference IS filtered: <a href="/glfm_group/glfm_project/-/snippets/88888">$88888</a>
      ````````````````````````````````

      ## Personal Snippet Ref

      `preview_markdown` exercising personal (non-project) `snippets` API endpoint. This is
      only used by the comment field on personal snippets. It has no unique custom markdown
      extension behavior, and specifically does not render snippet references via
      `SnippetReferenceFilter`, even if the ID is valid.

      ```````````````````````````````` example gitlab
      This personal snippet ID reference is NOT filtered: $99999
      .
      <p>This personal snippet ID reference is NOT filtered: $99999</p>
      ````````````````````````````````

      ## Project Wiki Link

      `preview_markdown` exercising project `wikis` API endpoint and `WikiLinkFilter`:

      ```````````````````````````````` example gitlab
      [project-wikis-test-file](project-wikis-test-file)
      .
      <p><a href="project-wikis-test-file">project-wikis-test-file</a></p>
      ````````````````````````````````
    MARKDOWN
  end

  let(:glfm_example_status_yml_contents) do
    <<~YAML
      ---
      02_01_00__inlines__strong__001:
        # The skip_update_example_snapshots key is present, but false, so this example is not skipped
        skip_update_example_snapshots: false
      02_01_00__inlines__strong__002:
        # It is OK to have an empty (nil) value for an example statuses entry, it means they will all be false.
      05_01_00__third_gitlab_specific_section_with_skipped_examples__strong_but_skipped__001:
        # Always skip this example
        skip_update_example_snapshots: 'skipping this example because it is very bad'
      05_02_00__third_gitlab_specific_section_with_skipped_examples__strong_but_manually_modified_and_skipped__001:
        # Always skip this example, but preserve the existing manual modifications
        skip_update_example_snapshots: 'skipping this example because we have manually modified it'
    YAML
  end

  let(:glfm_example_metadata_yml_contents) do
    <<~YAML
      ---
      06_01_00__api_request_overrides__group_upload_link__001:
        api_request_override_path: /groups/glfm_group/preview_markdown
      06_02_00__api_request_overrides__project_repo_link__001:
        api_request_override_path: /glfm_group/glfm_project/preview_markdown
      06_03_00__api_request_overrides__project_snippet_ref__001:
        api_request_override_path: /glfm_group/glfm_project/preview_markdown
      06_04_00__api_request_overrides__personal_snippet_ref__001:
        api_request_override_path: /-/snippets/preview_markdown
      06_05_00__api_request_overrides__project_wiki_link__001:
        api_request_override_path: /glfm_group/glfm_project/-/wikis/new_page/preview_markdown
    YAML
  end

  let(:test1) { '\1\2URI_PREFIX\4' }

  let(:glfm_example_normalizations_yml_contents) do
    # NOTE: This heredoc identifier must be quoted because we are using control characters in the heredoc body.
    #       See https://stackoverflow.com/a/73831037/25192
    <<~'YAML'
      ---
      # If a config file entry starts with `00_`, it will be skipped for validation that it exists in `examples_index.yml`
      00_shared:
        00_uri: &00_uri
          - regex: '(href|data-src)(=")(.*?)(test-file\.(png|zip)")'
            replacement: '\1\2URI_PREFIX\4'
    YAML
  end

  let(:es_html_yml_io_existing_contents) do
    <<~YAML
      ---
      01_00_00__obsolete_entry_to_be_deleted__001:
        canonical: |
          This entry is no longer exists in the snapshot_spec.md, so it will be deleted.
        static: |-
          This entry is no longer exists in the snapshot_spec.md, so it will be deleted.
        wysiwyg: |-
          This entry is no longer exists in the snapshot_spec.md, so it will be deleted.
      02_01_00__inlines__strong__001:
        canonical: |
          This entry is existing, but not skipped, so it will be overwritten.
        static: |-
          This entry is existing, but not skipped, so it will be overwritten.
        wysiwyg: |-
          This entry is existing, but not skipped, so it will be overwritten.
      05_02_00__third_gitlab_specific_section_with_skipped_examples__strong_but_manually_modified_and_skipped__001:
        canonical: |
          <p><strong>This example will have its manually modified static HTML, WYSIWYG HTML, and ProseMirror JSON preserved</strong></p>
        static: |-
          <p>This is the manually modified static HTML which will be preserved</p>
        wysiwyg: |-
          <p>This is the manually modified WYSIWYG HTML which will be preserved</p>
    YAML
  end

  let(:es_prosemirror_json_yml_io_existing_contents) do
    <<~YAML
      ---
      01_00_00__obsolete_entry_to_be_deleted__001: |-
        {
          "obsolete": "This entry is no longer exists in the snapshot_spec.md, and is not skipped, so it will be deleted."
        }
      02_01_00__inlines__strong__001: |-
        {
          "existing": "This entry is existing, but not skipped, so it will be overwritten."
        }
      02_03_00__inlines__strikethrough_extension__001: |-
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
      04_01_00__second_gitlab_specific_section_with_examples__strong_but_with_html__001: |-
        {
          "existing": "This entry is manually modified and preserved because skip_update_example_snapshot_prosemirror_json will be truthy"
        }
      05_02_00__third_gitlab_specific_section_with_skipped_examples__strong_but_manually_modified_and_skipped__001: |-
        {
          "existing": "This entry is manually modified and preserved because skip_update_example_snapshots will be truthy"
        }
    YAML
  end

  before do
    # We mock out the URI and local file IO objects with real StringIO, instead of just mock
    # objects. This gives better and more realistic coverage, while still avoiding
    # actual network and filesystem I/O during the spec run.

    # input files
    allow(File).to receive(:open).with(es_snapshot_spec_md_path) { es_snapshot_spec_md_local_io }
    allow(File).to receive(:open).with(glfm_example_status_yml_path) do
      StringIO.new(glfm_example_status_yml_contents)
    end
    allow(File).to receive(:open).with(glfm_example_metadata_yml_path) do
      StringIO.new(glfm_example_metadata_yml_contents)
    end
    allow(File).to receive(:open).with(glfm_example_normalizations_yml_path) do
      StringIO.new(glfm_example_normalizations_yml_contents)
    end

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
      described_class::METADATA_TEMPFILE_BASENAME[0],
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

  describe 'glfm_example_status.yml' do
    describe 'when skip_update_example_snapshots entry is truthy' do
      let(:es_examples_index_yml_contents) { reread_io(es_examples_index_yml_io) }
      let(:es_markdown_yml_contents) { reread_io(es_markdown_yml_io) }
      let(:expected_unskipped_example) do
        /05_01_00__third_gitlab_specific_section_with_skipped_examples__strong_but_skipped__001/
      end

      it 'still writes the example to examples_index.yml' do
        subject.process(skip_static_and_wysiwyg: true)

        expect(es_examples_index_yml_contents).to match(expected_unskipped_example)
      end

      it 'still writes the example to markdown.yml' do
        subject.process(skip_static_and_wysiwyg: true)

        expect(es_markdown_yml_contents).to match(expected_unskipped_example)
      end

      describe 'when any other skip_update_example_snapshot_* is also truthy' do
        let(:glfm_example_status_yml_contents) do
          <<~YAML
            ---
            02_01_00__inlines__strong__001:
              skip_update_example_snapshots: 'if the skip_update_example_snapshots key is truthy...'
              skip_update_example_snapshot_html_static: '...then no other skip_update_example_* keys can be truthy'
          YAML
        end

        it 'raises an error' do
          expected_msg = "Error: '02_01_00__inlines__strong__001' must not have any 'skip_update_example_snapshot_*' " \
          "values specified if 'skip_update_example_snapshots' is truthy"
          expect { subject.process }.to raise_error(/#{Regexp.escape(expected_msg)}/)
        end
      end
    end
  end

  describe 'writing examples_index.yml' do
    let(:es_examples_index_yml_contents) { reread_io(es_examples_index_yml_io) }
    let(:expected_examples_index_yml_contents) do
      <<~YAML
        ---
        02_01_00__inlines__strong__001:
          spec_example_position: 1
          source_specification: commonmark
        02_01_00__inlines__strong__002:
          spec_example_position: 2
          source_specification: github
        02_03_00__inlines__strikethrough_extension__001:
          spec_example_position: 4
          source_specification: github
        03_01_00__first_gitlab_specific_section_with_examples__strong_but_with_two_asterisks__001:
          spec_example_position: 5
          source_specification: gitlab
        03_02_01__first_gitlab_specific_section_with_examples__h2_which_contains_an_h3__example_in_an_h3__001:
          spec_example_position: 6
          source_specification: gitlab
        04_01_00__second_gitlab_specific_section_with_examples__strong_but_with_html__001:
          spec_example_position: 7
          source_specification: gitlab
        05_01_00__third_gitlab_specific_section_with_skipped_examples__strong_but_skipped__001:
          spec_example_position: 8
          source_specification: gitlab
        05_02_00__third_gitlab_specific_section_with_skipped_examples__strong_but_manually_modified_and_skipped__001:
          spec_example_position: 9
          source_specification: gitlab
        06_01_00__api_request_overrides__group_upload_link__001:
          spec_example_position: 10
          source_specification: gitlab
        06_02_00__api_request_overrides__project_repo_link__001:
          spec_example_position: 11
          source_specification: gitlab
        06_03_00__api_request_overrides__project_snippet_ref__001:
          spec_example_position: 12
          source_specification: gitlab
        06_04_00__api_request_overrides__personal_snippet_ref__001:
          spec_example_position: 13
          source_specification: gitlab
        06_05_00__api_request_overrides__project_wiki_link__001:
          spec_example_position: 14
          source_specification: gitlab
      YAML
    end

    it 'writes the correct content' do
      subject.process(skip_static_and_wysiwyg: true)

      expect(es_examples_index_yml_contents).to eq(expected_examples_index_yml_contents)
    end
  end

  describe 'writing markdown.yml' do
    let(:es_markdown_yml_contents) { reread_io(es_markdown_yml_io) }
    let(:expected_markdown_yml_contents) do
      <<~YAML
        ---
        02_01_00__inlines__strong__001: |
          __bold__
        02_01_00__inlines__strong__002: |
          __bold with more text__
        02_03_00__inlines__strikethrough_extension__001: |
          ~~Hi~~ Hello, world!
        03_01_00__first_gitlab_specific_section_with_examples__strong_but_with_two_asterisks__001: |
          **bold**
        03_02_01__first_gitlab_specific_section_with_examples__h2_which_contains_an_h3__example_in_an_h3__001: |
          Example in an H3
        04_01_00__second_gitlab_specific_section_with_examples__strong_but_with_html__001: |
          <strong>
          bold
          </strong>
        05_01_00__third_gitlab_specific_section_with_skipped_examples__strong_but_skipped__001: |
          **this example will be skipped**
        05_02_00__third_gitlab_specific_section_with_skipped_examples__strong_but_manually_modified_and_skipped__001: |
          **This example will have its manually modified static HTML, WYSIWYG HTML, and ProseMirror JSON preserved**
        06_01_00__api_request_overrides__group_upload_link__001: |
          [groups-test-file](/uploads/groups-test-file)
        06_02_00__api_request_overrides__project_repo_link__001: |
          [projects-test-file](projects-test-file)
        06_03_00__api_request_overrides__project_snippet_ref__001: |
          This project snippet ID reference IS filtered: $88888
        06_04_00__api_request_overrides__personal_snippet_ref__001: |
          This personal snippet ID reference is NOT filtered: $99999
        06_05_00__api_request_overrides__project_wiki_link__001: |
          [project-wikis-test-file](project-wikis-test-file)
      YAML
    end

    it 'writes the correct content' do
      subject.process(skip_static_and_wysiwyg: true)

      expect(es_markdown_yml_contents).to eq(expected_markdown_yml_contents)
    end
  end

  describe 'error handling when manually-curated input specification config files contain invalid example names:' do
    let(:err_msg) do
      /#{config_file}.*01_00_00__invalid__001.*does not have.*entry in.*#{described_class::ES_EXAMPLES_INDEX_YML_PATH}/m
    end

    let(:invalid_example_name_file_contents) do
      <<~YAML
        ---
        01_00_00__invalid__001:
          a: 1
      YAML
    end

    context 'for glfm_example_status.yml' do
      let(:config_file) { described_class::GLFM_EXAMPLE_STATUS_YML_PATH }
      let(:glfm_example_status_yml_contents) { invalid_example_name_file_contents }

      it 'raises error' do
        expect { subject.process(skip_static_and_wysiwyg: true) }.to raise_error(err_msg)
      end
    end

    context 'for glfm_example_metadata.yml' do
      let(:config_file) { described_class::GLFM_EXAMPLE_METADATA_YML_PATH }
      let(:glfm_example_metadata_yml_contents) { invalid_example_name_file_contents }

      it 'raises error' do
        expect { subject.process(skip_static_and_wysiwyg: true) }.to raise_error(err_msg)
      end
    end

    context 'for glfm_example_normalizations.yml' do
      let(:config_file) { described_class::GLFM_EXAMPLE_NORMALIZATIONS_YML_PATH }
      let(:glfm_example_normalizations_yml_contents) { invalid_example_name_file_contents }

      it 'raises error' do
        expect { subject.process(skip_static_and_wysiwyg: true) }.to raise_error(err_msg)
      end
    end
  end

  context 'with full processing of static and WYSIWYG HTML' do
    before(:all) do
      # NOTE: It is a necessary to do a `yarn install` in order to ensure that
      #   `scripts/lib/glfm/render_wysiwyg_html_and_json.js` can be invoked successfully
      #   on the CI job (which will not be set up for frontend specs since this is
      #   an RSpec spec), or if the current yarn dependencies are not installed locally.
      described_class.new.run_external_cmd('yarn install --frozen-lockfile')
    end

    describe 'manually-curated input specification config files' do
      let(:glfm_example_status_yml_contents) { '' }
      let(:glfm_example_metadata_yml_contents) { '' }
      let(:glfm_example_normalizations_yml_contents) { '' }

      it 'can be empty' do
        expect { subject.process }.not_to raise_error
      end
    end

    describe 'writing html.yml and prosemirror_json.yml' do
      let(:es_html_yml_contents) { reread_io(es_html_yml_io) }
      let(:es_prosemirror_json_yml_contents) { reread_io(es_prosemirror_json_yml_io) }

      # NOTE: This example_status.yml is crafted in conjunction with expected_html_yml_contents
      # to test the behavior of the `skip_update_*` flags
      let(:glfm_example_status_yml_contents) do
        <<~YAML
          ---
          02_01_00__inlines__strong__002:
            # NOTE: 02_01_00__inlines__strong__002: is omitted from the existing prosemirror_json.yml file, and is also
            # skipped here, to show that an example does not need to exist in order to be skipped.
            # TODO: This should be changed to raise an error instead, to enforce that there cannot be orphaned
            #       entries in glfm_example_status.yml. This task is captured in
            #       https://gitlab.com/gitlab-org/gitlab/-/issues/361241#other-cleanup-tasks
            skip_update_example_snapshot_prosemirror_json: "skipping because JSON isn't cool enough"
          03_01_00__first_gitlab_specific_section_with_examples__strong_but_with_two_asterisks__001:
            skip_update_example_snapshot_html_static: "skipping because there's too much static"
          04_01_00__second_gitlab_specific_section_with_examples__strong_but_with_html__001:
            skip_update_example_snapshot_html_wysiwyg: 'skipping because what you see is NOT what you get'
            skip_update_example_snapshot_prosemirror_json: "skipping because JSON still isn't cool enough"
          05_01_00__third_gitlab_specific_section_with_skipped_examples__strong_but_skipped__001:
            skip_update_example_snapshots: 'skipping this example because it is very bad'
          05_02_00__third_gitlab_specific_section_with_skipped_examples__strong_but_manually_modified_and_skipped__001:
            skip_update_example_snapshots: 'skipping this example because we have manually modified it'
        YAML
      end

      let(:expected_html_yml_contents) do
        <<~YAML
          ---
          02_01_00__inlines__strong__001:
            canonical: |
              <p><strong>bold</strong></p>
            static: |-
              <p data-sourcepos="1:1-1:8" dir="auto"><strong>bold</strong></p>
            wysiwyg: |-
              <p><strong>bold</strong></p>
          02_01_00__inlines__strong__002:
            canonical: |
              <p><strong>bold with more text</strong></p>
            static: |-
              <p data-sourcepos="1:1-1:23" dir="auto"><strong>bold with more text</strong></p>
            wysiwyg: |-
              <p><strong>bold with more text</strong></p>
          02_03_00__inlines__strikethrough_extension__001:
            canonical: |
              <p><del>Hi</del> Hello, world!</p>
            static: |-
              <p data-sourcepos="1:1-1:20" dir="auto"><del>Hi</del> Hello, world!</p>
            wysiwyg: |-
              <p><s>Hi</s> Hello, world!</p>
          03_01_00__first_gitlab_specific_section_with_examples__strong_but_with_two_asterisks__001:
            canonical: |
              <p><strong>bold</strong></p>
            wysiwyg: |-
              <p><strong>bold</strong></p>
          03_02_01__first_gitlab_specific_section_with_examples__h2_which_contains_an_h3__example_in_an_h3__001:
            canonical: |
              <p>Example in an H3</p>
            static: |-
              <p data-sourcepos="1:1-1:16" dir="auto">Example in an H3</p>
            wysiwyg: |-
              <p>Example in an H3</p>
          04_01_00__second_gitlab_specific_section_with_examples__strong_but_with_html__001:
            canonical: |
              <p><strong>
              bold
              </strong></p>
            static: |-
              <strong>
              bold
              </strong>
          05_02_00__third_gitlab_specific_section_with_skipped_examples__strong_but_manually_modified_and_skipped__001:
            canonical: |
              <p><strong>This example will have its manually modified static HTML, WYSIWYG HTML, and ProseMirror JSON preserved</strong></p>
            static: |-
              <p>This is the manually modified static HTML which will be preserved</p>
            wysiwyg: |-
              <p>This is the manually modified WYSIWYG HTML which will be preserved</p>
          06_01_00__api_request_overrides__group_upload_link__001:
            canonical: |
              <p><a href="groups-test-file">groups-test-file</a></p>
            static: |-
              <p data-sourcepos="1:1-1:45" dir="auto"><a href="/groups/glfm_group/-/uploads/groups-test-file" data-canonical-src="/uploads/groups-test-file" data-link="true" class="gfm">groups-test-file</a></p>
            wysiwyg: |-
              <p><a target="_blank" rel="noopener noreferrer nofollow" href="/uploads/groups-test-file">groups-test-file</a></p>
          06_02_00__api_request_overrides__project_repo_link__001:
            canonical: |
              <p><a href="projects-test-file">projects-test-file</a></p>
            static: |-
              <p data-sourcepos="1:1-1:40" dir="auto"><a href="/glfm_group/glfm_project/-/blob/master/projects-test-file" class="gfm">projects-test-file</a></p>
            wysiwyg: |-
              <p><a target="_blank" rel="noopener noreferrer nofollow" href="projects-test-file">projects-test-file</a></p>
          06_03_00__api_request_overrides__project_snippet_ref__001:
            canonical: |
              <p>This project snippet ID reference IS filtered: <a href="/glfm_group/glfm_project/-/snippets/88888">$88888</a>
            static: |-
              <p data-sourcepos="1:1-1:53" dir="auto">This project snippet ID reference IS filtered: <a href="/glfm_group/glfm_project/-/snippets/88888" data-reference-type="snippet" data-original="$88888" data-link="false" data-link-reference="false" data-project="77777" data-snippet="88888" data-container="body" data-placement="top" title="glfm_project_snippet" class="gfm gfm-snippet has-tooltip">$88888</a></p>
            wysiwyg: |-
              <p>This project snippet ID reference IS filtered: $88888</p>
          06_04_00__api_request_overrides__personal_snippet_ref__001:
            canonical: |
              <p>This personal snippet ID reference is NOT filtered: $99999</p>
            static: |-
              <p data-sourcepos="1:1-1:58" dir="auto">This personal snippet ID reference is NOT filtered: $99999</p>
            wysiwyg: |-
              <p>This personal snippet ID reference is NOT filtered: $99999</p>
          06_05_00__api_request_overrides__project_wiki_link__001:
            canonical: |
              <p><a href="project-wikis-test-file">project-wikis-test-file</a></p>
            static: |-
              <p data-sourcepos="1:1-1:50" dir="auto"><a href="/glfm_group/glfm_project/-/wikis/project-wikis-test-file" data-canonical-src="project-wikis-test-file">project-wikis-test-file</a></p>
            wysiwyg: |-
              <p><a target="_blank" rel="noopener noreferrer nofollow" href="project-wikis-test-file">project-wikis-test-file</a></p>
        YAML
      end

      let(:expected_prosemirror_json_contents) do
        <<~YAML
          ---
          02_01_00__inlines__strong__001: |-
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
          02_03_00__inlines__strikethrough_extension__001: |-
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
          03_01_00__first_gitlab_specific_section_with_examples__strong_but_with_two_asterisks__001: |-
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
          03_02_01__first_gitlab_specific_section_with_examples__h2_which_contains_an_h3__example_in_an_h3__001: |-
            {
              "type": "doc",
              "content": [
                {
                  "type": "paragraph",
                  "content": [
                    {
                      "type": "text",
                      "text": "Example in an H3"
                    }
                  ]
                }
              ]
            }
          04_01_00__second_gitlab_specific_section_with_examples__strong_but_with_html__001: |-
            {
              "existing": "This entry is manually modified and preserved because skip_update_example_snapshot_prosemirror_json will be truthy"
            }
          05_02_00__third_gitlab_specific_section_with_skipped_examples__strong_but_manually_modified_and_skipped__001: |-
            {
              "existing": "This entry is manually modified and preserved because skip_update_example_snapshots will be truthy"
            }
          06_01_00__api_request_overrides__group_upload_link__001: |-
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
                          "type": "link",
                          "attrs": {
                            "href": "/uploads/groups-test-file",
                            "target": "_blank",
                            "class": null,
                            "uploading": false,
                            "title": null,
                            "canonicalSrc": "/uploads/groups-test-file",
                            "isReference": false
                          }
                        }
                      ],
                      "text": "groups-test-file"
                    }
                  ]
                }
              ]
            }
          06_02_00__api_request_overrides__project_repo_link__001: |-
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
                          "type": "link",
                          "attrs": {
                            "href": "projects-test-file",
                            "target": "_blank",
                            "class": null,
                            "uploading": false,
                            "title": null,
                            "canonicalSrc": "projects-test-file",
                            "isReference": false
                          }
                        }
                      ],
                      "text": "projects-test-file"
                    }
                  ]
                }
              ]
            }
          06_03_00__api_request_overrides__project_snippet_ref__001: |-
            {
              "type": "doc",
              "content": [
                {
                  "type": "paragraph",
                  "content": [
                    {
                      "type": "text",
                      "text": "This project snippet ID reference IS filtered: $88888"
                    }
                  ]
                }
              ]
            }
          06_04_00__api_request_overrides__personal_snippet_ref__001: |-
            {
              "type": "doc",
              "content": [
                {
                  "type": "paragraph",
                  "content": [
                    {
                      "type": "text",
                      "text": "This personal snippet ID reference is NOT filtered: $99999"
                    }
                  ]
                }
              ]
            }
          06_05_00__api_request_overrides__project_wiki_link__001: |-
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
                          "type": "link",
                          "attrs": {
                            "href": "project-wikis-test-file",
                            "target": "_blank",
                            "class": null,
                            "uploading": false,
                            "title": null,
                            "canonicalSrc": "project-wikis-test-file",
                            "isReference": false
                          }
                        }
                      ],
                      "text": "project-wikis-test-file"
                    }
                  ]
                }
              ]
            }
        YAML
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
  end
  # rubocop:enable RSpec/MultipleMemoizedHelpers

  def reread_io(io)
    # Reset the io StringIO to the beginning position of the buffer
    io.seek(0)
    io.read
  end
end
