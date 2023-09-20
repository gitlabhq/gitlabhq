# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::EtagCaching::Router::Rails do
  it 'matches issue title endpoint' do
    result = match_route('/my-group/my-project/-/issues/123/realtime_changes')

    expect(result).to be_present
    expect(result.name).to eq 'issue_title'
  end

  it 'matches with a project name that includes a suffix of create' do
    result = match_route('/group/test-create/-/issues/123/realtime_changes')

    expect(result).to be_present
    expect(result.name).to eq 'issue_title'
  end

  it 'matches with a project name that includes a prefix of create' do
    result = match_route('/group/create-test/-/issues/123/realtime_changes')

    expect(result).to be_present
    expect(result.name).to eq 'issue_title'
  end

  it 'matches project pipelines endpoint' do
    result = match_route('/my-group/my-project/-/pipelines.json')

    expect(result).to be_present
    expect(result.name).to eq 'project_pipelines'
  end

  it 'matches commit pipelines endpoint' do
    result = match_route('/my-group/my-project/-/commit/aa8260d253a53f73f6c26c734c72fdd600f6e6d4/pipelines.json')

    expect(result).to be_present
    expect(result.name).to eq 'commit_pipelines'
  end

  it 'matches new merge request pipelines endpoint' do
    result = match_route('/my-group/my-project/-/merge_requests/new.json')

    expect(result).to be_present
    expect(result.name).to eq 'new_merge_request_pipelines'
  end

  it 'matches merge request pipelines endpoint' do
    result = match_route('/my-group/my-project/-/merge_requests/234/pipelines.json')

    expect(result).to be_present
    expect(result.name).to eq 'merge_request_pipelines'
  end

  it 'matches build endpoint' do
    result = match_route('/my-group/my-project/builds/234.json')

    expect(result).to be_present
    expect(result.name).to eq 'project_build'
  end

  it 'does not match blob with confusing name' do
    result = match_route('/my-group/my-project/-/blob/master/pipelines.json')

    expect(result).to be_blank
  end

  it 'matches the cluster environments path' do
    result = match_route('/my-group/my-project/-/clusters/47/environments')

    expect(result).to be_present
    expect(result.name).to eq 'cluster_environments'
  end

  it 'matches the environments path' do
    result = match_route('/my-group/my-project/-/environments.json')

    expect(result).to be_present
    expect(result.name).to eq 'environments'
  end

  it 'does not match the operations environments list path' do
    result = match_route('/-/operations/environments.json')

    expect(result).not_to be_present
  end

  it 'matches pipeline#show endpoint' do
    result = match_route('/my-group/my-project/-/pipelines/2.json')

    expect(result).to be_present
    expect(result.name).to eq 'project_pipeline'
  end

  it 'has a valid feature category for every route', :aggregate_failures do
    feature_categories = Gitlab::FeatureCategories.default.categories

    described_class.all_routes.each do |route|
      expect(feature_categories).to include(route.feature_category), "#{route.name} has a category of #{route.feature_category}, which is not valid"
    end
  end

  it 'has a caller_id for every route', :aggregate_failures do
    described_class.all_routes.each do |route|
      expect(route.caller_id).to include('#'), "#{route.name} has caller_id #{route.caller_id}, which is not valid"
    end
  end

  it 'has an urgency for every route', :aggregate_failures do
    described_class.all_routes.each do |route|
      expect(route.urgency).to be_an_instance_of(Gitlab::EndpointAttributes::Config::RequestUrgency)
    end
  end

  def match_route(path)
    described_class.match(double(path_info: path))
  end

  describe '.cache_key' do
    subject do
      described_class.cache_key(double(path: '/my-group/my-project/builds/234.json'))
    end

    it 'uses request path as cache key' do
      is_expected.to eq '/my-group/my-project/builds/234.json'
    end
  end
end
