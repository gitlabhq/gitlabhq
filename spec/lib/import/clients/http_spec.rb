# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Import::Clients::HTTP, feature_category: :importers do
  [:delete, :head, :get, :post, :put, :try_get].each do |method|
    describe ".#{method}" do
      before do
        stub_application_setting(max_http_response_size_limit: 1)
      end

      it "delegates to Gitlab::HTTP.#{method}" do
        path = 'https://example.com/api'

        expect(Gitlab::HTTP).to receive(method).with(path,
          { headers: { 'Content-Type' => 'application/json' }, max_bytes: 1.megabyte })

        described_class.public_send(method, path, { headers: { 'Content-Type' => 'application/json' } })
      end
    end
  end
end
