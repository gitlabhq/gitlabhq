# frozen_string_literal: true

# For basic testing of abilities for users with license stubbing.
# This doesn't provide any resources for you and assumes that the
# roles/users/projects/organizations setup will be provided.
# eg. let_it_be(:developer) { create(:user, developer_of: my_project) }
#
# Expected usage:
#
# it_behaves_like 'enables permissions for the correct roles',
#   licensed_feature: :security_dashboard, # licensed feature that should be toggled
#   permissions: %i[ # permissions you want to test
#     read_vulnerability
#     create_vulnerability_export
#     create_vulnerability_archive_export
#     admin_vulnerability_issue_link
#     admin_vulnerability_external_issue_link
#     read_security_project_tracked_ref
#   ],
#   allowed: %w[owner maintainer security_manager developer], # users that should be allowed when the license is enabled
#   disallowed: %w[guest reporter] # users that should not be allowed when the license is enabled

RSpec.shared_examples 'enables permissions for the correct roles' do |params|
  all_roles = params[:allowed] + params[:disallowed]
  enabled_cases = params[:allowed].map { |role| [role, true, :allowed] } +
    params[:disallowed].map { |role| [role, true, :disallowed] }
  disabled_cases = all_roles.map { |role| [role, false, :disallowed] }

  (enabled_cases + disabled_cases).each do |role_name, feature_enabled, expected|
    state = feature_enabled ? 'enabled' : 'disabled'
    context "when #{params[:licensed_feature]} is #{state}" do
      let(:current_user) { send(role_name) }
      let(:permissions) { Array(params[:permissions]) }

      feature = params[:licensed_feature]
      before do
        stub_licensed_features(feature => feature_enabled)
      end

      it "is #{expected} with #{role_name}" do
        if expected == :allowed
          expect_allowed(*permissions)
        else
          expect_disallowed(*permissions)
        end
      end
    end
  end
end
