require 'spec_helper'

describe Gitlab::Ci::Config::Rule::Environments do
  let(:rule) { described_class.new(job, config) }

  before do
    config.compose!
    rule.apply!
  end

  context 'when `on_stop` setting is defined' do
    context 'when teardown job is not defined' do
      let(:job) { config[:jobs][:deploy] }

      let(:config) do
        define_config(
          deploy: {
            script: 'rspec',
            environment: {
              name: 'test',
              on_stop: 'teardown_job'
            }
          }
        )
      end

      it 'invalidates environment that depends on `on_stop`' do
        expect(config.errors)
          .to include 'jobs:deploy:environment on stop job not defined'
      end
    end
  end

  def define_config(hash)
    Gitlab::Ci::Config::Node::Global.new(hash)
  end
end
