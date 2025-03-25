# frozen_string_literal: true

# Examples
# it { is_expected.to populate_sharding_key(:organization_id).from(:namespace) }
# it { is_expected.to populate_sharding_key(:organization_id).from(:project, :my_organization_id) }
# it { is_expected.to populate_sharding_key(:organization_id).with(1) }
RSpec::Matchers.define :populate_sharding_key do |sharding_field|
  chain(:from) do |source, field = sharding_field|
    @source = source
    @field = field
  end

  chain(:with) do |expected_value|
    @expected_value = expected_value
  end

  match do |model|
    @original_value = model.attributes[sharding_field.to_s]

    if @source
      @field ||= sharding_field.to_s
      @expected_value ||= 987654321
      mock = double(@field => @expected_value).as_null_object # rubocop:disable RSpec/VerifiedDoubles -- the source can be anything so can't set verified double.
      model.assign_attributes(@source.to_s => mock)
    end

    model.validate

    @populated_value = model.attributes[sharding_field.to_s]

    # Validate again to check that value doesn't change if already populated
    model.assign_attributes(sharding_field.to_s => 0)
    model.validate

    @second_populated_value = model.attributes[sharding_field.to_s]

    @original_value != @expected_value &&
      @populated_value == @expected_value &&
      @second_populated_value == @expected_value
  end

  failure_message do |model|
    if @populated_value != @expected_value
      <<~MSG
        expected #{model.class.name} to populate #{sharding_field} attribute but it didn't.
        Expected value: #{@expected_value}
        Actual value: #{model.public_send(sharding_field)}
      MSG
    elsif @original_value == @expected_value
      <<~MSG
        expected #{model.class.name} to populate #{sharding_field} attribute but
        it's already populated with expected value
      MSG
    else
      <<~MSG
        expected #{model.class.name} not to re-populate #{sharding_field} but it did change the value.
      MSG
    end
  end

  failure_message_when_negated do |_model|
    raise "Negation is not supported for the populate_sharding_key matcher"
  end

  description do
    "populate sharding_key"
  end
end
