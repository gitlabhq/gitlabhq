# frozen_string_literal: true

RSpec.shared_examples 'a gitlab tracking event' do |category, action|
  it "creates a gitlab tracking event #{action}", :snowplow do
    subject

    expect_snowplow_event(category: category, action: action, **snowplow_standard_context_params)
  end
end
