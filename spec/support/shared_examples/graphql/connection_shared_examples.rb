# frozen_string_literal: true

RSpec.shared_examples 'a connection with collection methods' do
  %i[to_a size map include? empty?].each do |method_name|
    it "responds to #{method_name}" do
      expect(connection).to respond_to(method_name)
    end
  end
end
