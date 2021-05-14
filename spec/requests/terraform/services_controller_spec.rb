# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Terraform::ServicesController do
  describe 'GET /.well-known/terraform.json' do
    subject { get '/.well-known/terraform.json' }

    it 'responds with terraform service discovery' do
      subject

      expect(json_response['modules.v1']).to eq("/api/#{::API::API.version}/packages/terraform/modules/v1/")
    end
  end
end
