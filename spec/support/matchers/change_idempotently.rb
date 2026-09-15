# frozen_string_literal: true

# Adds an `idempotently` modifier to the `change` matcher. The block runs twice.
# The first run has to satisfy the change expectation, the second one must not
# change the value at all.
#
# ```
# # Usage examples:
# expect { ingest }.to change { Sbom::Component.count }.by(4).idempotently
# expect { ingest }.to change { Sbom::Component.count }.idempotently
# expect { publish }.to change { record.reload.state }.to('done').idempotently
# ```
#
# The modifier calls the same block again, so a memoized `subject` never runs a
# second time and the example passes without testing anything. Call the code
# under test directly instead.
module ChangeMatcherIdempotency
  def idempotently
    @idempotently = true

    self
  end

  def matches?(event_proc)
    return false unless super
    return true unless @idempotently

    unchanged_on_second_run?(event_proc)
  end

  def does_not_match?(event_proc)
    raise NotImplementedError, '`expect { }.not_to change { }.idempotently` is not supported' if @idempotently

    super
  end

  def failure_message
    return super unless @changed_on_second_run

    "expected #{@change_details.value_representation} not to have changed on the second run, " \
      "but did change from #{@second_run_before_description} " \
      "to #{description_of(@change_details.actual_after)}"
  end

  def description
    @idempotently ? "#{super} idempotently" : super
  end

  private

  # Re-running `perform_change` re-reads the value, so the second run compares
  # against the state the first run left behind.
  def unchanged_on_second_run?(event_proc)
    @change_details.perform_change(event_proc) do |actual_before|
      @second_run_before_description = description_of(actual_before)
    end

    @changed_on_second_run = @change_details.changed?

    !@changed_on_second_run
  end
end

# `by`, `by_at_least`, `by_at_most`, `from` and `to` build a new matcher object,
# so the flag has to travel with them.
module ChangeMatcherIdempotencyChaining
  def by(...)
    carry_idempotency(super)
  end

  def by_at_least(...)
    carry_idempotency(super)
  end

  def by_at_most(...)
    carry_idempotency(super)
  end

  def from(...)
    carry_idempotency(super)
  end

  def to(...)
    carry_idempotency(super)
  end

  private

  def carry_idempotency(matcher)
    @idempotently ? matcher.idempotently : matcher
  end
end

RSpec::Matchers::BuiltIn::Change.prepend(ChangeMatcherIdempotency)
RSpec::Matchers::BuiltIn::Change.prepend(ChangeMatcherIdempotencyChaining)
RSpec::Matchers::BuiltIn::ChangeRelatively.prepend(ChangeMatcherIdempotency)
RSpec::Matchers::BuiltIn::ChangeFromValue.prepend(ChangeMatcherIdempotency)
RSpec::Matchers::BuiltIn::ChangeToValue.prepend(ChangeMatcherIdempotency)
