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
    stub_const("Gitlab::Octokit::ResponseValidation::MAX_ALLOWED_OBJECTS", 100)
  end

  context 'when there are many objects in an array' do
    let(:values) do
      Array.new(100) { "values" }
    end

    it 'raises a ResponseSizeTooLarge error' do
      expect { on_complete }.to raise_error(Gitlab::Octokit::ResponseValidation::ResponseSizeTooLarge)
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
    let(:response) { { data: 'a' * 50.kilobytes }.to_json }

    before do
      stub_const("Gitlab::Octokit::ResponseValidation::MAX_ALLOWED_BYTES", 50.kilobytes)
    end

    it 'raises a ResponseSizeTooLarge error' do
      expect { on_complete }.to raise_error(Gitlab::Octokit::ResponseValidation::ResponseSizeTooLarge)
    end
  end

  context 'when the response size in bytes is not too big' do
    let(:response) { { data: 'a' * 40.kilobytes }.to_json }

    before do
      stub_const("Gitlab::Octokit::ResponseValidation::MAX_ALLOWED_BYTES", 50.kilobytes)
    end

    it 'does not raises a ResponseSizeTooLarge error' do
      expect { middleware.on_complete(env) }.not_to raise_error
    end
  end

  context 'when the response is not json' do
    let(:response) { '<html><body>Hello World</body></html>' }

    it 'reports a JSON::ParseError instead of raising it' do
      expect(Gitlab::ErrorTracking).to receive(:track_and_raise_for_dev_exception).with(kind_of(JSON::ParserError))

      expect { middleware.on_complete(env) }.not_to raise_error
    end
  end
end
