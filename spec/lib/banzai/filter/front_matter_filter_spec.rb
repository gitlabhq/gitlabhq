# frozen_string_literal: true

require 'spec_helper'

describe Banzai::Filter::FrontMatterFilter do
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
      expect(output).to include "```yaml\nfoo: :foo_symbol\n"
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
      expect(output).to include "```toml\nfoo = :foo_symbol\n"
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
      expect(output).to include "```json\n{\n  \"foo\": \":foo_symbol\",\n"
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
      expect(output).to include "```arbitrary\nfoo = :foo_symbol\n"
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
      content = <<~MD
        ---
        foo: :foo_symbol
        bar: :bar_symbol
        ---
      MD

      output = filter(content)

      aggregate_failures do
        expect(output).to eq <<~MD
          ```yaml
          foo: :foo_symbol
          bar: :bar_symbol
          ```

        MD
      end
    end
  end
end
