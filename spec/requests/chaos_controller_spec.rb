# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ChaosController, type: :request, feature_category: :tooling do
  it_behaves_like 'Base action controller' do
    before do
      # Stub leak_mem so we don't actually leak memory for the base action controller tests.
      allow(Gitlab::Chaos).to receive(:leak_mem).with(100, 30.seconds)
    end

    subject(:request) { get leakmem_chaos_path }
  end
end
