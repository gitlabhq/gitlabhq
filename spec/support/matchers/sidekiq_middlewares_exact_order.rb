# frozen_string_literal: true

RSpec::Matchers.define :contain_sidekiq_middlewares_exactly do |expected|
  match do |actual|
    @actual = actual
    @expected = expected

    next false unless actual.is_a?(Array) && expected.is_a?(Array)

    @missing_elements = expected - actual
    next false unless @missing_elements.empty?

    @extra_elements = actual - expected
    next false unless @extra_elements.empty?

    true
  end

  failure_message do
    if !@missing_elements.empty?
      <<~MESSAGE
      Expected #{@actual.inspect} to contain #{@missing_elements.inspect}, but they were missing.

      Please adjust the allowed middlewares accordingly.
      MESSAGE
    elsif !@extra_elements.empty?
      <<~MESSAGE
      Unexpected #{@extra_elements.inspect} in #{@expected.inspect}.

      If #{@extra_elements.inspect} do not intercept job execution (return early or not yielding) between
      DuplicateJobs::Client and DuplicateJobs::Server, please add #{@extra_elements.inspect} to the allowed middlewares
      accordingly.

      If #{@extra_elements.inspect} do intercept job execution between DuplicateJobs::Client and DuplicateJobs::Server,
      #{@extra_elements.inspect} has to be placed before DuplicateJobs::Client or after DuplicateJobs::Server.

      See https://gitlab.com/gitlab-org/gitlab/-/merge_requests/174929 for more information.
      MESSAGE
    end
  end
end
