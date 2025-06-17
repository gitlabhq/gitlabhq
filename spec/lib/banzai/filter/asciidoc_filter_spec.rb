# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Banzai::Filter::AsciidocFilter, feature_category: :wiki do
  include FakeBlobHelpers

  let(:project) { create(:project, :repository) }
  let(:context) { { project: project, current_user: project.first_owner } }

  describe '#call' do
    it 'converts AsciiDoc to HTML' do
      input = '= AsciiDoc Heading'
      filter = described_class.new(input, context)

      expect(filter.call).to include('<h1>AsciiDoc Heading</h1>')
    end

    it 'handles sections and anchors' do
      input = <<~ADOC
        = Title

        == First section

        This is the first section.

        == Second section

        This is the second section.
      ADOC

      filter = described_class.new(input, context)
      output = filter.call

      expect(output).to include('<h1>Title</h1>')
      expect(output).to include('<h2 id="user-content-first-section">')
      expect(output).to include('<h2 id="user-content-second-section">')
      expect(output).to include('<p>This is the first section.</p>')
      expect(output).to include('<p>This is the second section.</p>')
    end

    it 'handles code blocks' do
      input = <<~ADOC
        [source,ruby]
        ----
        def hello
          puts 'Hello, world!'
        end
        ----
      ADOC

      filter = described_class.new(input, context)
      output = filter.call

      expect(output).to include('<code>def hello')
    end

    it 'handles special characters and escaping' do
      input = 'Special characters: <, >, &'
      filter = described_class.new(input, context)
      output = filter.call

      expect(output).to include('Special characters: &lt;, &gt;, &amp;')
    end
  end
end
