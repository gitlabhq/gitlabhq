# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Banzai::Filter::FrontMatterFilter, feature_category: :markdown do
  include FilterSpecHelper

  it 'allows for `encoding:` before the front matter' do
    content = <<~MD
      # encoding: UTF-8
      ---
      foo: foo
      bar: bar
      ---

      # Header

      Content
    MD

    output = filter(content)

    expect(output).not_to match 'encoding'
  end

  it 'converts YAML front matter to a fenced code block' do
    content = <<~MD
      ---
      foo: :foo_symbol
      bar: :bar_symbol
      ---

      # Header

      Content
    MD

    output = filter(content)

    aggregate_failures do
      expect(output).not_to include '---'
      expect(output).to include "```yaml:frontmatter\nfoo: :foo_symbol\n"
    end
  end

  it 'converts TOML frontmatter to a fenced code block' do
    content = <<~MD
      +++
      foo = :foo_symbol
      bar = :bar_symbol
      +++

      # Header

      Content
    MD

    output = filter(content)

    aggregate_failures do
      expect(output).not_to include '+++'
      expect(output).to include "```toml:frontmatter\nfoo = :foo_symbol\n"
    end
  end

  it 'converts JSON front matter to a fenced code block' do
    content = <<~MD
      ;;;
      {
        "foo": ":foo_symbol",
        "bar": ":bar_symbol"
      }
      ;;;

      # Header

      Content
    MD

    output = filter(content)

    aggregate_failures do
      expect(output).not_to include ';;;'
      expect(output).to include "```json:frontmatter\n{\n  \"foo\": \":foo_symbol\",\n"
    end
  end

  it 'converts arbitrary front matter to a fenced code block' do
    content = <<~MD
      ---arbitrary
      foo = :foo_symbol
      bar = :bar_symbol
      ---

      # Header

      Content
    MD

    output = filter(content)

    aggregate_failures do
      expect(output).not_to include '---arbitrary'
      expect(output).to include "```arbitrary:frontmatter\nfoo = :foo_symbol\n"
    end
  end

  context 'source position mapping' do
    it 'keeps spaces before and after' do
      content = <<~MD


        ---

        foo: :foo_symbol

        ---


        # Header
      MD

      output = filter(content)

      expect(output).to eq <<~MD


        ```yaml:frontmatter

        foo: :foo_symbol

        ```


        # Header
      MD
    end

    it 'keeps an empty line in place of the encoding' do
      content = <<~MD
        # encoding: UTF-8
        ---
        foo: :foo_symbol
        ---
      MD

      output = filter(content)

      expect(output).to eq <<~MD

        ```yaml:frontmatter
        foo: :foo_symbol
        ```
      MD
    end
  end

  context 'on content without front matter' do
    it 'returns the content unmodified' do
      content = <<~MD
        # This is some Markdown

        It has no YAML front matter to parse.
      MD

      expect(filter(content)).to eq content
    end
  end

  context 'on front matter without content' do
    it 'converts YAML front matter to a fenced code block' do
      content = <<~MD.rstrip
        ---
        foo: :foo_symbol
        bar: :bar_symbol
        ---
      MD

      output = filter(content)

      aggregate_failures do
        expect(output).to eq <<~MD
          ```yaml:frontmatter
          foo: :foo_symbol
          bar: :bar_symbol
          ```
        MD
      end
    end
  end

  describe 'protects against malicious backtracking' do
    it 'fails fast for strings with many spaces' do
      content = "coding:" + (" " * 50_000) + ";"

      expect do
        Timeout.timeout(BANZAI_FILTER_TIMEOUT_MAX) { filter(content) }
      end.not_to raise_error
    end

    it 'fails fast for strings with many newlines' do
      content = "coding:\n" + ";;;" + ("\n" * 10_000) + "x"

      expect do
        Timeout.timeout(BANZAI_FILTER_TIMEOUT_MAX) { filter(content) }
      end.not_to raise_error
    end

    it 'fails fast for strings with many `coding:`' do
      content = ("coding:" * 120_000) + ("\n" * 80_000) + ";"

      expect do
        Timeout.timeout(BANZAI_FILTER_TIMEOUT_MAX) { filter(content) }
      end.not_to raise_error
    end
  end

  it_behaves_like 'pipeline timing check'

  it_behaves_like 'limits the number of filtered items' do
    let(:text) do
      <<~MD
        ---
        foo: :foo_symbol
        ---

        ---
        bar: :bar_symbol
        ---

        ---
        fubar: :fubar_symbol
        ---
      MD
    end

    let(:ends_with) { "```\n\n---\nfubar: :fubar_symbol\n---\n" }
  end
end
