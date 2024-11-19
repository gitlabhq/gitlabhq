# frozen_string_literal: true

RSpec.shared_examples 'set_current_context' do
  it 'sets the metadata of the request in the context' do |example|
    raise('this shared example should be used in a request spec only') unless example.metadata[:type] == :request

    raise('expected_context should be provided') unless example.metadata[:expected_context].nil?

    raise('described_class is invalid') if described_class.nil?

    meta = example.metadata[:example_group]
    loop do
      most_outer_scope = meta[:scoped_id].split(':').size == 1
      raise('this shared example should be used within the scope of the controller action') if most_outer_scope

      describe_action_scope = meta[:scoped_id].split(':').size == 2
      break if describe_action_scope

      meta = meta[:parent_example_group]
    end

    inferred_controller_action = meta[:description]
    unless inferred_controller_action.start_with?('#')
      raise('controller action describe should be in the form of "#action_name"')
    end

    inferred_controller_action = inferred_controller_action.delete('#')

    expect_next_instance_of(described_class) do |controller|
      expect(controller).to receive(inferred_controller_action).and_wrap_original do |m, *args|
        m.call(*args)

        expect(Gitlab::ApplicationContext.current).to include(expected_context)
      end
    end

    raise('subject/let binding (perform_request) should be provided') unless try(:perform_request) || subject
  end
end
