# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BatchWorkerContext do
  subject(:batch_context) do
    described_class.new(
      %w[hello world],
      arguments_proc: ->(word) { word },
      context_proc: ->(word) { { user: build_stubbed(:user, username: word) } }
    )
  end

  describe "#arguments" do
    it "returns all the expected arguments in arrays" do
      expect(batch_context.arguments).to eq([%w[hello], %w[world]])
    end
  end

  describe "#context_for" do
    it "returns the correct application context for the arguments" do
      context = batch_context.context_for(%w[world])

      expect(context).to be_a(Gitlab::ApplicationContext)
      expect(context.to_lazy_hash[:user].call).to eq("world")
    end
  end
end
