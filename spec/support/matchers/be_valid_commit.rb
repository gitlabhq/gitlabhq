# frozen_string_literal: true

RSpec::Matchers.define :be_valid_commit do
  match do |actual|
    actual &&
      actual.id == SeedRepo::Commit::ID &&
      actual.message == SeedRepo::Commit::MESSAGE &&
      actual.author_name == SeedRepo::Commit::AUTHOR_FULL_NAME
  end

  failure_message do |actual|
    if actual.nil?
      'expected a valid commit, but got nil'
    else
      expected_attrs = {
        id: SeedRepo::Commit::ID,
        message: SeedRepo::Commit::MESSAGE,
        author_name: SeedRepo::Commit::AUTHOR_FULL_NAME
      }
      mismatches = expected_attrs.filter_map do |attr, expected|
        actual_value = actual.public_send(attr)
        "#{attr}: expected #{expected.inspect}, got #{actual_value.inspect}" if actual_value != expected
      end
      "expected a valid commit, but found mismatches:\n  #{mismatches.join("\n  ")}"
    end
  end
end
