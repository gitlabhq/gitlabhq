# frozen_string_literal: true

require 'spec_helper'

module API
  class CustomAttributesEndpointsExampleImpl < ::API::Base
    include ::API::CustomAttributesEndpoints
  end
end

RSpec.describe API::CustomAttributesEndpoints, feature_category: :groups_and_projects do
  let(:instance) { ::API::CustomAttributesEndpointsExampleImpl.new }

  before do
    instance.extend(::API::CustomAttributesEndpointsExampleImpl.helpers)
  end

  describe 'find_resource' do
    it 'render_api_error! when attributable name is not in list' do
      expect(instance).to receive(:render_api_error!).and_raise 'Invalid finder method'
      expect { instance.find_resource('invalid', non_existing_record_id) }.to raise_error 'Invalid finder method'
    end
  end
end
