# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::ProjectPackagesProtectionRules, :aggregate_failures, feature_category: :package_registry do
  include ExclusiveLeaseHelpers

  let_it_be(:project) { create(:project, :private) }
  let_it_be(:other_project) { create(:project, :private) }
  let_it_be(:package_protection_rule) { create(:package_protection_rule, project: project) }

  let_it_be(:maintainer) { create(:user, maintainer_of: [project, other_project]) }
  let_it_be(:api_user) { create(:user) }

  let_it_be(:invalid_token) { 'invalid-token123' }
  let_it_be(:headers_with_invalid_token) { { Gitlab::Auth::AuthFinders::PRIVATE_TOKEN_HEADER => invalid_token } }

  shared_examples 'rejecting project packages protection rules request when not enough permissions' do
    using RSpec::Parameterized::TableSyntax

    where(:user_role, :status) do
      :reporter  | :forbidden
      :developer | :forbidden
      :guest     | :forbidden
      nil        | :not_found
    end

    with_them do
      before do
        project.send(:"add_#{user_role}", api_user) if user_role
      end

      it_behaves_like 'returning response status', params[:status]
    end
  end

  describe 'GET /projects/:id/packages/protection/rules' do
    let(:url) { "/projects/#{project.id}/packages/protection/rules" }

    subject(:get_package_rules) { get(api(url, api_user)) }

    it_behaves_like 'rejecting project packages protection rules request when not enough permissions'

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

        it_behaves_like 'returning response status', :not_found
      end

      context 'when the project id does not exist' do
        let(:url) { "/projects/#{non_existing_record_id}/packages/protection/rules" }

        it_behaves_like 'returning response status', :not_found
      end

      context 'when packages_protected_packages is disabled' do
        before do
          stub_feature_flags(packages_protected_packages: false)
        end

        it_behaves_like 'returning response status', :not_found
      end
    end

    context 'with invalid token' do
      subject(:get_package_rules) { get(api(url), headers: headers_with_invalid_token) }

      it_behaves_like 'returning response status', :unauthorized
    end
  end

  describe 'POST /projects/:id/packages/protection/rules' do
    let(:url) { "/projects/#{project.id}/packages/protection/rules" }
    let(:params) do
      { package_name_pattern: '@my-new-scope/my-package-*',
        package_type: package_protection_rule.package_type,
        minimum_access_level_for_push: package_protection_rule.minimum_access_level_for_push }
    end

    subject(:post_package_rule) { post(api(url, api_user), params: params) }

    it_behaves_like 'rejecting project packages protection rules request when not enough permissions'

    context 'for maintainer' do
      let(:api_user) { maintainer }

      it 'creates a package protection rule' do
        expect { post_package_rule }.to change { Packages::Protection::Rule.count }.by(1)
        expect(response).to have_gitlab_http_status(:created)
      end

      context 'with invalid package_type' do
        before do
          params[:package_type] = "not in enum"
        end

        it 'does not create a package protection rule' do
          expect { post_package_rule }.to not_change(Packages::Protection::Rule, :count)
          expect(response).to have_gitlab_http_status(:bad_request)
        end
      end

      context 'with invalid minimum_access_level_for_push' do
        before do
          params[:minimum_access_level_for_push] = "not in enum"
        end

        it 'does not create a package protection rule' do
          expect { post_package_rule }.to not_change(Packages::Protection::Rule, :count)
          expect(response).to have_gitlab_http_status(:bad_request)
        end
      end

      context 'with already existing package_name_pattern' do
        before do
          params[:package_name_pattern] = package_protection_rule.package_name_pattern
        end

        it 'does not create a package protection rule' do
          expect { post_package_rule }.to not_change(Packages::Protection::Rule, :count)
          expect(response).to have_gitlab_http_status(:unprocessable_entity)
        end
      end

      context 'when the project id is invalid' do
        let(:url) { "/projects/invalid/packages/protection/rules" }

        it_behaves_like 'returning response status', :not_found
      end

      context 'when the project id does not exist' do
        let(:url) { "/projects/#{non_existing_record_id}/packages/protection/rules" }

        it_behaves_like 'returning response status', :not_found
      end

      context 'when packages_protected_packages is disabled' do
        before do
          stub_feature_flags(packages_protected_packages: false)
        end

        it_behaves_like 'returning response status', :not_found
      end
    end
  end

  describe 'DELETE /projects/:id/packages/protection/rules/:package_protection_rule_id' do
    let(:url) { "/projects/#{project.id}/packages/protection/rules/#{package_protection_rule.id}" }

    subject(:destroy_package_rule) { delete(api(url, api_user)) }

    it_behaves_like 'rejecting project packages protection rules request when not enough permissions'

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

      it_behaves_like 'returning response status', :not_found
    end

    context 'when the project id is invalid' do
      let(:url) { "/projects/invalid/packages/protection/rules/#{package_protection_rule.id}" }

      it_behaves_like 'returning response status', :not_found
    end

    context 'when the project id does not exist' do
      let(:url) { "/projects/#{non_existing_record_id}/packages/protection/rules/#{package_protection_rule.id}" }

      it_behaves_like 'returning response status', :not_found
    end

    context 'when the rule id is invalid' do
      let(:url) { "/projects/#{project.id}/packages/protection/rules/invalid" }

      it_behaves_like 'returning response status', :bad_request
    end

    context 'when the rule id does not exist' do
      let(:url) { "/projects/#{project.id}/packages/protection/rules/#{non_existing_record_id}" }

      it_behaves_like 'returning response status', :not_found
    end

    context 'when packages_protected_packages is disabled' do
      before do
        stub_feature_flags(packages_protected_packages: false)
      end

      it_behaves_like 'returning response status', :not_found
    end

    context 'with invalid token' do
      subject(:delete_package_rules) { delete(api(url), headers: headers_with_invalid_token) }

      it_behaves_like 'returning response status', :unauthorized
    end
  end
end
