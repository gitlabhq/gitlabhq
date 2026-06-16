# frozen_string_literal: true

# Stands in for the dispatching Danger plugin, which exposes the Danger DSL
# (warn/fail) as public methods and forwards helper. Shared by the lock rule
# specs so the fake context is defined in a single place.
RSpec.shared_context 'with database change lock rule context' do
  let(:context) do
    Class.new do
      attr_reader :helper

      def initialize(helper)
        @helper = helper
      end

      def warn(*); end
      def fail(*); end
    end.new(fake_helper)
  end
end
