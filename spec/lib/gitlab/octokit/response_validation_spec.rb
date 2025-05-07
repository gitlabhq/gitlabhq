# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Octokit::ResponseValidation, feature_category: :importers do
  subject(:on_complete) { middleware.on_complete(env) }

  let(:app) { instance_double(Octokit::Response::RaiseError) }

  let(:middleware) { described_class.new(app) }
  let(:env) { Rack::MockRequest.new(app) }
  let(:response) { { some: { nested: { values: values } } }.to_json }

  before do
    allow(env).to receive_message_chain(:response, :body).and_return(response)
    allow(env).to receive(:url).and_return(URI("https://api.githubinstance.com/gitlabhq/gitlabhq/pulls"))
    allow(Gitlab::CurrentSettings).to receive(:max_github_response_json_value_count).and_return(100)
  end

  context 'when there are many objects in an array' do
    let(:values) do
      Array.new(100) { "values" }
    end

    it 'raises a ResponseSizeTooLarge error' do
      expect { on_complete }.to raise_error(Gitlab::Octokit::ResponseValidation::ResponseSizeTooLarge)
    end

    context 'when the host is api.github.com' do
      before do
        allow(env).to receive(:url).and_return(URI("https://api.github.com/gitlabhq/gitlabhq/pulls"))
      end

      it 'does not raises an error' do
        expect { middleware.on_complete(env) }.not_to raise_error
      end
    end
  end

  context 'when there are many objects in a hash' do
    let(:values) do
      hash = {}
      100.times do |i|
        hash[i.to_s] = "value"
      end
      hash
    end

    it 'raises a ResponseSizeTooLarge error' do
      expect { on_complete }.to raise_error(Gitlab::Octokit::ResponseValidation::ResponseSizeTooLarge)
    end
  end

  context 'when there is a deeply nested hash' do
    let(:values) do
      hash = { a: {} }

      child_hash = hash

      100.times do
        child_hash[:a] = { a: {} }
        child_hash = child_hash[:a]
      end

      hash
    end

    it 'raises a ResponseSizeTooLarge error' do
      expect { on_complete }.to raise_error(Gitlab::Octokit::ResponseValidation::ResponseSizeTooLarge)
    end
  end

  context 'when there are not many objects' do
    let(:values) do
      Array.new(20) { "value" }
    end

    it 'does not raises a ResponseSizeTooLarge error' do
      expect { middleware.on_complete(env) }.not_to raise_error
    end
  end

  context 'when the response is empty' do
    let(:response) { '' }

    it 'does not raises an error' do
      expect { middleware.on_complete(env) }.not_to raise_error
    end
  end

  context 'when the response size in bytes is too big' do
    let(:response) { { data: 'a' * 1.megabyte }.to_json }

    before do
      allow(Gitlab::CurrentSettings).to receive(:max_github_response_size_limit).and_return(1)
    end

    it 'raises a ResponseSizeTooLarge error' do
      expect { on_complete }.to raise_error(Gitlab::Octokit::ResponseValidation::ResponseSizeTooLarge)
    end
  end

  context 'when the response size in bytes is not too big' do
    let(:response) { { data: 'a' * 900.kilobytes }.to_json }

    before do
      allow(Gitlab::CurrentSettings).to receive(:max_github_response_size_limit).and_return(1)
    end

    it 'does not raises a ResponseSizeTooLarge error' do
      expect { middleware.on_complete(env) }.not_to raise_error
    end
  end

  context 'when max_github_response_size_limit is set to 0' do
    let(:response) { { data: 'a' * 900.kilobytes }.to_json }

    before do
      allow(Gitlab::CurrentSettings).to receive(:max_github_response_size_limit).and_return(0)
    end

    it 'does not raises a ResponseSizeTooLarge error' do
      expect { middleware.on_complete(env) }.not_to raise_error
    end
  end

  context 'when max_github_response_json_value_count is set to 0' do
    let(:response) { { data: { z: 'a', y: 'b' } }.to_json }

    before do
      allow(Gitlab::CurrentSettings).to receive(:max_github_response_json_value_count).and_return(0)
    end

    it 'does not raises a ResponseSizeTooLarge error' do
      expect { middleware.on_complete(env) }.not_to raise_error
    end
  end
end
