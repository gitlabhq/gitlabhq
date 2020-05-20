# frozen_string_literal: true

RSpec.shared_examples 'requires variables' do
  it 'shared example requires variables to be set', :aggregate_failures do
    variables = Array.wrap(required_variables)

    variables.each do |variable_name|
      expect { send(variable_name) }.not_to(
        raise_error, "The following variable must be set to use this shared example: #{variable_name}"
      )
    end
  end
end
