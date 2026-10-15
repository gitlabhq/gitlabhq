# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::RackLoadBalancingHelpers, feature_category: :database do
  let(:env) { {} }
  let(:helper) do
    Class.new do
      include Gitlab::RackLoadBalancingHelpers

      attr_reader :request

      def initialize(request)
        @request = request
      end
    end.new(instance_double(Rack::Request, env: env))
  end

  let(:sticking) { ::Ci::Build.sticking }
  let(:stick_object_key) { ::Gitlab::Database::LoadBalancing::RackMiddleware::STICK_OBJECT }

  describe '#load_balancer_stick_request' do
    it 'adds the entry and looks it up', :aggregate_failures do
      expect(sticking).to receive(:find_caught_up_replica).with(:build, '42', hash_id: false).and_return(true)

      expect(helper.load_balancer_stick_request(::Ci::Build, :build, '42')).to be(true)
      expect(env[stick_object_key]).to contain_exactly([sticking, :build, '42'])
    end

    it 'looks up each entry once per request' do
      expect(sticking).to receive(:find_caught_up_replica).with(:build, '42', hash_id: false).once
      expect(sticking).to receive(:find_caught_up_replica).with(:build, '43', hash_id: false).once

      2.times do
        helper.load_balancer_stick_request(::Ci::Build, :build, '42')
        helper.load_balancer_stick_request(::Ci::Build, :build, '43')
      end
    end

    it 'skips an entry that RackMiddleware already looked up' do
      env[stick_object_key] = Set[[sticking, :build, '42']]

      expect(sticking).not_to receive(:find_caught_up_replica)

      helper.load_balancer_stick_request(::Ci::Build, :build, '42')
    end
  end
end
