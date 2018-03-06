require 'spec_helper'

describe PipelineBackgroundQueue do
  let(:worker) do
    Class.new do
      def self.name
        'DummyWorker'
      end

      include ApplicationWorker
      include PipelineBackgroundQueue
    end
  end

  it 'sets a default object storage queue automatically' do
    expect(worker.sidekiq_options['queue'])
      .to eq 'pipeline_background:dummy'
  end
end
