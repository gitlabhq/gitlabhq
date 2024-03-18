# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Middleware::Organizations::Current, feature_category: :cell do
  let(:headers) { {} }
  let_it_be(:organization) { create(:organization) }

  subject(:perform_request) do
    path = '/'
    app = ->(env) { [200, env, 'app'] }
    middleware = described_class.new(app)
    Rack::MockRequest.new(middleware).get(path, headers)
  end

  before_all do
    create(:organization) # prove we are really being selective for the organization finder
  end

  after do
    Current.reset
  end

  it 'does not set the organization' do
    perform_request

    expect(Current.organization).to be_nil
  end

  context 'when the organization header is set' do
    let(:headers) { { ::Organizations::ORGANIZATION_HTTP_HEADER => organization.id } }

    it 'sets the organization' do
      perform_request

      expect(Current.organization).to eq(organization)
    end

    context 'when organization does not exist' do
      let(:headers) { { ::Organizations::ORGANIZATION_HTTP_HEADER => non_existing_record_id } }

      it 'does not set the organization' do
        perform_request

        expect(Current.organization).to be_nil
      end
    end

    context 'when organization has non-integer value' do
      let(:headers) { { ::Organizations::ORGANIZATION_HTTP_HEADER => "#{organization.id}_some_words" } }

      it 'does not set the organization' do
        perform_request

        expect(Current.organization).to be_nil
      end
    end
  end
end
