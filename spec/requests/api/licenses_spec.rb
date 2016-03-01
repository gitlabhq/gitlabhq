require 'spec_helper'

describe API::API, api: true  do
  include ApiHelpers
  describe 'GET /licenses/:key' do
    before(:each) do
      get api("/licenses/#{license_type}?fullname=Anton")
    end

    context 'for mit license name' do
      let(:license_type){ 'mit' }

      it 'returns MIT license text and replases template values' do
        expect(response.body).to include('Copyright (c) 2016 Anton')
        expect(response.body).to include('Copyright (c) 2016')
      end
    end

    context 'for gnu license name' do
      let(:license_type){ 'gpl-3.0' }

      it 'returns GNU license text and replases template values' do
        expect(response.body).to include('GNU GENERAL PUBLIC LICENSE')
        expect(response.body).to include('Copyright (C) 2016')
      end
    end

    context 'for apache license name' do
      let(:license_type){ 'apache-2.0' }

      it 'returns Apache license text and replases template values' do
        expect(response.body).to include('Apache License')
        expect(response.body).to include('Copyright 2016')
      end
    end

    context 'for mythic license name' do
      let(:license_type){ 'muth-over9000' }

      it 'returns string with error' do
        expect(response).to have_http_status(404)
        expect(response.body).to eq 'License not found'
      end
    end
  end
end
