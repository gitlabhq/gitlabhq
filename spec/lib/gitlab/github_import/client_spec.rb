# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::GithubImport::Client do
  describe '#parallel?' do
    it 'returns true when the client is running in parallel mode' do
      client = described_class.new('foo', parallel: true)

      expect(client).to be_parallel
    end

    it 'returns false when the client is running in sequential mode' do
      client = described_class.new('foo', parallel: false)

      expect(client).not_to be_parallel
    end
  end

  describe '#user' do
    it 'returns the details for the given username' do
      client = described_class.new('foo')

      expect(client.octokit).to receive(:user).with('foo')
      expect(client).to receive(:with_rate_limit).and_yield

      client.user('foo')
    end
  end

  describe '#pull_request_reviews' do
    it 'returns the pull request reviews' do
      client = described_class.new('foo')

      expect(client)
        .to receive(:each_object)
        .with(:pull_request_reviews, 'foo/bar', 999)

      client.pull_request_reviews('foo/bar', 999)
    end
  end

  describe '#repository' do
    it 'returns the details of a repository' do
      client = described_class.new('foo')

      expect(client.octokit).to receive(:repo).with('foo/bar')
      expect(client).to receive(:with_rate_limit).and_yield

      client.repository('foo/bar')
    end
  end

  describe '#pull_request' do
    it 'returns the details of a pull_request' do
      client = described_class.new('foo')

      expect(client.octokit).to receive(:pull_request).with('foo/bar', 999)
      expect(client).to receive(:with_rate_limit).and_yield

      client.pull_request('foo/bar', 999)
    end
  end

  describe '#labels' do
    it 'returns the labels' do
      client = described_class.new('foo')

      expect(client)
        .to receive(:each_object)
        .with(:labels, 'foo/bar')

      client.labels('foo/bar')
    end
  end

  describe '#milestones' do
    it 'returns the milestones' do
      client = described_class.new('foo')

      expect(client)
        .to receive(:each_object)
        .with(:milestones, 'foo/bar')

      client.milestones('foo/bar')
    end
  end

  describe '#releases' do
    it 'returns the releases' do
      client = described_class.new('foo')

      expect(client)
        .to receive(:each_object)
        .with(:releases, 'foo/bar')

      client.releases('foo/bar')
    end
  end

  describe '#each_page' do
    let(:client) { described_class.new('foo') }
    let(:object1) { double(:object1) }
    let(:object2) { double(:object2) }

    before do
      allow(client)
        .to receive(:with_rate_limit)
        .and_yield

      allow(client.octokit)
        .to receive(:public_send)
        .and_return([object1])

      response = double(:response, data: [object2], rels: { next: nil })
      next_page = double(:next_page, get: response)

      allow(client.octokit)
        .to receive(:last_response)
        .and_return(double(:last_response, rels: { next: next_page }))
    end

    context 'without a block' do
      it 'returns an Enumerator' do
        expect(client.each_page(:foo)).to be_an_instance_of(Enumerator)
      end

      it 'the returned Enumerator returns Page objects' do
        enum = client.each_page(:foo)

        page1 = enum.next
        page2 = enum.next

        expect(page1).to be_an_instance_of(described_class::Page)
        expect(page2).to be_an_instance_of(described_class::Page)

        expect(page1.objects).to eq([object1])
        expect(page1.number).to eq(1)

        expect(page2.objects).to eq([object2])
        expect(page2.number).to eq(2)
      end
    end

    context 'with a block' do
      it 'yields every retrieved page to the supplied block' do
        pages = []

        client.each_page(:foo) { |page| pages << page }

        expect(pages[0]).to be_an_instance_of(described_class::Page)
        expect(pages[1]).to be_an_instance_of(described_class::Page)

        expect(pages[0].objects).to eq([object1])
        expect(pages[0].number).to eq(1)

        expect(pages[1].objects).to eq([object2])
        expect(pages[1].number).to eq(2)
      end

      it 'starts at the given page' do
        pages = []

        client.each_page(:foo, page: 2) { |page| pages << page }

        expect(pages[0].number).to eq(2)
        expect(pages[1].number).to eq(3)
      end
    end
  end

  describe '#with_rate_limit' do
    let(:client) { described_class.new('foo') }

    it 'yields the supplied block when enough requests remain' do
      expect(client).to receive(:requests_remaining?).and_return(true)

      expect { |b| client.with_rate_limit(&b) }.to yield_control
    end

    it 'waits before yielding if not enough requests remain' do
      expect(client).to receive(:requests_remaining?).and_return(false)
      expect(client).to receive(:raise_or_wait_for_rate_limit)

      expect { |b| client.with_rate_limit(&b) }.to yield_control
    end

    it 'waits and retries the operation if all requests were consumed in the supplied block' do
      retries = 0

      expect(client).to receive(:requests_remaining?).and_return(true)
      expect(client).to receive(:raise_or_wait_for_rate_limit)

      client.with_rate_limit do
        if retries == 0
          retries += 1
          raise(Octokit::TooManyRequests)
        end
      end

      expect(retries).to eq(1)
    end

    it 'increments the request count counter' do
      expect(client.request_count_counter)
        .to receive(:increment)
        .and_call_original

      expect(client).to receive(:requests_remaining?).and_return(true)

      client.with_rate_limit { }
    end

    it 'ignores rate limiting when disabled' do
      expect(client)
        .to receive(:rate_limiting_enabled?)
        .and_return(false)

      expect(client)
        .not_to receive(:requests_remaining?)

      expect(client.with_rate_limit { 10 }).to eq(10)
    end
  end

  describe '#requests_remaining?' do
    let(:client) { described_class.new('foo') }

    context 'when default requests limit is set' do
      before do
        allow(client).to receive(:requests_limit).and_return(5000)
      end

      it 'returns true if enough requests remain' do
        expect(client).to receive(:remaining_requests).and_return(9000)

        expect(client.requests_remaining?).to eq(true)
      end

      it 'returns false if not enough requests remain' do
        expect(client).to receive(:remaining_requests).and_return(1)

        expect(client.requests_remaining?).to eq(false)
      end
    end

    context 'when search requests limit is set' do
      before do
        allow(client).to receive(:requests_limit).and_return(described_class::SEARCH_MAX_REQUESTS_PER_MINUTE)
      end

      it 'returns true if enough requests remain' do
        expect(client).to receive(:remaining_requests).and_return(described_class::SEARCH_RATE_LIMIT_THRESHOLD + 1)

        expect(client.requests_remaining?).to eq(true)
      end

      it 'returns false if not enough requests remain' do
        expect(client).to receive(:remaining_requests).and_return(described_class::SEARCH_RATE_LIMIT_THRESHOLD - 1)

        expect(client.requests_remaining?).to eq(false)
      end
    end
  end

  describe '#raise_or_wait_for_rate_limit' do
    it 'raises RateLimitError when running in parallel mode' do
      client = described_class.new('foo', parallel: true)

      expect { client.raise_or_wait_for_rate_limit }
        .to raise_error(Gitlab::GithubImport::RateLimitError)
    end

    it 'sleeps when running in sequential mode' do
      client = described_class.new('foo', parallel: false)

      expect(client).to receive(:rate_limit_resets_in).and_return(1)
      expect(client).to receive(:sleep).with(1)

      client.raise_or_wait_for_rate_limit
    end

    it 'increments the rate limit counter' do
      client = described_class.new('foo', parallel: false)

      expect(client)
        .to receive(:rate_limit_resets_in)
        .and_return(1)

      expect(client)
        .to receive(:sleep)
        .with(1)

      expect(client.rate_limit_counter)
        .to receive(:increment)
        .and_call_original

      client.raise_or_wait_for_rate_limit
    end
  end

  describe '#remaining_requests' do
    it 'returns the number of remaining requests' do
      client = described_class.new('foo')
      rate_limit = double(remaining: 1)

      expect(client.octokit).to receive(:rate_limit).and_return(rate_limit)
      expect(client.remaining_requests).to eq(1)
    end
  end

  describe '#requests_limit' do
    it 'returns requests limit' do
      client = described_class.new('foo')
      rate_limit = double(limit: 1)

      expect(client.octokit).to receive(:rate_limit).and_return(rate_limit)
      expect(client.requests_limit).to eq(1)
    end
  end

  describe '#rate_limit_resets_in' do
    it 'returns the number of seconds after which the rate limit is reset' do
      client = described_class.new('foo')
      rate_limit = double(resets_in: 1)

      expect(client.octokit).to receive(:rate_limit).and_return(rate_limit)

      expect(client.rate_limit_resets_in).to eq(6)
    end
  end

  describe '#api_endpoint' do
    let(:client) { described_class.new('foo') }

    context 'without a custom endpoint configured in Omniauth' do
      it 'returns the default API endpoint' do
        expect(client)
          .to receive(:custom_api_endpoint)
          .and_return(nil)

        expect(client.api_endpoint).to eq('https://api.github.com')
      end
    end

    context 'with a custom endpoint configured in Omniauth' do
      it 'returns the custom endpoint' do
        endpoint = 'https://github.kittens.com'

        expect(client)
          .to receive(:custom_api_endpoint)
          .and_return(endpoint)

        expect(client.api_endpoint).to eq(endpoint)
      end
    end
  end

  describe '#web_endpoint' do
    let(:client) { described_class.new('foo') }

    context 'without a custom endpoint configured in Omniauth' do
      it 'returns the default web endpoint' do
        expect(client)
          .to receive(:custom_api_endpoint)
          .and_return(nil)

        expect(client.web_endpoint).to eq('https://github.com')
      end
    end

    context 'with a custom endpoint configured in Omniauth' do
      it 'returns the custom endpoint' do
        endpoint = 'https://github.kittens.com'

        expect(client)
          .to receive(:custom_api_endpoint)
          .and_return(endpoint)

        expect(client.web_endpoint).to eq(endpoint)
      end
    end
  end

  describe '#custom_api_endpoint' do
    let(:client) { described_class.new('foo') }

    context 'without a custom endpoint' do
      it 'returns nil' do
        expect(client)
          .to receive(:github_omniauth_provider)
          .and_return({})

        expect(client.custom_api_endpoint).to be_nil
      end
    end

    context 'with a custom endpoint' do
      it 'returns the API endpoint' do
        endpoint = 'https://github.kittens.com'

        expect(client)
          .to receive(:github_omniauth_provider)
          .and_return({ 'args' => { 'client_options' => { 'site' => endpoint } } })

        expect(client.custom_api_endpoint).to eq(endpoint)
      end
    end
  end

  describe '#default_api_endpoint' do
    it 'returns the default API endpoint' do
      client = described_class.new('foo')

      expect(client.default_api_endpoint).to eq('https://api.github.com')
    end
  end

  describe '#verify_ssl' do
    let(:client) { described_class.new('foo') }

    context 'without a custom configuration' do
      it 'returns true' do
        expect(client)
          .to receive(:github_omniauth_provider)
          .and_return({})

        expect(client.verify_ssl).to eq(true)
      end
    end

    context 'with a custom configuration' do
      it 'returns the configured value' do
        expect(client.verify_ssl).to eq(false)
      end
    end
  end

  describe '#github_omniauth_provider' do
    let(:client) { described_class.new('foo') }

    context 'without a configured provider' do
      it 'returns an empty Hash' do
        expect(Gitlab.config.omniauth)
          .to receive(:providers)
          .and_return([])

        expect(client.github_omniauth_provider).to eq({})
      end
    end

    context 'with a configured provider' do
      it 'returns the provider details as a Hash' do
        hash = client.github_omniauth_provider

        expect(hash['name']).to eq('github')
        expect(hash['url']).to eq('https://github.com/')
      end
    end
  end

  describe '#rate_limiting_enabled?' do
    let(:client) { described_class.new('foo') }

    it 'returns true when using GitHub.com' do
      expect(client.rate_limiting_enabled?).to eq(true)
    end

    it 'returns false for GitHub enterprise installations' do
      expect(client)
        .to receive(:api_endpoint)
        .and_return('https://github.kittens.com/')

      expect(client.rate_limiting_enabled?).to eq(false)
    end
  end

  describe 'search' do
    let(:client) { described_class.new('foo') }
    let(:user) { double(:user, login: 'user') }
    let(:org1) { double(:org, login: 'org1') }
    let(:org2) { double(:org, login: 'org2') }
    let(:repo1) { double(:repo, full_name: 'repo1') }
    let(:repo2) { double(:repo, full_name: 'repo2') }

    before do
      allow(client)
        .to receive(:each_object)
        .with(:repos, nil, { affiliation: 'collaborator' })
        .and_return([repo1, repo2].to_enum)

      allow(client)
        .to receive(:each_object)
        .with(:organizations)
        .and_return([org1, org2].to_enum)

      allow(client.octokit).to receive(:user).and_return(user)
    end

    describe '#search_repos_by_name' do
      it 'searches for repositories based on name' do
        expected_search_query = 'test in:name is:public,private user:user repo:repo1 repo:repo2 org:org1 org:org2'

        expect(client.octokit).to receive(:search_repositories).with(expected_search_query, {})

        client.search_repos_by_name('test')
      end
    end

    describe '#search_query' do
      it 'returns base search query' do
        result = client.search_query(str: 'test', type: :test, include_collaborations: false, include_orgs: false)

        expect(result).to eq('test in:test is:public,private user:user')
      end

      context 'when include_collaborations is true' do
        it 'returns search query including users' do
          result = client.search_query(str: 'test', type: :test, include_collaborations: true, include_orgs: false)

          expect(result).to eq('test in:test is:public,private user:user repo:repo1 repo:repo2')
        end
      end

      context 'when include_orgs is true' do
        it 'returns search query including users' do
          result = client.search_query(str: 'test', type: :test, include_collaborations: false, include_orgs: true)

          expect(result).to eq('test in:test is:public,private user:user org:org1 org:org2')
        end
      end
    end
  end
end
