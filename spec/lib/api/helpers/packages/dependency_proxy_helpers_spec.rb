# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Helpers::Packages::DependencyProxyHelpers do
  let_it_be(:helper) { Class.new.include(described_class).new }

  describe '#redirect_registry_request' do
    using RSpec::Parameterized::TableSyntax
    include_context 'dependency proxy helpers context'

    let_it_be(:group) { create(:group) }
    let_it_be_with_reload(:project) { create(:project, group: group) }
    let_it_be_with_reload(:package_setting) { create(:namespace_package_setting, namespace: group) }

    let(:target) { project }
    let(:options) { {} }

    subject do
      helper.redirect_registry_request(
        forward_to_registry: forward_to_registry,
        package_type: package_type,
        target: target,
        options: options
      ) { helper.fallback }
    end

    before do
      allow(helper).to receive(:options).and_return(for: described_class)
    end

    shared_examples 'executing fallback' do
      it 'redirects to package registry' do
        expect(helper).not_to receive(:registry_url)
        expect(helper).not_to receive(:redirect)
        expect(helper).to receive(:fallback).once

        subject
      end
    end

    shared_examples 'executing redirect' do
      it 'redirects to package registry', :snowplow do
        expect(helper).to receive(:registry_url).once
        expect(helper).to receive(:redirect).once
        expect(helper).not_to receive(:fallback)

        subject

        expect_snowplow_event(category: described_class.to_s, action: "#{package_type}_request_forward")
      end
    end

    %i[maven npm pypi].each do |forwardable_package_type|
      context "with #{forwardable_package_type} packages" do
        let(:package_type) { forwardable_package_type }

        where(:application_setting, :group_setting, :forward_to_registry, :example_name) do
          true  | nil   | true  | 'executing redirect'
          true  | nil   | false | 'executing fallback'
          false | nil   | true  | 'executing fallback'
          false | nil   | false | 'executing fallback'
          true  | false | true  | 'executing fallback'
          true  | false | false | 'executing fallback'
          false | true  | true  | 'executing redirect'
          false | true  | false | 'executing fallback'
        end

        with_them do
          before do
            allow_fetch_cascade_application_setting(attribute: "#{forwardable_package_type}_package_requests_forwarding", return_value: application_setting)
            package_setting.update!("#{forwardable_package_type}_package_requests_forwarding" => group_setting)
          end

          it_behaves_like params[:example_name]
        end
      end

      context 'when no target is present' do
        let(:package_type) { forwardable_package_type }
        let(:forward_to_registry) { true }
        let(:target) { nil }

        before do
          allow_fetch_cascade_application_setting(attribute: "#{forwardable_package_type}_package_requests_forwarding", return_value: true)
          package_setting.update!("#{forwardable_package_type}_package_requests_forwarding" => false)
        end

        it_behaves_like 'executing redirect'
      end

      context 'when maven_central_request_forwarding is disabled' do
        let(:package_type) { :maven }

        where(:application_setting, :forward_to_registry) do
          true  | true
          true  | false
          false | true
          false | false
        end

        with_them do
          before do
            stub_feature_flags(maven_central_request_forwarding: false)
            allow_fetch_cascade_application_setting(attribute: "maven_package_requests_forwarding", return_value: application_setting)
          end

          it_behaves_like 'executing fallback'
        end
      end
    end

    context 'with non-forwardable package type' do
      let(:forward_to_registry) { true }

      before do
        stub_application_setting(maven_package_requests_forwarding: true)
        stub_application_setting(npm_package_requests_forwarding: true)
        stub_application_setting(pypi_package_requests_forwarding: true)
      end

      Packages::Package.package_types.keys.without('maven', 'npm', 'pypi').each do |pkg_type|
        context pkg_type.to_s do
          let(:package_type) { pkg_type.to_sym }

          it 'raises an error' do
            expect { subject }.to raise_error(ArgumentError, "Can't find application setting for package_type #{package_type}")
          end
        end
      end
    end

    describe '#registry_url' do
      subject { helper.registry_url(package_type, options) }

      where(:package_type, :expected_result, :params) do
        :maven | 'https://repo.maven.apache.org/maven2/test/123' | { path: 'test', file_name: '123', project: project }
        :npm   | 'https://registry.npmjs.org/test' | { package_name: 'test' }
        :pypi  | 'https://pypi.org/simple/test/' | { package_name: 'test' }
      end

      with_them do
        let(:options) { params }

        it { is_expected.to eq(expected_result) }
      end

      Packages::Package.package_types.keys.without('maven', 'npm', 'pypi').each do |pkg_type|
        context "with non-forwardable package type #{pkg_type}" do
          let(:package_type) { pkg_type }

          it 'raises an error' do
            expect { subject }.to raise_error(ArgumentError, "Can't build registry_url for package_type #{package_type}")
          end
        end
      end
    end
  end
end
