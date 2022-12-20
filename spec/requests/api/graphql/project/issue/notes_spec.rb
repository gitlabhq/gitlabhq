# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'getting notes for an issue', feature_category: :team_planning do
  include GraphqlHelpers

  let(:noteable) { create(:issue) }
  let(:noteable_data) { graphql_data['project']['issue'] }

  def noteable_query(noteable_fields)
    <<~QRY
      {
        project(fullPath: "#{noteable.project.full_path}") {
          issue(iid: "#{noteable.iid}") {
            #{noteable_fields}
          }
        }
      }
    QRY
  end

  it_behaves_like 'exposing regular notes on a noteable in GraphQL'
end
