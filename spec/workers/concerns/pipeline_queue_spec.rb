require 'spec_helper'

describe PipelineQueue do
  let(:worker) do
    Class.new do
      def self.name
        'DummyWorker'
      end

      include ApplicationWorker
      include PipelineQueue
    end
  end

  it 'sets a default pipelines queue automatically' do
    expect(worker.sidekiq_options['queue'])
      .to eq 'pipeline_default:dummy'
  end
end
