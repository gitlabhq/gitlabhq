# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::ProjectPackagesProtectionRules, feature_category: :package_registry do
  include ExclusiveLeaseHelpers

  let_it_be(:project) { create(:project, :private) }
  let_it_be(:other_project) { create(:project, :private) }
  let_it_be(:package_protection_rule) { create(:package_protection_rule, project: project) }

  let_it_be(:maintainer) { create(:user, maintainer_of: [project, other_project]) }
  let_it_be(:developer) { create(:user, developer_of: [project]) }
  let_it_be(:reporter) { create(:user, reporter_of: [project]) }
  let_it_be(:guest) { create(:user, guest_of: [project]) }

  let(:users) do
    {
      anonymous: nil,
      developer: developer,
      guest: guest,
      maintainer: maintainer,
      reporter: reporter
    }
  end

  shared_examples 'rejecting project packages protection rules request' do |user_type, status|
    context "for #{user_type}" do
      let(:api_user) { users[user_type] }

      it_behaves_like 'returning response status', status
    end
  end

  describe 'DELETE /projects/:id/packages/protection/rules/:package_protection_rule_id' do
    let(:url) { "/projects/#{project.id}/packages/protection/rules/#{package_protection_rule.id}" }

    subject(:destroy_package_rule) { delete(api(url, api_user)) }

    it_behaves_like 'rejecting project packages protection rules request', :reporter, :forbidden
    it_behaves_like 'rejecting project packages protection rules request', :developer, :forbidden
    it_behaves_like 'rejecting project packages protection rules request', :guest, :forbidden
    it_behaves_like 'rejecting project packages protection rules request', :anonymous, :not_found

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
  end
end
