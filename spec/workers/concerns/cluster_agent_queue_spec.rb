# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ClusterAgentQueue do
  let(:worker) do
    Class.new do
      def self.name
        'ExampleWorker'
      end

      include ApplicationWorker
      include ClusterAgentQueue
    end
  end

  it { expect(worker.get_feature_category).to eq(:kubernetes_management) }
end
