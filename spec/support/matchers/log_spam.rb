# frozen_string_literal: true

# This matcher checkes if one spam log with provided attributes was created
#
# Example:
#
# expect { create_issue }.to log_spam
RSpec::Matchers.define :log_spam do |expected|
  def spam_logs
    SpamLog.all
  end

  match do |block|
    block.call

    expect(spam_logs).to contain_exactly(
      have_attributes(expected)
    )
  end

  description do
    count = spam_logs.count

    if count == 1
      keys = expected.keys.map(&:to_s)
      actual = spam_logs.first.attributes.slice(*keys)
      "create a spam log with #{expected} attributes. #{actual} created instead."
    else
      "create exactly 1 spam log with #{expected} attributes. #{count} spam logs created instead."
    end
  end

  supports_block_expectations
end
