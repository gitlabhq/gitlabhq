# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Auth::Iam, feature_category: :system_access do
  using RSpec::Parameterized::TableSyntax

  describe 'configuration methods' do
    where(:method, :config_method, :test_value) do
      :service_url | :url     | 'https://iam.example.com'
      :issuer      | :url     | 'https://iam.example.com'
      :enabled?    | :enabled | true
    end

    with_them do
      it "returns configured #{params[:method]}" do
        allow(Gitlab.config.authn.iam_service).to receive(config_method).and_return(test_value)

        expect(described_class.public_send(method)).to eq(test_value)
      end
    end
  end
end
