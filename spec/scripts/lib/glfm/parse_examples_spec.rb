# frozen_string_literal: true
require 'fast_spec_helper'
require_relative '../../../../scripts/lib/glfm/parse_examples'

RSpec.describe Glfm::ParseExamples, '#parse_examples' do
  subject do
    described_module = described_class
    Class.new { include described_module }.new
  end

  let(:spec_txt_contents) do
    <<~MARKDOWN
      ---
      title: Spec
      ...

      # Introduction

      intro

      # 1.0.0 H1

      ## 1.1.0 H2

      no extension

      ```````````````````````````````` example
      example 1 md
      .
      html
      ````````````````````````````````

      one extension

      ```````````````````````````````` example extension_1.1.0-1
      example 2 md
      .
      html
      ````````````````````````````````

      ### 1.1.1 H3 with no examples

      text

      ### 1.1.2 Consecutive H3 with example

      text

      ```````````````````````````````` example disabled
      example 3 md
      .
      html
      ````````````````````````````````

      ## 1.2.0 H2 with all disabled examples


      ```````````````````````````````` example disabled
      example 4 md
      .
      html
      ````````````````````````````````

      ## 1.2.0 New H2


      ```````````````````````````````` example extension_1.2.0-1
      example 5 md
      .
      html
      ````````````````````````````````

      # 2.0.0 New H1

      ## 2.1.0 H2

      ```````````````````````````````` example gitlab
      example 6 md
      .
      html
      ````````````````````````````````

      ## 2.2.0 H2 which contains an H3

      No example here, just text

      ### 2.2.1 H3

      The CommonMark and GHFM specifications don't have any examples inside an H3, but it is
      supported for the GLFM specification.

      ```````````````````````````````` example extension_2.2.1-1
      example 7 md
      .
      html
      ````````````````````````````````

      # 3.0.0 New H1

      ## 3.1.0 H2

      ```````````````````````````````` example
      example 8 md
      .
      html
      ````````````````````````````````

      ### 3.1.1 H3

      ```````````````````````````````` example
      example 9 md
      .
      html
      ````````````````````````````````

      ### 3.1.1 Consecutive H3

      ```````````````````````````````` example
      example 10 md
      .
      html
      ````````````````````````````````

      ## 3.2.0 Another H2

      ```````````````````````````````` example
      example 11 md
      .
      html
      ````````````````````````````````

      <!-- END TESTS -->

      # Appendix

      Appendix text.
    MARKDOWN
  end

  let(:spec_txt_lines) { spec_txt_contents.split("\n") }

  describe "parsing" do
    it 'correctly parses' do
      examples = subject.parse_examples(spec_txt_lines)

      expected =
        [
          {
            disabled: false,
            end_line: 19,
            example: 1,
            extensions: [],
            headers: [
              '1.0.0 H1',
              '1.1.0 H2'
            ],
            html: 'html',
            markdown: 'example 1 md',
            section: '1.1.0 H2',
            start_line: 15
          },
          {
            disabled: false,
            end_line: 27,
            example: 2,
            extensions: %w[extension_1.1.0-1],
            headers: [
              '1.0.0 H1',
              '1.1.0 H2'
            ],
            html: 'html',
            markdown: 'example 2 md',
            section: '1.1.0 H2',
            start_line: 23
          },
          {
            disabled: true,
            end_line: 41,
            example: 3,
            extensions: %w[disabled],
            headers: [
              '1.0.0 H1',
              '1.1.0 H2',
              '1.1.2 Consecutive H3 with example'
            ],
            html: 'html',
            markdown: 'example 3 md',
            section: '1.1.2 Consecutive H3 with example',
            start_line: 37
          },
          {
            disabled: true,
            end_line: 50,
            example: 4,
            extensions: %w[disabled],
            headers: [
              '1.0.0 H1',
              '1.2.0 H2 with all disabled examples'
            ],
            html: 'html',
            markdown: 'example 4 md',
            section: '1.2.0 H2 with all disabled examples',
            start_line: 46
          },
          {
            disabled: false,
            end_line: 59,
            example: 5,
            extensions: %w[extension_1.2.0-1],
            headers: [
              '1.0.0 H1',
              '1.2.0 New H2'
            ],
            html: 'html',
            markdown: 'example 5 md',
            section: '1.2.0 New H2',
            start_line: 55
          },
          {
            disabled: false,
            end_line: 69,
            example: 6,
            extensions: %w[gitlab],
            headers: [
              '2.0.0 New H1',
              '2.1.0 H2'
            ],
            html: 'html',
            markdown: 'example 6 md',
            section: '2.1.0 H2',
            start_line: 65
          },
          {
            disabled: false,
            end_line: 84,
            example: 7,
            extensions: %w[extension_2.2.1-1],
            headers: [
              '2.0.0 New H1',
              '2.2.0 H2 which contains an H3',
              '2.2.1 H3'
            ],
            html: 'html',
            markdown: 'example 7 md',
            section: '2.2.1 H3',
            start_line: 80
          },
          {
            disabled: false,
            end_line: 94,
            example: 8,
            extensions: [],
            headers: [
              '3.0.0 New H1',
              '3.1.0 H2'
            ],
            html: 'html',
            markdown: 'example 8 md',
            section: '3.1.0 H2',
            start_line: 90
          },
          {
            disabled: false,
            end_line: 102,
            example: 9,
            extensions: [],
            headers: [
              '3.0.0 New H1',
              '3.1.0 H2',
              '3.1.1 H3'
            ],
            html: 'html',
            markdown: 'example 9 md',
            section: '3.1.1 H3',
            start_line: 98
          },
          {
            disabled: false,
            end_line: 110,
            example: 10,
            extensions: [],
            headers: [
              '3.0.0 New H1',
              '3.1.0 H2',
              '3.1.1 Consecutive H3'
            ],
            html: 'html',
            markdown: 'example 10 md',
            section: '3.1.1 Consecutive H3',
            start_line: 106
          },
          {
            disabled: false,
            end_line: 118,
            example: 11,
            extensions: [],
            headers: [
              '3.0.0 New H1',
              '3.2.0 Another H2'
            ],
            html: 'html',
            markdown: 'example 11 md',
            section: '3.2.0 Another H2',
            start_line: 114
          }
        ]

      expect(examples).to eq(expected)
    end
  end

  describe "with incorrect header nesting" do
    let(:spec_txt_contents) do
      <<~MARKDOWN
        ---
        title: Spec
        ...

        # H1

        ### H3

      MARKDOWN
    end

    it "raises if H3 is nested directly in H1" do
      expect { subject.parse_examples(spec_txt_lines) }
        .to raise_error(/The H3 'H3' may not be nested directly within the H1 'H1'/)
    end
  end
end
