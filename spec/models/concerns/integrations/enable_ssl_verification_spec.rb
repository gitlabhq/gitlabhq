# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Integrations::EnableSslVerification do
  let(:described_class) do
    Class.new(Integration) do
      prepend Integrations::EnableSslVerification

      def fields
        [
          { name: 'main_url' },
          { name: 'other_url' },
          { name: 'username' }
        ]
      end
    end
  end

  let(:integration) { described_class.new }

  include_context Integrations::EnableSslVerification
end
