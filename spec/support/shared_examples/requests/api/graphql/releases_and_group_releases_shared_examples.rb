# frozen_string_literal: true

RSpec.shared_examples 'correct total count' do
  let(:data) { graphql_data.dig(resource_type.to_s, 'releases') }

  before do
    create_list(:release, 2, project: project)

    post_query
  end

  it 'returns the total count' do
    expect(data['count']).to eq(project.releases.count)
  end
end

RSpec.shared_examples 'when there are no releases' do
  let(:data) { graphql_data.dig(resource_type.to_s, 'releases') }

  before do
    project.releases.delete_all(:delete_all)

    post_query
  end

  it 'returns an empty array' do
    expect(data['nodes']).to eq([])
  end
end

RSpec.shared_examples 'full access to all repository-related fields' do
  describe 'repository-related fields' do
    before do
      post_query
    end

    it 'returns data for fields that are protected in private projects' do
      expected_sources = release.sources.map do |s|
        { 'url' => s.url }
      end

      expected_evidences = release.evidences.map do |e|
        { 'sha' => e.sha }
      end
      expect(data).to eq(
        'tagName' => release.tag,
        'tagPath' => project_tag_path(project, release.tag),
        'name' => release.name,
        'commit' => {
          'sha' => release.commit.sha
        },
        'assets' => {
          'count' => release.assets_count,
          'sources' => {
            'nodes' => expected_sources
          }
        },
        'evidences' => {
          'nodes' => expected_evidences
        },
        'links' => {
          'selfUrl' => project_release_url(project, release),
          'openedMergeRequestsUrl' => project_merge_requests_url(project, opened_url_params),
          'mergedMergeRequestsUrl' => project_merge_requests_url(project, merged_url_params),
          'closedMergeRequestsUrl' => project_merge_requests_url(project, closed_url_params),
          'openedIssuesUrl' => project_issues_url(project, opened_url_params),
          'closedIssuesUrl' => project_issues_url(project, closed_url_params)
        }
      )
    end
  end

  it_behaves_like 'correct total count'
  it_behaves_like 'when there are no releases'
end

RSpec.shared_examples 'no access to any repository-related fields' do
  describe 'repository-related fields' do
    before do
      post_query
    end

    it 'does not return data for fields that expose repository information' do
      tag_name = release.tag
      release_name = release.name
      expect(data).to eq(
        'tagName' => tag_name,
        'tagPath' => nil,
        'name' => release_name,
        'commit' => nil,
        'assets' => {
          'count' => release.assets_count(except: [:sources]),
          'sources' => {
            'nodes' => []
          }
        },
        'evidences' => {
          'nodes' => []
        },
        'links' => {
          'closedIssuesUrl' => nil,
          'closedMergeRequestsUrl' => nil,
          'mergedMergeRequestsUrl' => nil,
          'openedIssuesUrl' => nil,
          'openedMergeRequestsUrl' => nil,
          'selfUrl' => project_release_url(project, release)
        }
      )
    end
  end

  it_behaves_like 'correct total count'
end

RSpec.shared_examples 'access to editUrl' do
  # editUrl is tested separately because its permissions
  # are slightly different than other release fields
  let(:query) do
    graphql_query_for(resource_type, { fullPath: resource.full_path },
      %(
        releases {
          nodes {
            links {
              editUrl
            }
          }
        }
      ))
  end

  before do
    post_query
  end

  it 'returns editUrl' do
    expect(data).to eq(
      'links' => {
        'editUrl' => edit_project_release_url(project, release)
      }
    )
  end
end

RSpec.shared_examples 'no access to editUrl' do
  let(:query) do
    graphql_query_for(resource_type, { fullPath: resource.full_path },
      %(
        releases {
          nodes {
            links {
              editUrl
            }
          }
        }
      ))
  end

  before do
    post_query
  end

  it 'does not return editUrl' do
    expect(data).to eq(
      'links' => {
        'editUrl' => nil
      }
    )
  end
end

RSpec.shared_examples 'no access to any release data' do
  before do
    post_query
  end

  it 'returns nil' do
    expect(data).to eq(nil)
  end
end
