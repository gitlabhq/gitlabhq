# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Creating the packages protection rule', :aggregate_failures, feature_category: :package_registry do
  include GraphqlHelpers
  using RSpec::Parameterized::TableSyntax

  let_it_be(:project) { create(:project) }
  let_it_be(:user) { create(:user, maintainer_projects: [project]) }

  let(:package_protection_rule_attributes) { build_stubbed(:package_protection_rule, project: project) }

  let(:kwargs) do
    {
      project_path: project.full_path,
      package_name_pattern: package_protection_rule_attributes.package_name_pattern,
      package_type: "NPM",
      push_protected_up_to_access_level: "MAINTAINER"
    }
  end

  let(:mutation) do
    graphql_mutation(:create_packages_protection_rule, kwargs,
      <<~QUERY
      clientMutationId
      errors
      QUERY
    )
  end

  let(:mutation_response) { graphql_mutation_response(:create_packages_protection_rule) }

  describe 'post graphql mutation' do
    subject { post_graphql_mutation(mutation, current_user: user) }

    context 'without existing packages protection rule' do
      it 'returns without error' do
        subject

        expect_graphql_errors_to_be_empty
      end

      it 'returns the created packages protection rule' do
        expect { subject }.to change { ::Packages::Protection::Rule.count }.by(1)

        expect_graphql_errors_to_be_empty
        expect(Packages::Protection::Rule.where(project: project).count).to eq 1

        expect(Packages::Protection::Rule.where(project: project,
          package_name_pattern: kwargs[:package_name_pattern])).to exist
      end

      context 'when invalid fields are given' do
        let(:kwargs) do
          {
            project_path: project.full_path,
            package_name_pattern: '',
            package_type: 'UNKNOWN_PACKAGE_TYPE',
            push_protected_up_to_access_level: 'UNKNOWN_ACCESS_LEVEL'
          }
        end

        it 'returns error about required argument' do
          subject

          expect_graphql_errors_to_include(/was provided invalid value for packageType/)
          expect_graphql_errors_to_include(/pushProtectedUpToAccessLevel/)
        end
      end
    end

    context 'when user does not have permission' do
      let_it_be(:developer) { create(:user).tap { |u| project.add_developer(u) } }
      let_it_be(:reporter) { create(:user).tap { |u| project.add_reporter(u) } }
      let_it_be(:guest) { create(:user).tap { |u| project.add_guest(u) } }
      let_it_be(:anonymous) { create(:user) }

      where(:user) do
        [ref(:developer), ref(:reporter), ref(:guest), ref(:anonymous)]
      end

      with_them do
        it 'returns an error' do
          expect { subject }.not_to change { ::Packages::Protection::Rule.count }

          expect_graphql_errors_to_include(/you don't have permission to perform this action/)
        end
      end
    end

    context 'with existing packages protection rule' do
      let_it_be(:existing_package_protection_rule) do
        create(:package_protection_rule, project: project, push_protected_up_to_access_level: Gitlab::Access::DEVELOPER)
      end

      context 'when package name pattern is slightly different' do
        let(:kwargs) do
          {
            project_path: project.full_path,
            # The field `package_name_pattern` is unique; this is why we change the value in a minimum way
            package_name_pattern: "#{existing_package_protection_rule.package_name_pattern}-unique",
            package_type: "NPM",
            push_protected_up_to_access_level: "DEVELOPER"
          }
        end

        it 'returns the created packages protection rule' do
          expect { subject }.to change { ::Packages::Protection::Rule.count }.by(1)

          expect(Packages::Protection::Rule.where(project: project).count).to eq 2
          expect(Packages::Protection::Rule.where(project: project,
            package_name_pattern: kwargs[:package_name_pattern])).to exist
        end

        it 'returns without error' do
          subject

          expect_graphql_errors_to_be_empty
        end
      end

      context 'when field `package_name_pattern` is taken' do
        let(:kwargs) do
          {
            project_path: project.full_path,
            package_name_pattern: existing_package_protection_rule.package_name_pattern,
            package_type: 'NPM',
            push_protected_up_to_access_level: 'MAINTAINER'
          }
        end

        it 'returns without error' do
          subject

          expect(mutation_response).to include 'errors' => ['Package name pattern has already been taken']
        end

        it 'does not create new package protection rules' do
          expect { subject }.to change { Packages::Protection::Rule.count }.by(0)

          expect(Packages::Protection::Rule.where(project: project,
            package_name_pattern: kwargs[:package_name_pattern],
            push_protected_up_to_access_level: Gitlab::Access::MAINTAINER)).not_to exist
        end
      end
    end

    context "when feature flag ':packages_protected_packages' disabled" do
      before do
        stub_feature_flags(packages_protected_packages: false)
      end

      it 'does not create any package protection rules' do
        expect { subject }.to change { Packages::Protection::Rule.count }.by(0)

        expect(Packages::Protection::Rule.where(project: project)).not_to exist
      end

      it 'returns error of disabled feature flag' do
        subject.tap { expect_graphql_errors_to_include(/'packages_protected_packages' feature flag is disabled/) }
      end
    end
  end
end
