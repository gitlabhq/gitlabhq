# frozen_string_literal: true

require 'spec_helper'

describe 'rendering namespace statistics' do
  include GraphqlHelpers

  let(:project) { create(:project) }
  let!(:project_statistics) { create(:project_statistics, project: project, packages_size: 5.megabytes) }
  let(:user) { create(:user) }

  let(:query) do
    graphql_query_for('project',
                      { 'fullPath' => project.full_path },
                      "statistics { #{all_graphql_fields_for('ProjectStatistics')} }")
  end

  before do
    project.add_reporter(user)
  end

  it_behaves_like 'a working graphql query' do
    before do
      post_graphql(query, current_user: user)
    end
  end

  it "includes the packages size if the user can read the statistics" do
    post_graphql(query, current_user: user)

    expect(graphql_data['project']['statistics']['packagesSize']).to eq(5.megabytes)
  end

  context 'when the project is public' do
    let(:project) { create(:project, :public) }

    it 'includes the statistics regardless of the user' do
      post_graphql(query, current_user: nil)

      expect(graphql_data['project']['statistics']).to be_present
    end
  end
end
