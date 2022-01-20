# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Gitlab::Metrics::Exporter::GcRequestMiddleware do
  let(:app) { double(:app) }
  let(:env) { {} }

  subject(:middleware) { described_class.new(app) }

  describe '#call' do
    it 'runs a major GC after the next middleware is called' do
      expect(app).to receive(:call).with(env).ordered.and_return([200, {}, []])
      expect(GC).to receive(:start).ordered

      response = middleware.call(env)

      expect(response).to eq([200, {}, []])
    end
  end
end
