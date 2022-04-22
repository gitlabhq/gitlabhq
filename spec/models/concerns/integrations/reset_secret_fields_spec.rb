# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Integrations::ResetSecretFields do
  let(:described_class) do
    Class.new(Integration) do
      field :username, type: 'text'
      field :url, type: 'text', exposes_secrets: true
      field :api_url, type: 'text', exposes_secrets: true
      field :password, type: 'password'
      field :token, type: 'password'
    end
  end

  let(:integration) { described_class.new }

  it_behaves_like Integrations::ResetSecretFields
end
