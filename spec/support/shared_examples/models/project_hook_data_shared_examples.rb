# frozen_string_literal: true

RSpec.shared_examples 'project hook data with deprecateds' do |project_key: :project|
  it 'contains project data' do
    expect(data[project_key][:name]).to eq(project.name)
    expect(data[project_key][:description]).to eq(project.description)
    expect(data[project_key][:web_url]).to eq(project.web_url)
    expect(data[project_key][:avatar_url]).to eq(project.avatar_url)
    expect(data[project_key][:git_http_url]).to eq(project.http_url_to_repo)
    expect(data[project_key][:git_ssh_url]).to eq(project.ssh_url_to_repo)
    expect(data[project_key][:namespace]).to eq(project.namespace.name)
    expect(data[project_key][:visibility_level]).to eq(project.visibility_level)
    expect(data[project_key][:path_with_namespace]).to eq(project.full_path)
    expect(data[project_key][:default_branch]).to eq(project.default_branch)
    expect(data[project_key][:homepage]).to eq(project.web_url)
    expect(data[project_key][:url]).to eq(project.url_to_repo)
    expect(data[project_key][:ssh_url]).to eq(project.ssh_url_to_repo)
    expect(data[project_key][:http_url]).to eq(project.http_url_to_repo)
  end
end

RSpec.shared_examples 'project hook data' do |project_key: :project|
  it 'contains project data' do
    expect(data[project_key][:name]).to eq(project.name)
    expect(data[project_key][:description]).to eq(project.description)
    expect(data[project_key][:web_url]).to eq(project.web_url)
    expect(data[project_key][:avatar_url]).to eq(project.avatar_url)
    expect(data[project_key][:git_http_url]).to eq(project.http_url_to_repo)
    expect(data[project_key][:git_ssh_url]).to eq(project.ssh_url_to_repo)
    expect(data[project_key][:namespace]).to eq(project.namespace.name)
    expect(data[project_key][:visibility_level]).to eq(project.visibility_level)
    expect(data[project_key][:path_with_namespace]).to eq(project.full_path)
    expect(data[project_key][:default_branch]).to eq(project.default_branch)
  end
end

RSpec.shared_examples 'deprecated repository hook data' do
  it 'contains deprecated repository data' do
    expect(data[:repository][:name]).to eq(project.name)
    expect(data[:repository][:description]).to eq(project.description)
    expect(data[:repository][:url]).to eq(project.url_to_repo)
    expect(data[:repository][:homepage]).to eq(project.web_url)
  end
end

RSpec.shared_examples 'push hook data' do
  it 'contains commit data' do
    expect(data).to be_a(Hash)
    expect(data[:before]).to eq('1b12f15a11fc6e62177bef08f47bc7b5ce50b141')
    expect(data[:after]).to eq('b83d6e391c22777fca1ed3012fce84f633d7fed0')
    expect(data[:commits].size).to eq(3)
    expect(data[:total_commits_count]).to eq(3)
    expect(data[:commits].first[:added]).to eq(['bar/branch-test.txt'])
    expect(data[:commits].first[:modified]).to eq([])
    expect(data[:commits].first[:removed]).to eq([])
  end
end
