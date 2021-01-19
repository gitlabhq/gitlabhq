# frozen_string_literal: true

RSpec.shared_examples 'handling file uploads' do |shared_examples_name|
  context 'with object storage disabled' do
    it_behaves_like shared_examples_name
  end
end
