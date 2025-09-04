# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'searching groups', :with_license, feature_category: :groups_and_projects do
  it_behaves_like 'groups query' do
    describe 'project statistics' do
      context 'when user can read statistics' do
        before_all do
          public_group.add_owner(user)
        end

        it 'returns project_statistics field' do
          subject

          expect(graphql_data_at(field_name.to_s.camelize(:lower).to_sym, :nodes, 0, :project_statistics)).to include({
            "buildArtifactsSize" => 0.0,
            "lfsObjectsSize" => 0.0,
            "packagesSize" => 0.0,
            "pipelineArtifactsSize" => 0.0,
            "repositorySize" => 0.0,
            "snippetsSize" => 0.0,
            "storageSize" => 0.0,
            "uploadsSize" => 0.0,
            "wikiSize" => 0.0
          })
        end
      end

      context 'when user does not have admin ability' do
        it 'returns project_statistics field as nil' do
          subject

          expect(graphql_data_at(field_name, :nodes, 0, :project_statistics)).to be_nil
        end
      end
    end
  end
end
