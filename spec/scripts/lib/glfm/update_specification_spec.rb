# frozen_string_literal: true
require 'fast_spec_helper'
require_relative '../../../../scripts/lib/glfm/update_specification'

RSpec.describe Glfm::UpdateSpecification, '#process' do
  subject { described_class.new }

  let(:ghfm_spec_txt_uri) { described_class::GHFM_SPEC_TXT_URI }
  let(:ghfm_spec_txt_uri_io) { StringIO.new(ghfm_spec_txt_contents) }
  let(:ghfm_spec_txt_path) { described_class::GHFM_SPEC_TXT_PATH }
  let(:ghfm_spec_txt_local_io) { StringIO.new(ghfm_spec_txt_contents) }

  let(:glfm_intro_txt_path) { described_class::GLFM_INTRO_TXT_PATH }
  let(:glfm_intro_txt_io) { StringIO.new(glfm_intro_txt_contents) }
  let(:glfm_examples_txt_path) { described_class::GLFM_EXAMPLES_TXT_PATH }
  let(:glfm_examples_txt_io) { StringIO.new(glfm_examples_txt_contents) }
  let(:glfm_spec_txt_path) { described_class::GLFM_SPEC_TXT_PATH }
  let(:glfm_spec_txt_io) { StringIO.new }

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

  let(:glfm_intro_txt_contents) do
    # language=Markdown
    <<~MARKDOWN
      # Introduction

      ## What is GitLab Flavored Markdown?

      Intro text about GitLab Flavored Markdown.
    MARKDOWN
  end

  let(:glfm_examples_txt_contents) do
    <<~MARKDOWN
      # GitLab-Specific Section with Examples

      Some examples.
    MARKDOWN
  end

  before do
    # Mock default ENV var values
    allow(ENV).to receive(:[]).with('UPDATE_GHFM_SPEC_TXT').and_return(nil)
    allow(ENV).to receive(:[]).and_call_original

    # We mock out the URI and local file IO objects with real StringIO, instead of just mock
    # objects. This gives better and more realistic coverage, while still avoiding
    # actual network and filesystem I/O during the spec run.
    allow(URI).to receive(:open).with(ghfm_spec_txt_uri) { ghfm_spec_txt_uri_io }
    allow(File).to receive(:open).with(ghfm_spec_txt_path) { ghfm_spec_txt_local_io }
    allow(File).to receive(:open).with(glfm_intro_txt_path) { glfm_intro_txt_io }
    allow(File).to receive(:open).with(glfm_examples_txt_path) { glfm_examples_txt_io }
    allow(File).to receive(:open).with(glfm_spec_txt_path, 'w') { glfm_spec_txt_io }

    # Prevent console output when running tests
    allow(subject).to receive(:output)
  end

  describe 'retrieving latest GHFM spec.txt' do
    context 'when UPDATE_GHFM_SPEC_TXT is not true (default)' do
      it 'does not download' do
        expect(URI).not_to receive(:open).with(ghfm_spec_txt_uri)

        subject.process

        expect(reread_io(ghfm_spec_txt_local_io)).to eq(ghfm_spec_txt_contents)
      end
    end

    context 'when UPDATE_GHFM_SPEC_TXT is true' do
      let(:ghfm_spec_txt_local_io) { StringIO.new }

      before do
        allow(ENV).to receive(:[]).with('UPDATE_GHFM_SPEC_TXT').and_return('true')
        allow(File).to receive(:open).with(ghfm_spec_txt_path, 'w') { ghfm_spec_txt_local_io }
      end

      context 'with success' do
        it 'downloads and saves' do
          subject.process

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
            expect { subject.process }.to raise_error /version mismatch.*expected.*29.*got.*30/i
          end
        end

        context 'with a failed read of file lines' do
          let(:ghfm_spec_txt_contents) { '' }

          it 'raises an error if lines cannot be read' do
            expect { subject.process }.to raise_error /unable to read lines/i
          end
        end

        context 'with a failed re-read of file string' do
          before do
            allow(ghfm_spec_txt_uri_io).to receive(:read).and_return(nil)
          end

          it 'raises an error if file is blank' do
            expect { subject.process }.to raise_error /unable to read string/i
          end
        end
      end
    end
  end

  describe 'writing GLFM spec.txt' do
    let(:glfm_contents) { reread_io(glfm_spec_txt_io) }

    before do
      subject.process
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
      expect(glfm_contents).to match(/#{Regexp.escape(glfm_intro_txt_contents)}/m)
    end

    it 'inserts the GitLab examples sections before the appendix section' do
      expected = <<~MARKDOWN
        End of last GitHub examples section.

        # GitLab-Specific Section with Examples

        Some examples.

        <!-- END TESTS -->

        # Appendix
      MARKDOWN
      expect(glfm_contents).to match(/#{Regexp.escape(expected)}/m)
    end
  end

  def reread_io(io)
    # Reset the io StringIO to the beginning position of the buffer
    io.seek(0)
    io.read
  end
end
