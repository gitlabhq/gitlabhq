# frozen_string_literal: true

require 'spec_helper'

# The shared API::Hooks modules set route_setting :tier only when the mounting
# class passes `tier:` in its mount configuration (see `given configuration[:tier]`).
RSpec.describe 'API::Hooks route tiers', feature_category: :webhooks do
  shared_examples 'hook routes without a tier' do
    it 'does not annotate any route, including the shared hook modules', :aggregate_failures do
      paths = routes.map(&:path)

      expect(paths).to include(a_string_including('/url_variables/'), a_string_including('/custom_headers/'))
      expect(routes.map { |route| route.settings[:tier] }.uniq).to eq([nil])
    end
  end

  describe API::ProjectHooks do
    let(:routes) { described_class.routes }

    it_behaves_like 'hook routes without a tier'
  end

  describe API::SystemHooks do
    let(:routes) { described_class.routes }

    it_behaves_like 'hook routes without a tier'
  end
end
