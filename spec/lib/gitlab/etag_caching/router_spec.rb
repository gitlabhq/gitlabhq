require 'spec_helper'

describe Gitlab::EtagCaching::Router do
  it 'matches issue notes endpoint' do
    env = build_env(
      '/my-group/and-subgroup/here-comes-the-project/noteable/issue/1/notes'
    )

    result = described_class.match(env)

    expect(result).to be_present
    expect(result.name).to eq 'issue_notes'
  end

  it 'matches issue title endpoint' do
    env = build_env(
      '/my-group/my-project/issues/123/realtime_changes'
    )

    result = described_class.match(env)

    expect(result).to be_present
    expect(result.name).to eq 'issue_title'
  end

  it 'matches project pipelines endpoint' do
    env = build_env(
      '/my-group/my-project/pipelines.json'
    )

    result = described_class.match(env)

    expect(result).to be_present
    expect(result.name).to eq 'project_pipelines'
  end

  it 'matches commit pipelines endpoint' do
    env = build_env(
      '/my-group/my-project/commit/aa8260d253a53f73f6c26c734c72fdd600f6e6d4/pipelines.json'
    )

    result = described_class.match(env)

    expect(result).to be_present
    expect(result.name).to eq 'commit_pipelines'
  end

  it 'matches new merge request pipelines endpoint' do
    env = build_env(
      '/my-group/my-project/merge_requests/new.json'
    )

    result = described_class.match(env)

    expect(result).to be_present
    expect(result.name).to eq 'new_merge_request_pipelines'
  end

  it 'matches merge request pipelines endpoint' do
    env = build_env(
      '/my-group/my-project/merge_requests/234/pipelines.json'
    )

    result = described_class.match(env)

    expect(result).to be_present
    expect(result.name).to eq 'merge_request_pipelines'
  end

  it 'matches build endpoint' do
    env = build_env(
      '/my-group/my-project/builds/234.json'
    )

    result = described_class.match(env)

    expect(result).to be_present
    expect(result.name).to eq 'project_build'
  end

  it 'does not match blob with confusing name' do
    env = build_env(
      '/my-group/my-project/blob/master/pipelines.json'
    )

    result = described_class.match(env)

    expect(result).to be_blank
  end

<<<<<<< HEAD
  it 'matches pipeline#show endpoint' do
    env = build_env(
      '/my-group/my-project/pipelines/2.json'
=======
  it 'matches the environments path' do
    env = build_env(
      '/my-group/my-project/environments.json'
>>>>>>> ebede2b... Use etag caching for environments JSON
    )

    result = described_class.match(env)

<<<<<<< HEAD
<<<<<<< HEAD
    expect(result).to be_present
    expect(result.name).to eq 'project_pipeline'
=======
    expect(result).to be_blank
>>>>>>> ebede2b... Use etag caching for environments JSON
=======
    expect(result).to be_present
    expect(result.name).to eq 'environments'
>>>>>>> 3be9820... Test etag caching router and incorporate review
  end

  def build_env(path)
    { 'PATH_INFO' => path }
  end
end
