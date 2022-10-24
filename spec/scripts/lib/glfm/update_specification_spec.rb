# frozen_string_literal: true

require 'fast_spec_helper'
require_relative '../../../../scripts/lib/glfm/update_specification'
require_relative '../../../support/helpers/next_instance_of'

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
RSpec.describe Glfm::UpdateSpecification, '#process' do
  include NextInstanceOf

  subject { described_class.new }

  let(:ghfm_spec_txt_uri) { described_class::GHFM_SPEC_TXT_URI }
  let(:ghfm_spec_txt_uri_parsed) { instance_double(URI::HTTPS, :ghfm_spec_txt_uri_parsed) }
  let(:ghfm_spec_txt_uri_io) { StringIO.new(ghfm_spec_txt_contents) }
  let(:ghfm_spec_md_path) { described_class::GHFM_SPEC_MD_PATH }
  let(:ghfm_spec_txt_local_io) { StringIO.new(ghfm_spec_txt_contents) }

  let(:glfm_intro_md_path) { described_class::GLFM_INTRO_MD_PATH }
  let(:glfm_intro_md_io) { StringIO.new(glfm_intro_md_contents) }
  let(:glfm_official_specification_examples_md_path) { described_class::GLFM_OFFICIAL_SPECIFICATION_EXAMPLES_MD_PATH }
  let(:glfm_official_specification_examples_md_io) { StringIO.new(glfm_official_specification_examples_md_contents) }
  let(:glfm_internal_extension_examples_md_path) { described_class::GLFM_INTERNAL_EXTENSION_EXAMPLES_MD_PATH }
  let(:glfm_internal_extension_examples_md_io) { StringIO.new(glfm_internal_extension_examples_md_contents) }
  let(:glfm_spec_txt_path) { described_class::GLFM_SPEC_TXT_PATH }
  let(:glfm_spec_txt_io) { StringIO.new }
  let(:glfm_spec_html_path) { described_class::GLFM_SPEC_HTML_PATH }
  let(:glfm_spec_html_io) { StringIO.new }
  let(:markdown_tempfile_io) { StringIO.new }

  let(:ghfm_spec_txt_contents) do
    <<~MARKDOWN
      ---
      title: GitHub Flavored Markdown Spec
      version: 0.29
      date: '2019-04-06'
      license: '[CC-BY-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0/)'
      ...

      # Introduction

      ## What is GitHub Flavored Markdown?

      It's like GLFM, but with an H.

      # Section with Examples

      ## Strong

      ```````````````````````````````` example
      __bold__
      .
      <p><strong>bold</strong></p>
      ````````````````````````````````

      End of last GitHub examples section.

      <!-- END TESTS -->

      # Appendix

      Appendix text.
    MARKDOWN
  end

  let(:glfm_intro_md_contents) do
    # language=Markdown
    <<~MARKDOWN
      # Introduction

      ## What is GitLab Flavored Markdown?

      Intro text about GitLab Flavored Markdown.
    MARKDOWN
  end

  let(:glfm_official_specification_examples_md_contents) do
    <<~MARKDOWN
      # Official Specification Section with Examples

      Some examples.
    MARKDOWN
  end

  let(:glfm_internal_extension_examples_md_contents) do
    <<~MARKDOWN
      # Internal Extension Section with Examples

      Some examples.
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
    allow(File).to receive(:open).with(glfm_intro_md_path) { glfm_intro_md_io }
    allow(File).to receive(:open).with(glfm_official_specification_examples_md_path) do
      glfm_official_specification_examples_md_io
    end
    allow(File).to receive(:open).with(glfm_internal_extension_examples_md_path) do
      glfm_internal_extension_examples_md_io
    end

    # output files
    allow(File).to receive(:open).with(glfm_spec_txt_path, 'w') { glfm_spec_txt_io }
    allow(File).to receive(:open).with(glfm_spec_html_path, 'w') { glfm_spec_html_io }

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

  describe 'writing GLFM spec.txt' do
    let(:glfm_contents) { reread_io(glfm_spec_txt_io) }

    before do
      subject.process(skip_spec_html_generation: true)
    end

    it 'replaces the header text with the GitLab version' do
      expect(glfm_contents).not_to match(/GitHub Flavored Markdown Spec/m)
      expect(glfm_contents).not_to match(/^version: \d\.\d/m)
      expect(glfm_contents).not_to match(/^date: /m)
      expect(glfm_contents).not_to match(/^license: /m)
      expect(glfm_contents).to match(/#{Regexp.escape(described_class::GLFM_SPEC_TXT_HEADER)}\n/mo)
    end

    it 'replaces the intro section with the GitLab version' do
      expect(glfm_contents).not_to match(/What is GitHub Flavored Markdown/m)
      expect(glfm_contents).to match(/#{Regexp.escape(glfm_intro_md_contents)}/m)
    end

    it 'inserts the GitLab official spec and internal extension examples sections before the appendix section' do
      expected = <<~MARKDOWN
        End of last GitHub examples section.

        # Official Specification Section with Examples

        Some examples.

        # Internal Extension Section with Examples

        Some examples.

        <!-- END TESTS -->

        # Appendix
      MARKDOWN
      expect(glfm_contents).to match(/#{Regexp.escape(expected)}/m)
    end
  end

  describe 'writing GLFM spec.html' do
    let(:glfm_contents) { reread_io(glfm_spec_html_io) }

    before do
      subject.process
    end

    it 'renders HTML from spec.txt', :unlimited_max_formatted_output_length do
      expected = <<~HTML
        <div class="gl-relative markdown-code-block js-markdown-code">
        <pre data-sourcepos="1:1-4:3" class="code highlight js-syntax-highlight language-yaml" lang="yaml" data-lang-params="frontmatter" v-pre="true"><code><span id="LC1" class="line" lang="yaml"><span class="na">title</span><span class="pi">:</span> <span class="s">GitLab Flavored Markdown (GLFM) Spec</span></span>
        <span id="LC2" class="line" lang="yaml"><span class="na">version</span><span class="pi">:</span> <span class="s">alpha</span></span></code></pre>
        <copy-code></copy-code>
        </div>
        <h1 data-sourcepos="6:1-6:14" dir="auto">
        <a id="user-content-introduction" class="anchor" href="#introduction" aria-hidden="true"></a>Introduction</h1>
        <h2 data-sourcepos="8:1-8:36" dir="auto">
        <a id="user-content-what-is-gitlab-flavored-markdown" class="anchor" href="#what-is-gitlab-flavored-markdown" aria-hidden="true"></a>What is GitLab Flavored Markdown?</h2>
        <p data-sourcepos="10:1-10:42" dir="auto">Intro text about GitLab Flavored Markdown.</p>
        <h1 data-sourcepos="12:1-12:23" dir="auto">
        <a id="user-content-section-with-examples" class="anchor" href="#section-with-examples" aria-hidden="true"></a>Section with Examples</h1>
        <h2 data-sourcepos="14:1-14:9" dir="auto">
        <a id="user-content-strong" class="anchor" href="#strong" aria-hidden="true"></a>Strong</h2>
        <div class="gl-relative markdown-code-block js-markdown-code">
        <pre data-sourcepos="16:1-20:32" class="code highlight js-syntax-highlight language-plaintext" lang="plaintext" data-canonical-lang="example" v-pre="true"><code><span id="LC1" class="line" lang="plaintext">__bold__</span>
        <span id="LC2" class="line" lang="plaintext">.</span>
        <span id="LC3" class="line" lang="plaintext">&lt;p&gt;&lt;strong&gt;bold&lt;/strong&gt;&lt;/p&gt;</span></code></pre>
        <copy-code></copy-code>
        </div>
        <p data-sourcepos="22:1-22:36" dir="auto">End of last GitHub examples section.</p>
        <h1 data-sourcepos="24:1-24:46" dir="auto">
        <a id="user-content-official-specification-section-with-examples" class="anchor" href="#official-specification-section-with-examples" aria-hidden="true"></a>Official Specification Section with Examples</h1>
        <p data-sourcepos="26:1-26:14" dir="auto">Some examples.</p>
        <h1 data-sourcepos="28:1-28:42" dir="auto">
        <a id="user-content-internal-extension-section-with-examples" class="anchor" href="#internal-extension-section-with-examples" aria-hidden="true"></a>Internal Extension Section with Examples</h1>
        <p data-sourcepos="30:1-30:14" dir="auto">Some examples.</p>

        <h1 data-sourcepos="34:1-34:10" dir="auto">
        <a id="user-content-appendix" class="anchor" href="#appendix" aria-hidden="true"></a>Appendix</h1>
        <p data-sourcepos="36:1-36:14" dir="auto">Appendix text.</p>
      HTML
      expect(glfm_contents).to be == expected
    end
  end

  def reread_io(io)
    # Reset the io StringIO to the beginning position of the buffer
    io.seek(0)
    io.read
  end
end
