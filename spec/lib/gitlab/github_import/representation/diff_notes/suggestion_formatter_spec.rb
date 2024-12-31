# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Gitlab::GithubImport::Representation::DiffNotes::SuggestionFormatter, feature_category: :importers do
  it 'does nothing when there is any text before the suggestion tag' do
    note = <<~BODY
    looks like```suggestion but it isn't
    ```
    BODY

    note_formatter = described_class.new(note: note)

    expect(note_formatter.formatted_note).to eq(note)
    expect(note_formatter.contains_suggestion?).to eq(false)
  end

  it 'handles nil value for note' do
    note = nil

    note_formatter = described_class.new(note: note)

    expect(note_formatter.formatted_note).to eq(note)
    expect(note_formatter.contains_suggestion?).to eq(false)
  end

  it 'does not allow over 3 leading spaces for valid suggestion' do
    note = <<~BODY
      Single-line suggestion
          ```suggestion
      sug1
      ```
    BODY

    note_formatter = described_class.new(note: note)

    expect(note_formatter.formatted_note).to eq(note)
    expect(note_formatter.contains_suggestion?).to eq(false)
  end

  it 'allows up to 3 leading spaces' do
    note = <<~BODY
      Single-line suggestion
         ```suggestion
      sug1
      ```
    BODY

    expected = <<~BODY
      Single-line suggestion
      ```suggestion:-0+0
      sug1
      ```
    BODY

    note_formatter = described_class.new(note: note)

    expect(note_formatter.formatted_note).to eq(expected)
    expect(note_formatter.contains_suggestion?).to eq(true)
  end

  it 'does nothing when there is any text without space after the suggestion tag' do
    note = <<~BODY
    ```suggestionbut it isn't
    ```
    BODY

    note_formatter = described_class.new(note: note)

    expect(note_formatter.formatted_note).to eq(note)
    expect(note_formatter.contains_suggestion?).to eq(false)
  end

  it 'formats single-line suggestions' do
    note = <<~BODY
      Single-line suggestion
      ```suggestion
      sug1
      ```
    BODY

    expected = <<~BODY
      Single-line suggestion
      ```suggestion:-0+0
      sug1
      ```
    BODY

    note_formatter = described_class.new(note: note)

    expect(note_formatter.formatted_note).to eq(expected)
    expect(note_formatter.contains_suggestion?).to eq(true)
  end

  it 'ignores text after suggestion tag on the same line' do
    note = <<~BODY
    looks like
    ```suggestion text to be ignored
    suggestion
    ```
    BODY

    expected = <<~BODY
    looks like
    ```suggestion:-0+0
    suggestion
    ```
    BODY

    note_formatter = described_class.new(note: note)

    expect(note_formatter.formatted_note).to eq(expected)
    expect(note_formatter.contains_suggestion?).to eq(true)
  end

  it 'formats multiple single-line suggestions' do
    note = <<~BODY
      Single-line suggestion
      ```suggestion
      sug1
      ```
      OR
      ```suggestion
      sug2
      ```
    BODY

    expected = <<~BODY
      Single-line suggestion
      ```suggestion:-0+0
      sug1
      ```
      OR
      ```suggestion:-0+0
      sug2
      ```
    BODY

    note_formatter = described_class.new(note: note)

    expect(note_formatter.formatted_note).to eq(expected)
    expect(note_formatter.contains_suggestion?).to eq(true)
  end

  it 'formats multi-line suggestions' do
    note = <<~BODY
      Multi-line suggestion
      ```suggestion
      sug1
      ```
    BODY

    expected = <<~BODY
      Multi-line suggestion
      ```suggestion:-2+0
      sug1
      ```
    BODY

    note_formatter = described_class.new(note: note, start_line: 6, end_line: 8)

    expect(note_formatter.formatted_note).to eq(expected)
    expect(note_formatter.contains_suggestion?).to eq(true)
  end

  it 'formats multiple multi-line suggestions' do
    note = <<~BODY
      Multi-line suggestion
      ```suggestion
      sug1
      ```
      OR
      ```suggestion
      sug2
      ```
    BODY

    expected = <<~BODY
      Multi-line suggestion
      ```suggestion:-2+0
      sug1
      ```
      OR
      ```suggestion:-2+0
      sug2
      ```
    BODY

    note_formatter = described_class.new(note: note, start_line: 6, end_line: 8)

    expect(note_formatter.formatted_note).to eq(expected)
    expect(note_formatter.contains_suggestion?).to eq(true)
  end
end
