# frozen_string_literal: true

RSpec::Matchers.define :nullify_if_blank do |attribute|
  match do |record|
    expect(record.class.attributes_to_nullify).to include(attribute)
  end

  failure_message do |record|
    "expected nullify_if_blank configuration on #{record.class} to include #{attribute}"
  end
end
