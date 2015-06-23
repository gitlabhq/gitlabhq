RSpec::Matchers.define :be_valid_commit do
  match do |actual|
    actual &&
      actual.id == ValidCommit::ID &&
      actual.message == ValidCommit::MESSAGE &&
      actual.author_name == ValidCommit::AUTHOR_FULL_NAME
  end
end

def emulate_user(user)
  user = case user
        when :user then create(:user)
        when :visitor then nil
        when :admin then create(:admin)
        else user
        end
  login_with(user) if user
end

RSpec::Matchers.define :be_allowed_for do |user|
  match do |url|
    emulate_user(user)
    visit url
    status_code != 404 && current_path != new_user_session_path
  end
end

RSpec::Matchers.define :be_denied_for do |user|
  match do |url|
    emulate_user(user)
    visit url
    status_code == 404 || current_path == new_user_session_path
  end
end

RSpec::Matchers.define :be_not_found_for do |user|
  match do |url|
    emulate_user(user)
    visit url
    status_code == 404
  end
end

RSpec::Matchers.define :include_module do |expected|
  match do
    described_class.included_modules.include?(expected)
  end

  description do
    "includes the #{expected} module"
  end

  failure_message do
    "expected #{described_class} to include the #{expected} module"
  end
end

# Extend shoulda-matchers
module Shoulda::Matchers::ActiveModel
  class ValidateLengthOfMatcher
    # Shortcut for is_at_least and is_at_most
    def is_within(range)
      is_at_least(range.min) && is_at_most(range.max)
    end
  end
end
