# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Middleware::Organizations::Current, feature_category: :cell do
  subject(:perform_request) do
    path = '/'
    app = ->(env) { [200, env, 'app'] }
    middleware = described_class.new(app)
    Rack::MockRequest.new(middleware).get(path)
  end

  context 'with an existing default organization' do
    let_it_be(:organization) { create(:organization, :default) }

    before_all do
      create(:organization) # prove we are really being selective for the default org
    end

    after do
      Current.reset
    end

    it 'loads the current organization' do
      perform_request

      expect(Current.organization).to eq(organization)
    end

    context 'when current_organization_middleware feature flag is disabled' do
      before do
        stub_feature_flags(current_organization_middleware: false)
      end

      it 'does not set the organization' do
        perform_request

        expect(Current.organization).to eq(nil)
      end
    end
  end

  context 'without an existing default organization' do
    it 'sets the current organization to nil' do
      perform_request

      expect(Current.organization).to eq(nil)
    end
  end
end
