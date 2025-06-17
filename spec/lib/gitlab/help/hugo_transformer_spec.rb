# frozen_string_literal: true

require 'spec_helper'

# rubocop:disable RSpec/FeatureCategory -- Help pages are not part of a feature category. This feature is supported by the Technical Writing team.
RSpec.describe Gitlab::Help::HugoTransformer do
  # rubocop:enable RSpec/FeatureCategory
  describe '#transform' do
    let(:transformer) { described_class.new }

    context 'when content contains Hugo shortcodes' do
      it 'converts disclaimer alert shortcodes to the standard disclaimer text' do
        content = <<~MARKDOWN
          # Documentation

          {{< alert type="disclaimer" />}}

          Regular content
        MARKDOWN

        expected_content = <<~MARKDOWN
          # Documentation

          #{described_class::DISCLAIMER_TEXT}

          Regular content
        MARKDOWN

        expect(transformer.transform(content).strip).to eq(expected_content.strip)
      end

      it 'handles history shortcodes with correct heading levels' do
        content = <<~MARKDOWN
          # Main heading

          Some content here.

          ## Secondary heading

          More content here.

          {{< history >}}

          - Introduced in xyz
          - Deprecated in abc

          {{< /history >}}

          ### Another heading

          {{< history >}}

          - Another history item

          {{< /history >}}
        MARKDOWN

        expected_content = <<~MARKDOWN
          # Main heading

          Some content here.

          ## Secondary heading

          More content here.

          ### Version history

          - Introduced in xyz
          - Deprecated in abc

          ### Another heading

          #### Version history

          - Another history item
        MARKDOWN

        expect(transformer.transform(content).strip).to eq(expected_content.strip)
      end

      it 'handles tabs shortcodes with correct heading levels' do
        content = <<~MARKDOWN
          # Main heading

          ## Secondary heading

          Some content here.

          {{< tabs >}}

          {{< tab title="Tab one" >}}

          This is content in the first tab.

          - This is a list
          - It's inside a tab

          {{< /tab >}}

          {{< tab title="Tab two" >}}

          This tab has one paragraph, and some code.

          ```php
          y=mx+b
          ```

          {{< /tab >}}

          {{< /tabs >}}

          ### Another heading
        MARKDOWN

        expected_content = <<~MARKDOWN
          # Main heading

          ## Secondary heading

          Some content here.

          ### Tab one

          This is content in the first tab.

          - This is a list
          - It's inside a tab

          ### Tab two

          This tab has one paragraph, and some code.

          ```php
          y=mx+b
          ```

          ### Another heading
        MARKDOWN

        expect(transformer.transform(content).strip).to eq(expected_content.strip)
      end

      it 'removes shortcode tags while preserving content' do
        content = <<~MARKDOWN
          # Documentation

          {{< alert type="note" >}}

          Some note content

          {{< /alert >}}

          Regular content

          {{< details >}}

          - Tier: some tiers
          - Offering: some offerings
          - Status: Experiment

          {{< /details >}}
        MARKDOWN

        expected_content = <<~MARKDOWN
          # Documentation

          Some note content

          Regular content

          - Tier: some tiers
          - Offering: some offerings
          - Status: Experiment
        MARKDOWN

        expect(transformer.transform(content).strip).to eq(expected_content.strip)
      end

      it 'replaces icon shortcodes with text placeholders' do
        content = <<~MARKDOWN
          # Documentation

          Here is a tanuki icon: {{< icon name="tanuki" >}}

          And another icon: {{< icon name="pipeline" >}}
        MARKDOWN

        expected_content = <<~MARKDOWN
          # Documentation

          Here is a tanuki icon: **{tanuki}**

          And another icon: **{pipeline}**
        MARKDOWN

        expect(transformer.transform(content).strip).to eq(expected_content.strip)
      end

      it 'leaves shortcode syntax unchanged within code block sections' do
        content = <<~MARKDOWN
          # Documentation

          Here's a regular shortcode:
          {{< icon name="tanuki" >}}

          Here's how to use shortcodes:

          ```markdown
          Use icons like this:
          {{< icon name="tanuki" >}}

          Or alerts:
          {{< alert type="note" >}}
          This is a note
          {{< /alert >}}
          ```

          And here's another regular shortcode:
          {{< icon name="pipeline" >}}

          ```
          {{< tabs >}}
          {{< tab title="Tab one" >}}
          Content
          {{< /tab >}}
          {{< /tabs >}}
          ```

          This codeblock has four backticks:

          ````markdown
          # Hello world
          {{< icon name="tanuki" >}}
          ````
        MARKDOWN

        expected_content = <<~MARKDOWN
          # Documentation

          Here's a regular shortcode:
          **{tanuki}**

          Here's how to use shortcodes:

          ```markdown
          Use icons like this:
          {{< icon name="tanuki" >}}

          Or alerts:
          {{< alert type="note" >}}
          This is a note
          {{< /alert >}}
          ```

          And here's another regular shortcode:
          **{pipeline}**

          ```
          {{< tabs >}}
          {{< tab title="Tab one" >}}
          Content
          {{< /tab >}}
          {{< /tabs >}}
          ```

          This codeblock has four backticks:

          ````markdown
          # Hello world
          {{< icon name="tanuki" >}}
          ````
        MARKDOWN

        expect(transformer.transform(content).strip).to eq(expected_content.strip)
      end

      it 'handles nested shortcodes' do
        content = <<~MARKDOWN
          # Documentation

          One paragraph.

          {{< tabs >}}

          {{< tab title="Tab with icon" >}}

          Here's an icon: **{tanuki}**

          {{< /tab >}}

          {{< tab title="Tab with alert" >}}

          {{< alert type="note" >}}

          This is a note

          {{< /alert >}}

          {{< /tab >}}

          {{< /tabs >}}
        MARKDOWN

        expected_content = <<~MARKDOWN
          # Documentation

          One paragraph.

          ## Tab with icon

          Here's an icon: **{tanuki}**

          ## Tab with alert

          This is a note
        MARKDOWN

        expect(transformer.transform(content).strip).to eq(expected_content.strip)
      end
    end

    it 'converts maintained-versions shortcodes to maintenance policy message' do
      content = <<~MARKDOWN
        # Documentation

        Current maintained versions:

        {{< maintained-versions >}}

        More content here.
      MARKDOWN

      expected_content = <<~MARKDOWN
        # Documentation

        Current maintained versions:

        https://docs.gitlab.com/policy/maintenance/#maintained-versions

        More content here.
      MARKDOWN

      expect(transformer.transform(content).strip).to eq(expected_content.strip)
    end

    it 'handles maintained-versions shortcode with self-closing syntax' do
      content = '{{< maintained-versions />}}'

      expected_content = 'https://docs.gitlab.com/policy/maintenance/#maintained-versions'

      expect(transformer.transform(content).strip).to eq(expected_content.strip)
    end

    describe '#find_next_heading_level' do
      it 'returns level 2 when no previous headings exist' do
        content = "Some content without headings"
        level = transformer.send(:find_next_heading_level, content, content.length)
        expect(level).to eq(2)
      end

      it 'returns one level deeper than the previous heading' do
        content = <<~MARKDOWN
          # Level 1

          Some content

          ## Level 2

          More content
        MARKDOWN

        level = transformer.send(:find_next_heading_level, content, content.length)
        expect(level).to eq(3)
      end

      it 'does not exceed level 6' do
        content = <<~MARKDOWN
          # Level 1

          ## Level 2

          ### Level 3

          #### Level 4

          ##### Level 5

          ###### Level 6

          Some content
        MARKDOWN

        level = transformer.send(:find_next_heading_level, content, content.length)
        expect(level).to eq(6)
      end

      it 'finds the correct level when multiple headings exist' do
        content = <<~MARKDOWN
          # Level 1

          ## Level 2

          # Back to Level 1

          Some content
        MARKDOWN

        level = transformer.send(:find_next_heading_level, content, content.length)
        expect(level).to eq(2)
      end
    end
  end

  describe '#hugo_anchor' do
    let(:transformer) { described_class.new }

    context 'with non-string input' do
      it 'returns without error' do
        expect(transformer.hugo_anchor(nil)).to eq('')
        expect(transformer.hugo_anchor(123)).to eq('123')
        expect(transformer.hugo_anchor(false)).to eq('false')
      end
    end

    context 'with string input not containing code blocks' do
      it 'handles title with spaces' do
        expect(transformer.hugo_anchor('Toggle notes confidentiality on APIs')).to \
          eq('toggle-notes-confidentiality-on-apis')
      end

      it 'handles title with special characters' do
        expect(transformer.hugo_anchor('Updating CI/CD job tokens to JWT standard')).to \
          eq('updating-cicd-job-tokens-to-jwt-standard')
      end
    end

    context 'with string input containing code blocks' do
      it 'handles single code block' do
        expect(transformer.hugo_anchor('The `ci_job_token_scope_enabled` projects API attribute is deprecated')).to \
          eq('the-ci_job_token_scope_enabled-projects-api-attribute-is-deprecated')
      end

      it 'handles multiple code blocks' do
        expect(transformer.hugo_anchor('Replace `add_on_purchase` GraphQL field with `add_on_purchases`')).to \
          eq('replace-add_on_purchase-graphql-field-with-add_on_purchases')
      end

      it 'handles code block with special characters' do
        expect(transformer.hugo_anchor('The `heroku/builder:22` image is deprecated')).to \
          eq('the-herokubuilder22-image-is-deprecated')
      end

      it 'handles empty code block' do
        expect(transformer.hugo_anchor('``')).to eq('')
      end
    end
  end
end
