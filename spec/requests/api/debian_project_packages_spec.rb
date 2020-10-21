# frozen_string_literal: true
require 'spec_helper'

RSpec.describe API::DebianProjectPackages do
  include HttpBasicAuthHelpers
  include WorkhorseHelpers

  include_context 'Debian repository shared context', :project do
    describe 'GET projects/:id/-/packages/debian/dists/*distribution/Release.gpg' do
      let(:url) { "/projects/#{project.id}/-/packages/debian/dists/#{distribution}/Release.gpg" }

      it_behaves_like 'Debian project repository GET endpoint', :not_found, nil
    end

    describe 'GET projects/:id/-/packages/debian/dists/*distribution/Release' do
      let(:url) { "/projects/#{project.id}/-/packages/debian/dists/#{distribution}/Release" }

      it_behaves_like 'Debian project repository GET endpoint', :success, 'TODO Release'
    end

    describe 'GET projects/:id/-/packages/debian/dists/*distribution/InRelease' do
      let(:url) { "/projects/#{project.id}/-/packages/debian/dists/#{distribution}/InRelease" }

      it_behaves_like 'Debian project repository GET endpoint', :not_found, nil
    end

    describe 'GET projects/:id/-/packages/debian/dists/*distribution/:component/binary-:architecture/Packages' do
      let(:url) { "/projects/#{project.id}/-/packages/debian/dists/#{distribution}/#{component}/binary-#{architecture}/Packages" }

      it_behaves_like 'Debian project repository GET endpoint', :success, 'TODO Packages'
    end

    describe 'GET projects/:id/-/packages/debian/pool/:component/:letter/:source_package/:file_name' do
      let(:url) { "/projects/#{project.id}/-/packages/debian/pool/#{component}/#{letter}/#{source_package}/#{package_name}_#{package_version}_#{architecture}.deb" }

      it_behaves_like 'Debian project repository GET endpoint', :success, 'TODO File'
    end

    describe 'PUT projects/:id/-/packages/debian/incoming/:file_name' do
      let(:method) { :put }
      let(:url) { "/projects/#{project.id}/-/packages/debian/incoming/#{file_name}" }

      it_behaves_like 'Debian project repository PUT endpoint', :created, nil
    end
  end
end
