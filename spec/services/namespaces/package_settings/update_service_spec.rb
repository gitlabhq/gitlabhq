# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Namespaces::PackageSettings::UpdateService, feature_category: :package_registry do
  using RSpec::Parameterized::TableSyntax

  let_it_be_with_reload(:namespace) { create(:group) }
  let_it_be(:user) { create(:user) }
  let_it_be(:params) { {} }

  describe '#execute' do
    subject { described_class.new(container: namespace, current_user: user, params: params).execute }

    shared_examples 'returning a success' do
      it 'returns a success' do
        result = subject

        expect(result.payload[:package_settings]).to be_present
        expect(result.success?).to be_truthy
      end
    end

    shared_examples 'returning an error' do |message, http_status|
      it 'returns an error' do
        result = subject

        expect(result.message).to eq(message)
        expect(result.status).to eq(:error)
        expect(result.http_status).to eq(http_status)
      end
    end

    shared_examples 'updating the namespace package setting' do
      it_behaves_like 'updating the namespace package setting attributes',
        from: {
          maven_duplicates_allowed: true,
          maven_duplicate_exception_regex: 'SNAPSHOT',
          generic_duplicates_allowed: true,
          generic_duplicate_exception_regex: 'foo',
          nuget_duplicates_allowed: true,
          nuget_duplicate_exception_regex: 'foo',
          maven_package_requests_forwarding: true,
          lock_maven_package_requests_forwarding: false,
          npm_package_requests_forwarding: nil,
          lock_npm_package_requests_forwarding: false,
          pypi_package_requests_forwarding: nil,
          lock_pypi_package_requests_forwarding: false,
          nuget_symbol_server_enabled: false,
          terraform_module_duplicates_allowed: false,
          terraform_module_duplicate_exception_regex: 'foo'
        }, to: {
          maven_duplicates_allowed: false,
          maven_duplicate_exception_regex: 'RELEASE',
          generic_duplicates_allowed: false,
          generic_duplicate_exception_regex: 'bar',
          nuget_duplicates_allowed: false,
          nuget_duplicate_exception_regex: 'bar',
          maven_package_requests_forwarding: true,
          lock_maven_package_requests_forwarding: true,
          npm_package_requests_forwarding: true,
          lock_npm_package_requests_forwarding: true,
          pypi_package_requests_forwarding: true,
          lock_pypi_package_requests_forwarding: true,
          nuget_symbol_server_enabled: true,
          terraform_module_duplicates_allowed: true,
          terraform_module_duplicate_exception_regex: 'bar'
        }

      it_behaves_like 'returning a success'

      context 'with invalid params' do
        let_it_be(:params) { { maven_duplicates_allowed: nil } }

        it_behaves_like 'not creating the namespace package setting'

        it "doesn't update the maven_duplicates_allowed" do
          expect { subject }
            .not_to change { package_settings.reload.maven_duplicates_allowed }
        end

        it_behaves_like 'returning an error', 'Maven duplicates allowed is not included in the list', 400
      end
    end

    shared_examples 'denying access to namespace package setting' do
      context 'with existing namespace package setting' do
        it_behaves_like 'not creating the namespace package setting'

        it_behaves_like 'returning an error', 'Access Denied', 403
      end
    end

    context 'with existing namespace package setting' do
      let_it_be(:package_settings) { create(:namespace_package_setting, namespace: namespace) }
      let_it_be(:params) do
        {
          maven_duplicates_allowed: false,
          maven_duplicate_exception_regex: 'RELEASE',
          generic_duplicates_allowed: false,
          generic_duplicate_exception_regex: 'bar',
          nuget_duplicates_allowed: false,
          nuget_duplicate_exception_regex: 'bar',
          maven_package_requests_forwarding: true,
          lock_maven_package_requests_forwarding: true,
          npm_package_requests_forwarding: true,
          lock_npm_package_requests_forwarding: true,
          pypi_package_requests_forwarding: true,
          lock_pypi_package_requests_forwarding: true,
          nuget_symbol_server_enabled: true,
          terraform_module_duplicates_allowed: true,
          terraform_module_duplicate_exception_regex: 'bar'
        }
      end

      where(:user_role, :shared_examples_name) do
        :owner      | 'updating the namespace package setting'
        :maintainer | 'denying access to namespace package setting'
        :developer  | 'denying access to namespace package setting'
        :reporter   | 'denying access to namespace package setting'
        :guest      | 'denying access to namespace package setting'
        :anonymous  | 'denying access to namespace package setting'
      end

      with_them do
        before do
          namespace.send("add_#{user_role}", user) unless user_role == :anonymous
        end

        it_behaves_like params[:shared_examples_name]
      end
    end

    context 'without existing namespace package setting' do
      let_it_be(:package_settings) { namespace.package_settings }

      where(:user_role, :shared_examples_name) do
        :owner      | 'creating the namespace package setting'
        :maintainer | 'denying access to namespace package setting'
        :developer  | 'denying access to namespace package setting'
        :reporter   | 'denying access to namespace package setting'
        :guest      | 'denying access to namespace package setting'
        :anonymous  | 'denying access to namespace package setting'
      end

      with_them do
        before do
          namespace.send("add_#{user_role}", user) unless user_role == :anonymous
        end

        it_behaves_like params[:shared_examples_name]
      end
    end
  end
end
