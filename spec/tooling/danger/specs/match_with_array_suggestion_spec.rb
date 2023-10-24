# frozen_string_literal: true

require 'fast_spec_helper'
require 'gitlab/dangerfiles/spec_helper'

require_relative '../../../../tooling/danger/specs'
require_relative '../../../../tooling/danger/project_helper'

RSpec.describe Tooling::Danger::Specs::MatchWithArraySuggestion, feature_category: :tooling do
  include_context "with dangerfile"

  let(:fake_danger) { DangerSpecHelper.fake_danger.include(Tooling::Danger::Specs) }
  let(:fake_project_helper) { instance_double('Tooling::Danger::ProjectHelper') }
  let(:filename) { 'spec/foo_spec.rb' }

  let(:file_lines) do
    [
      " describe 'foo' do",
      " expect(foo).to match(['bar', 'baz'])",
      " end",
      " expect(foo).to match(['bar', 'baz'])", # same line as line 1 above, we expect two different suggestions
      " ",
      " expect(foo).to match ['bar', 'baz']",
      " expect(foo).to eq(['bar', 'baz'])",
      " expect(foo).to eq ['bar', 'baz']",
      " expect(foo).to(match(['bar', 'baz']))",
      " expect(foo).to(eq(['bar', 'baz']))",
      " expect(foo).to(eq([bar, baz]))",
      " expect(foo).to(eq(['bar']))",
      " foo.eq(['bar'])"
    ]
  end

  let(:matching_lines) do
    [
      "+ expect(foo).to match(['should not error'])",
      "+ expect(foo).to match(['bar', 'baz'])",
      "+ expect(foo).to match(['bar', 'baz'])",
      "+ expect(foo).to match ['bar', 'baz']",
      "+ expect(foo).to eq(['bar', 'baz'])",
      "+ expect(foo).to eq ['bar', 'baz']",
      "+ expect(foo).to(match(['bar', 'baz']))",
      "+ expect(foo).to(eq(['bar', 'baz']))",
      "+ expect(foo).to(eq([bar, baz]))"
    ]
  end

  let(:changed_lines) do
    [
      "  expect(foo).to match(['bar', 'baz'])",
      "  expect(foo).to match(['bar', 'baz'])",
      "  expect(foo).to match ['bar', 'baz']",
      "  expect(foo).to eq(['bar', 'baz'])",
      "  expect(foo).to eq ['bar', 'baz']",
      "- expect(foo).to match(['bar', 'baz'])",
      "- expect(foo).to match(['bar', 'baz'])",
      "- expect(foo).to match ['bar', 'baz']",
      "- expect(foo).to eq(['bar', 'baz'])",
      "- expect(foo).to eq ['bar', 'baz']",
      "- expect(foo).to eq [bar, foo]",
      "+ expect(foo).to eq([])"
    ] + matching_lines
  end

  let(:template) do
    <<~MARKDOWN.chomp
    ```suggestion
    %<suggested_line>s
    ```

    If order of the result is not important, please consider using `match_array` to avoid flakiness.
    MARKDOWN
  end

  subject(:specs) { fake_danger.new(helper: fake_helper) }

  before do
    allow(specs).to receive(:project_helper).and_return(fake_project_helper)
    allow(specs.helper).to receive(:changed_lines).with(filename).and_return(changed_lines)
    allow(specs.project_helper).to receive(:file_lines).and_return(file_lines)
  end

  it 'adds suggestions at the correct lines' do
    [
      { suggested_line: " expect(foo).to match_array(['bar', 'baz'])", number: 2 },
      { suggested_line: " expect(foo).to match_array(['bar', 'baz'])", number: 4 },
      { suggested_line: " expect(foo).to match_array ['bar', 'baz']", number: 6 },
      { suggested_line: " expect(foo).to match_array(['bar', 'baz'])", number: 7 },
      { suggested_line: " expect(foo).to match_array ['bar', 'baz']", number: 8 },
      { suggested_line: " expect(foo).to(match_array(['bar', 'baz']))", number: 9 },
      { suggested_line: " expect(foo).to(match_array(['bar', 'baz']))", number: 10 },
      { suggested_line: " expect(foo).to(match_array([bar, baz]))", number: 11 }
    ].each do |test_case|
      comment = format(template, suggested_line: test_case[:suggested_line])
      expect(specs).to receive(:markdown).with(comment, file: filename, line: test_case[:number])
    end

    specs.add_suggestions_for(filename)
  end
end
