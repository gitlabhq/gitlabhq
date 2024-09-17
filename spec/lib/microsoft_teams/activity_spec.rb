# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe MicrosoftTeams::Activity do
  subject { described_class.new(title: 'title', subtitle: 'subtitle', text: 'text', image: 'image') }

  describe '#prepare' do
    it 'returns the correct JSON object' do
      expect(subject.prepare).to eq(
        {
          type: "ColumnSet",
          columns: [
            { type: "Column", width: "auto", items: [
              { type: "Image", url: "image", size: "medium" }
            ] },
            { type: "Column", width: "stretch", items: [
              { type: "TextBlock", text: "title", weight: "bolder", wrap: true },
              { type: "TextBlock", text: "subtitle", isSubtle: true, wrap: true },
              { type: "TextBlock", text: "text", wrap: true }
            ] }
          ]
        }
      )
    end
  end
end
