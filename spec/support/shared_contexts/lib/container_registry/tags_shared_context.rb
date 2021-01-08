# frozen_string_literal: true

RSpec.shared_context 'container registry tags' do
  def stub_next_container_registry_tags_call(method_name, mock_value)
    allow_next_instance_of(ContainerRegistry::Tag) do |tag|
      allow(tag).to receive(method_name).and_return(mock_value)
    end
  end
end
