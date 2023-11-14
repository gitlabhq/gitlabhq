# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Gitlab::Memory::Watchdog::Handlers::PumaHandler, feature_category: :cloud_connector do
  # rubocop: disable RSpec/VerifiedDoubles
  # In tests, the Puma constant is not loaded so we cannot make this an instance_double.
  let(:puma_worker_handle_class) { double('Puma::Cluster::WorkerHandle') }
  let(:puma_worker_handle) { double('worker') }
  # rubocop: enable RSpec/VerifiedDoubles

  subject(:handler) { described_class.new({}) }

  before do
    stub_const('::Puma::Cluster::WorkerHandle', puma_worker_handle_class)
    allow(puma_worker_handle_class).to receive(:new).and_return(puma_worker_handle)
    allow(puma_worker_handle).to receive(:term)
  end

  describe '#call' do
    it 'invokes orderly termination via Puma API' do
      expect(puma_worker_handle).to receive(:term)

      expect(handler.call).to be(true)
    end
  end
end
