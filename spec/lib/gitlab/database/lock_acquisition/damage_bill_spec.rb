# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Gitlab::Database::LockAcquisition::DamageBill, feature_category: :database do
  subject(:bill) { described_class.new }

  def now
    Process.clock_gettime(Process::CLOCK_MONOTONIC)
  end

  def backdate_last_accrual(seconds)
    bill.instance_variable_set(:@last_accrual_at, now - seconds)
  end

  it 'charges depth x elapsed into both the window and the run bill', :aggregate_failures do
    bill.new_attempt!(now - 5.0)
    backdate_last_accrual(1.0)

    bill.accrue(2, true)

    expect(bill.window_spent).to be_within(0.1).of(2.0)
    expect(bill.run_spent).to be_within(0.1).of(2.0)
  end

  it 'caps a single rectangle and flags it as a blind interval, consumed once', :aggregate_failures do
    bill.new_attempt!(now - 10.0)
    backdate_last_accrual(4.0)

    bill.accrue(2, true)

    expect(bill.window_spent).to be_within(0.1).of(2 * described_class::RECTANGLE_WIDTH_CAP_S)
    expect(bill.consume_capped_interval?).to be(true)
    expect(bill.consume_capped_interval?).to be(false)
  end

  it 'resets the window but never the run bill when nothing waits', :aggregate_failures do
    bill.new_attempt!(now - 5.0)
    backdate_last_accrual(1.0)
    bill.accrue(3, true)

    bill.accrue(0, false)

    expect(bill.window_spent).to eq(0.0)
    expect(bill.run_spent).to be_within(0.1).of(3.0)
    expect(bill).not_to be_window_exhausted
  end

  it 'bills a new attempt from the attempt start, not from the last accrual', :aggregate_failures do
    backdate_last_accrual(10.0)
    bill.new_attempt!(now - 1.0)

    bill.accrue(1, true)

    expect(bill.window_spent).to be_within(0.1).of(1.0)
  end

  it 'reports exhaustion against the window and run budgets', :aggregate_failures do
    bill.new_attempt!(now - 30.0)

    expect(bill).not_to be_window_exhausted

    backdate_last_accrual(1.0)
    bill.accrue(11, true)

    expect(bill).to be_window_exhausted
    expect(bill).to be_filled_on_first_poll
    expect(bill).not_to be_run_exhausted

    backdate_last_accrual(1.0)
    bill.accrue(11, true)

    expect(bill).to be_run_exhausted
    expect(bill).not_to be_filled_on_first_poll
  end
end
