# frozen_string_literal: true

RSpec::Matchers.define :be_valid_commit do
  match do |actual|
    actual &&
      actual.id == SeedRepo::Commit::ID &&
      actual.message == SeedRepo::Commit::MESSAGE &&
      actual.author_name == SeedRepo::Commit::AUTHOR_FULL_NAME
  end
end
