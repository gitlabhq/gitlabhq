# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::EtagCaching::Router do
  it 'matches issue notes endpoint' do
    result = described_class.match(
      '/my-group/and-subgroup/here-comes-the-project/noteable/issue/1/notes'
    )

    expect(result).to be_present
    expect(result.name).to eq 'issue_notes'
  end

  it 'matches MR notes endpoint' do
    result = described_class.match(
      '/my-group/and-subgroup/here-comes-the-project/noteable/merge_request/1/notes'
    )

    expect(result).to be_present
    expect(result.name).to eq 'merge_request_notes'
  end

  it 'matches issue title endpoint' do
    result = described_class.match(
      '/my-group/my-project/issues/123/realtime_changes'
    )

    expect(result).to be_present
    expect(result.name).to eq 'issue_title'
  end

  it 'matches with a project name that includes a suffix of create' do
    result = described_class.match(
      '/group/test-create/issues/123/realtime_changes'
    )

    expect(result).to be_present
    expect(result.name).to eq 'issue_title'
  end

  it 'matches with a project name that includes a prefix of create' do
    result = described_class.match(
      '/group/create-test/issues/123/realtime_changes'
    )

    expect(result).to be_present
    expect(result.name).to eq 'issue_title'
  end

  it 'matches project pipelines endpoint' do
    result = described_class.match(
      '/my-group/my-project/pipelines.json'
    )

    expect(result).to be_present
    expect(result.name).to eq 'project_pipelines'
  end

  it 'matches commit pipelines endpoint' do
    result = described_class.match(
      '/my-group/my-project/commit/aa8260d253a53f73f6c26c734c72fdd600f6e6d4/pipelines.json'
    )

    expect(result).to be_present
    expect(result.name).to eq 'commit_pipelines'
  end

  it 'matches new merge request pipelines endpoint' do
    result = described_class.match(
      '/my-group/my-project/merge_requests/new.json'
    )

    expect(result).to be_present
    expect(result.name).to eq 'new_merge_request_pipelines'
  end

  it 'matches merge request pipelines endpoint' do
    result = described_class.match(
      '/my-group/my-project/merge_requests/234/pipelines.json'
    )

    expect(result).to be_present
    expect(result.name).to eq 'merge_request_pipelines'
  end

  it 'matches build endpoint' do
    result = described_class.match(
      '/my-group/my-project/builds/234.json'
    )

    expect(result).to be_present
    expect(result.name).to eq 'project_build'
  end

  it 'does not match blob with confusing name' do
    result = described_class.match(
      '/my-group/my-project/blob/master/pipelines.json'
    )

    expect(result).to be_blank
  end

  it 'matches the cluster environments path' do
    result = described_class.match(
      '/my-group/my-project/-/clusters/47/environments'
    )

    expect(result).to be_present
    expect(result.name).to eq 'cluster_environments'
  end

  it 'matches the environments path' do
    result = described_class.match(
      '/my-group/my-project/environments.json'
    )

    expect(result).to be_present
    expect(result.name).to eq 'environments'
  end

  it 'matches pipeline#show endpoint' do
    result = described_class.match(
      '/my-group/my-project/pipelines/2.json'
    )

    expect(result).to be_present
    expect(result.name).to eq 'project_pipeline'
  end
end
