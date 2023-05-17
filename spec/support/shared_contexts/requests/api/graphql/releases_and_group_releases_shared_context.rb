# frozen_string_literal: true

RSpec.shared_context 'when releases and group releases shared context' do
  let_it_be(:stranger) { create(:user) }
  let_it_be(:guest) { create(:user) }
  let_it_be(:reporter) { create(:user) }
  let_it_be(:developer) { create(:user) }

  let(:base_url_params) { { scope: 'all', release_tag: release.tag } }
  let(:opened_url_params) { { state: 'opened', **base_url_params } }
  let(:merged_url_params) { { state: 'merged', **base_url_params } }
  let(:closed_url_params) { { state: 'closed', **base_url_params } }

  let(:query) do
    graphql_query_for(resource_type, { fullPath: resource.full_path },
      %(
        releases {
          count
          nodes {
            tagName
            tagPath
            name
            commit {
              sha
            }
            assets {
              count
              sources {
                nodes {
                  url
                }
              }
            }
            evidences {
              nodes {
                sha
              }
            }
            links {
              selfUrl
              openedMergeRequestsUrl
              mergedMergeRequestsUrl
              closedMergeRequestsUrl
              openedIssuesUrl
              closedIssuesUrl
            }
          }
        }
      ))
  end

  let(:params_for_issues_and_mrs) { { scope: 'all', state: 'opened', release_tag: release.tag } }
  let(:post_query) { post_graphql(query, current_user: current_user) }

  let(:data) { graphql_data.dig(resource_type.to_s, 'releases', 'nodes', 0) }

  before do
    stub_default_url_options(host: 'www.example.com')
  end
end
