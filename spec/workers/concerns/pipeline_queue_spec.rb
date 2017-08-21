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
      .to eq 'pipelines-default'
  end

  describe '.enqueue_in' do
    it 'sets a custom sidekiq queue with prefix, name and group' do
      worker.enqueue_in(queue: :build, group: :processing)

      expect(worker.sidekiq_options['queue'])
        .to eq 'pipelines-build-processing'
    end
  end
end
