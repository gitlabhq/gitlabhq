# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'rendering project statistics', feature_category: :shared do
  include GraphqlHelpers

  let(:project) { create(:project) }
  let!(:project_statistics) { create(:project_statistics, project: project, packages_size: 5.gigabytes, uploads_size: 3.gigabytes) }
  let(:user) { create(:user) }

  let(:query) do
    graphql_query_for(
      'project',
      { 'fullPath' => project.full_path },
      "statistics { #{all_graphql_fields_for('ProjectStatistics')} }"
    )
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

    expect(graphql_data['project']['statistics']['packagesSize']).to eq(5.gigabytes)
  end

  it 'includes uploads size if the user can read the statistics' do
    post_graphql(query, current_user: user)

    expect(graphql_data_at(:project, :statistics, :uploadsSize)).to eq(3.gigabytes)
  end

  context 'when the project is public' do
    let(:project) { create(:project, :public) }

    it 'hides statistics for unauthenticated requests' do
      post_graphql(query, current_user: nil)

      expect(graphql_data['project']['statistics']).to be_blank
    end
  end
end
