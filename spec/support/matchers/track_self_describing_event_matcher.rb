# frozen_string_literal: true

RSpec::Matchers.define :track_self_describing_event do |schema, data|
  match do
    expect(Gitlab::Tracking).to have_received(:self_describing_event)
      .with(schema, data: data)
  end

  match_when_negated do
    expect(Gitlab::Tracking).not_to have_received(:self_describing_event)
  end
end
