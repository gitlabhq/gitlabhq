require 'rails_helper'

describe Banzai::Filter::YamlFrontMatterFilter do
  include FilterSpecHelper

  it 'allows for `encoding:` before the frontmatter' do
    content = <<-MD.strip_heredoc
      # encoding: UTF-8
      ---
      foo: foo
      ---

      # Header

      Content
    MD

    output = filter(content)

    expect(output).not_to match 'encoding'
  end

  it 'converts YAML frontmatter to a fenced code block' do
    content = <<-MD.strip_heredoc
      ---
      bar: :bar_symbol
      ---

      # Header

      Content
    MD

    output = filter(content)

    aggregate_failures do
      expect(output).not_to include '---'
      expect(output).to include "```yaml\nbar: :bar_symbol\n```"
    end
  end

  context 'on content without frontmatter' do
    it 'returns the content unmodified' do
      content = <<-MD.strip_heredoc
        # This is some Markdown

        It has no YAML frontmatter to parse.
      MD

      expect(filter(content)).to eq content
    end
  end
end
