# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::GrapeLogging::Loggers::UrgencyLogger do
  def endpoint(options, namespace: '')
    Struct.new(:options, :namespace).new(options, namespace)
  end

  let(:api_class) do
    Class.new(API::Base) do
      namespace 'testing' do
        # rubocop:disable Rails/HttpPositionalArguments
        # This is not the get that performs a request, but the one from Grape
        get 'test', urgency: :high do
          {}
        end
        # rubocop:enable Rails/HttpPositionalArguments
      end
    end
  end

  describe ".parameters" do
    where(:request_env, :expected_parameters) do
      [
        [{}, {}],
        [{ 'api.endpoint' => endpoint({}) }, {}],
        [{ 'api.endpoint' => endpoint({ for: 'something weird' }) }, {}],
        [
          { 'api.endpoint' => endpoint({ for: api_class, path: [] }) },
          { request_urgency: :default, target_duration_s: 1 }
        ],
        [
          { 'api.endpoint' => endpoint({ for: api_class, path: ['test'] }, namespace: '/testing') },
          { request_urgency: :high, target_duration_s: 0.25 }
        ]
      ]
    end

    with_them do
      let(:request) { double('request', env: request_env) }

      subject { described_class.new.parameters(request, nil) }

      it { is_expected.to eq(expected_parameters) }
    end
  end
end
