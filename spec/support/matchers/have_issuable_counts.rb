# frozen_string_literal: true

RSpec::Matchers.define :have_issuable_counts do |opts|
  expected_counts = opts.map do |state, count|
    "#{state.to_s.humanize} #{count}"
  end

  match do |actual|
    actual.within '.top-area' do
      expected_counts.each do |expected_count|
        expect(actual).to have_content(expected_count)
      end
    end
  end

  description do
    "displays the following issuable counts: #{expected_counts.inspect}"
  end

  failure_message do
    "expected the following issuable counts: #{expected_counts.inspect} to be displayed"
  end
end
