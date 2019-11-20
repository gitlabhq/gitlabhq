# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::GitlabImport::Client do
  include ImportSpecHelper

  let(:token) { '123456' }
  let(:client) { described_class.new(token) }

  before do
    stub_omniauth_provider('gitlab')
  end

  it 'all OAuth2 client options are symbols' do
    client.client.options.keys.each do |key|
      expect(key).to be_kind_of(Symbol)
    end
  end

  it 'uses membership and simple flags' do
    stub_request('/api/v4/projects?membership=true&page=1&per_page=100&simple=true')

    expect_any_instance_of(OAuth2::Response).to receive(:parsed).and_return([])

    expect(client.projects.to_a).to eq []
  end

  shared_examples 'pagination params' do
    before do
      allow_any_instance_of(OAuth2::Response).to receive(:parsed).and_return([])
    end

    it 'allows page_limit param' do
      allow_any_instance_of(OAuth2::Response).to receive(:parsed).and_return(element_list)

      expect(client).to receive(:lazy_page_iterator).with(hash_including(page_limit: 2)).and_call_original

      client.send(method, *args, page_limit: 2, per_page: 1).to_a
    end

    it 'allows per_page param' do
      expect(client).to receive(:lazy_page_iterator).with(hash_including(per_page: 2)).and_call_original

      client.send(method, *args, per_page: 2).to_a
    end

    it 'allows starting_page param' do
      expect(client).to receive(:lazy_page_iterator).with(hash_including(starting_page: 3)).and_call_original

      client.send(method, *args, starting_page: 3).to_a
    end
  end

  describe '#projects' do
    subject(:method) { :projects }

    let(:args) { [] }
    let(:element_list) { build_list(:project, 2) }

    before do
      stub_request('/api/v4/projects?membership=true&page=1&per_page=1&simple=true')
      stub_request('/api/v4/projects?membership=true&page=2&per_page=1&simple=true')
      stub_request('/api/v4/projects?membership=true&page=1&per_page=2&simple=true')
      stub_request('/api/v4/projects?membership=true&page=3&per_page=100&simple=true')
    end

    it_behaves_like 'pagination params'
  end

  describe '#issues' do
    subject(:method) { :issues }

    let(:args) { [1] }
    let(:element_list) { build_list(:issue, 2) }

    before do
      stub_request('/api/v4/projects/1/issues?page=1&per_page=1')
      stub_request('/api/v4/projects/1/issues?page=2&per_page=1')
      stub_request('/api/v4/projects/1/issues?page=1&per_page=2')
      stub_request('/api/v4/projects/1/issues?page=3&per_page=100')
    end

    it_behaves_like 'pagination params'
  end

  describe '#issue_comments' do
    subject(:method) { :issue_comments }

    let(:args) { [1, 1] }
    let(:element_list) { build_list(:note_on_issue, 2) }

    before do
      stub_request('/api/v4/projects/1/issues/1/notes?page=1&per_page=1')
      stub_request('/api/v4/projects/1/issues/1/notes?page=2&per_page=1')
      stub_request('/api/v4/projects/1/issues/1/notes?page=1&per_page=2')
      stub_request('/api/v4/projects/1/issues/1/notes?page=3&per_page=100')
    end

    it_behaves_like 'pagination params'
  end

  def stub_request(path)
    WebMock.stub_request(:get, "https://gitlab.com#{path}")
      .to_return(status: 200)
  end
end
