# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Integrations::EnableSslVerification, feature_category: :integrations do
  let(:described_class) do
    Class.new(Integration) do
      prepend Integrations::EnableSslVerification

      field :main_url
      field :other_url
      field :username
    end
  end

  let(:integration) { described_class.new }

  include_context described_class
end
