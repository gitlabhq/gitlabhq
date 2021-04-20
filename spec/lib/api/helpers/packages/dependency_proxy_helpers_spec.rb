# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Helpers::Packages::DependencyProxyHelpers do
  let_it_be(:helper) { Class.new.include(described_class).new }

  describe 'redirect_registry_request' do
    using RSpec::Parameterized::TableSyntax

    let(:options) { {} }

    subject { helper.redirect_registry_request(forward_to_registry, package_type, options) { helper.fallback } }

    before do
      allow(helper).to receive(:options).and_return(for: API::NpmInstancePackages)
    end

    shared_examples 'executing fallback' do
      it 'redirects to package registry' do
        expect(helper).to receive(:registry_url).never
        expect(helper).to receive(:redirect).never
        expect(helper).to receive(:fallback).once

        subject
      end
    end

    shared_examples 'executing redirect' do
      it 'redirects to package registry', :snowplow do
        expect(helper).to receive(:registry_url).once
        expect(helper).to receive(:redirect).once
        expect(helper).to receive(:fallback).never

        subject

        expect_snowplow_event(category: 'API::NpmInstancePackages', action: 'npm_request_forward')
      end
    end

    context 'with npm packages' do
      let(:package_type) { :npm }

      where(:application_setting, :forward_to_registry, :example_name) do
        true  | true  | 'executing redirect'
        true  | false | 'executing fallback'
        false | true  | 'executing fallback'
        false | false | 'executing fallback'
      end

      with_them do
        before do
          stub_application_setting(npm_package_requests_forwarding: application_setting)
        end

        it_behaves_like params[:example_name]
      end
    end

    context 'with non-forwardable packages' do
      let(:forward_to_registry) { true }

      before do
        stub_application_setting(npm_package_requests_forwarding: true)
      end

      Packages::Package.package_types.keys.without('npm').each do |pkg_type|
        context "#{pkg_type}" do
          let(:package_type) { pkg_type }

          it 'raises an error' do
            expect { subject }.to raise_error(ArgumentError, "Can't build registry_url for package_type #{package_type}")
          end
        end
      end
    end
  end
end
