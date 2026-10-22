# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'database query analyzers initializer', feature_category: :database do
  describe 'Rack middleware' do
    let(:middlewares) { Rails.application.middleware.map(&:klass) }
    let(:analyzer_index) { middlewares.index(Gitlab::Middleware::QueryAnalyzer) }

    it 'enables the query analyzers once the request store is available' do
      expect(analyzer_index).to be > middlewares.index(RequestStore::Middleware)
    end

    it 'enables the query analyzers before middleware that runs queries', :aggregate_failures do
      expect(analyzer_index).to be < middlewares.index(Gitlab::Middleware::ReadOnly)
      expect(analyzer_index).to be < middlewares.index(Warden::Manager)
      expect(analyzer_index).to be < middlewares.index(Rack::Attack)
    end
  end
end
