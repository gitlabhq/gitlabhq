# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::NpmInstancePackages do
  include_context 'npm api setup'

  describe 'GET /api/v4/packages/npm/*package_name' do
    it_behaves_like 'handling get metadata requests' do
      let(:url) { api("/packages/npm/#{package_name}") }
    end
  end

  describe 'GET /api/v4/packages/npm/-/package/*package_name/dist-tags' do
    it_behaves_like 'handling get dist tags requests', scope: :instance do
      let(:url) { api("/packages/npm/-/package/#{package_name}/dist-tags") }
    end
  end

  describe 'PUT /api/v4/packages/npm/-/package/*package_name/dist-tags/:tag' do
    it_behaves_like 'handling create dist tag requests', scope: :instance do
      let(:url) { api("/packages/npm/-/package/#{package_name}/dist-tags/#{tag_name}") }
    end
  end

  describe 'DELETE /api/v4/packages/npm/-/package/*package_name/dist-tags/:tag' do
    it_behaves_like 'handling delete dist tag requests', scope: :instance do
      let(:url) { api("/packages/npm/-/package/#{package_name}/dist-tags/#{tag_name}") }
    end
  end
end
