# frozen_string_literal: true
require 'spec_helper'

RSpec.describe 'getting the packages cleanup policy linked to a project', feature_category: :package_registry do
  using RSpec::Parameterized::TableSyntax
  include GraphqlHelpers

  let_it_be_with_reload(:project) { create(:project) }
  let_it_be(:current_user) { project.first_owner }

  let(:fields) do
    <<~QUERY
      #{all_graphql_fields_for('packages_cleanup_policy'.classify)}
    QUERY
  end

  let(:query) do
    graphql_query_for(
      'project',
      { 'fullPath' => project.full_path },
      query_graphql_field('packagesCleanupPolicy', {}, fields)
    )
  end

  subject { post_graphql(query, current_user: current_user) }

  it_behaves_like 'a working graphql query' do
    before do
      subject
    end
  end

  context 'with an existing policy' do
    let_it_be(:policy) { create(:packages_cleanup_policy, project: project) }

    it_behaves_like 'a working graphql query' do
      before do
        subject
      end
    end
  end

  context 'with different permissions' do
    let_it_be(:current_user) { create(:user) }

    let(:packages_cleanup_policy_response) { graphql_data_at('project', 'packagesCleanupPolicy') }

    where(:visibility, :role, :policy_visible) do
      :private | :maintainer | true
      :private | :developer  | false
      :private | :reporter   | false
      :private | :guest      | false
      :private | :anonymous  | false
      :public  | :maintainer | true
      :public  | :developer  | false
      :public  | :reporter   | false
      :public  | :guest      | false
      :public  | :anonymous  | false
    end

    with_them do
      before do
        project.update!(visibility: visibility.to_s)
        project.add_member(current_user, role) unless role == :anonymous
      end

      it 'return the proper response' do
        subject

        if policy_visible
          expect(packages_cleanup_policy_response)
            .to eq('keepNDuplicatedPackageFiles' => 'ALL_PACKAGE_FILES', 'nextRunAt' => nil)
        else
          expect(packages_cleanup_policy_response).to be_blank
        end
      end
    end
  end
end
