require 'spec_helper'

describe PipelineQueue do
  let(:worker) do
    Class.new do
      include Sidekiq::Worker
      include PipelineQueue
    end
  end

  it 'sets a default pipelines queue automatically' do
    expect(worker.sidekiq_options['queue'])
      .to eq 'pipeline_default'
  end

  describe '.enqueue_in' do
    it 'sets a custom sidekiq queue with prefix and group' do
      worker.enqueue_in(group: :processing)

      expect(worker.sidekiq_options['queue'])
        .to eq 'pipeline_processing'
    end
  end
end
