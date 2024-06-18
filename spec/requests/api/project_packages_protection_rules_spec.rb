# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::ProjectPackagesProtectionRules, feature_category: :package_registry do
  include ExclusiveLeaseHelpers

  let_it_be(:project) { create(:project, :private) }
  let_it_be(:other_project) { create(:project, :private) }
  let_it_be(:package_protection_rule) { create(:package_protection_rule, project: project) }

  let_it_be(:maintainer) { create(:user, maintainer_of: [project, other_project]) }
  let_it_be(:api_user) { create(:user) }

  let_it_be(:invalid_token) { 'invalid-token123' }
  let_it_be(:headers_with_invalid_token) { { Gitlab::Auth::AuthFinders::PRIVATE_TOKEN_HEADER => invalid_token } }

  shared_examples 'rejecting project packages protection rules request' do |user_role, status|
    context "for #{user_role}" do
      before do
        project.send(:"add_#{user_role}", api_user) if user_role
      end

      it_behaves_like 'returning response status', status
    end
  end

  describe 'GET /projects/:id/packages/protection/rules' do
    let(:url) { "/projects/#{project.id}/packages/protection/rules" }

    subject(:get_package_rules) { get(api(url, api_user)) }

    it_behaves_like 'rejecting project packages protection rules request', :reporter, :forbidden
    it_behaves_like 'rejecting project packages protection rules request', :developer, :forbidden
    it_behaves_like 'rejecting project packages protection rules request', :guest, :forbidden
    it_behaves_like 'rejecting project packages protection rules request', nil, :not_found

    context 'for maintainer' do
      let(:api_user) { maintainer }

      let_it_be(:other_package_protection_rule) do
        create(:package_protection_rule, project: project, package_name_pattern: "@my-scope/my-package-*")
      end

      it 'gets the package protection rules' do
        get_package_rules

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response.count).to eq(2)
      end

      context 'when the project id is invalid' do
        let(:url) { "/projects/invalid/packages/protection/rules" }

        it_behaves_like 'rejecting project packages protection rules request', :maintainer, :not_found
      end

      context 'when the project id does not exist' do
        let(:url) { "/projects/#{non_existing_record_id}/packages/protection/rules" }

        it_behaves_like 'rejecting project packages protection rules request', :maintainer, :not_found
      end

      context 'when packages_protected_packages is disabled' do
        before do
          stub_feature_flags(packages_protected_packages: false)
        end

        it_behaves_like 'rejecting project packages protection rules request', :maintainer, :not_found
      end
    end

    context 'with invalid token' do
      subject(:get_package_rules) { get(api(url), headers: headers_with_invalid_token) }

      it_behaves_like 'rejecting project packages protection rules request', nil, :unauthorized
    end
  end

  describe 'DELETE /projects/:id/packages/protection/rules/:package_protection_rule_id' do
    let(:url) { "/projects/#{project.id}/packages/protection/rules/#{package_protection_rule.id}" }

    subject(:destroy_package_rule) { delete(api(url, api_user)) }

    it_behaves_like 'rejecting project packages protection rules request', :reporter, :forbidden
    it_behaves_like 'rejecting project packages protection rules request', :developer, :forbidden
    it_behaves_like 'rejecting project packages protection rules request', :guest, :forbidden
    it_behaves_like 'rejecting project packages protection rules request', nil, :not_found

    context 'for maintainer' do
      let(:api_user) { maintainer }

      it 'deletes the package protection rule' do
        destroy_package_rule
        expect do
          Packages::Protection::Rule.find(package_protection_rule.id)
        end.to raise_error(ActiveRecord::RecordNotFound)
        expect(response).to have_gitlab_http_status(:no_content)
      end
    end

    context 'when the package protection rule does belong to another project' do
      let(:url) { "/projects/#{other_project.id}/packages/protection/rules/#{package_protection_rule.id}" }

      it_behaves_like 'rejecting project packages protection rules request', :maintainer, :not_found
    end

    context 'when the project id is invalid' do
      let(:url) { "/projects/invalid/packages/protection/rules/#{package_protection_rule.id}" }

      it_behaves_like 'rejecting project packages protection rules request', :maintainer, :not_found
    end

    context 'when the project id does not exist' do
      let(:url) { "/projects/#{non_existing_record_id}/packages/protection/rules/#{package_protection_rule.id}" }

      it_behaves_like 'rejecting project packages protection rules request', :maintainer, :not_found
    end

    context 'when the rule id is invalid' do
      let(:url) { "/projects/#{project.id}/packages/protection/rules/invalid" }

      it_behaves_like 'rejecting project packages protection rules request', :maintainer, :bad_request
    end

    context 'when the rule id does not exist' do
      let(:url) { "/projects/#{project.id}/packages/protection/rules/#{non_existing_record_id}" }

      it_behaves_like 'rejecting project packages protection rules request', :maintainer, :not_found
    end

    context 'when packages_protected_packages is disabled' do
      before do
        stub_feature_flags(packages_protected_packages: false)
      end

      it_behaves_like 'rejecting project packages protection rules request', :maintainer, :not_found
    end

    context 'with invalid token' do
      subject(:delete_package_rules) { delete(api(url), headers: headers_with_invalid_token) }

      it_behaves_like 'rejecting project packages protection rules request', nil, :unauthorized
    end
  end
end
