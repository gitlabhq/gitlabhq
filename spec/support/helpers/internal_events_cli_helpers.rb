# frozen_string_literal: true

module InternalEventsCliHelpers
  def stub_milestone(milestone)
    stub_const("InternalEventsCli::Helpers::MILESTONE", milestone)
  end

  def stub_product_groups(body)
    allow(Net::HTTP).to receive(:get)
      .with(URI(InternalEventsCli::Helpers::GroupOwnership::STAGES_YML))
      .and_return(body)
  end

  def stub_helper(helper, value)
    # rubocop:disable RSpec/AnyInstanceOf -- 'Next' helper not included in fast_spec_helper & next is insufficient
    allow_any_instance_of(InternalEventsCli::Helpers).to receive(helper).and_return(value)
    # rubocop:enable RSpec/AnyInstanceOf
  end

  def internal_event_fixture(filepath)
    Rails.root.join('spec', 'fixtures', 'scripts', 'internal_events', filepath)
  end
end
