require 'spec_helper'

describe Gitlab::Ci::Config::Rule::Environments do
  let(:rule) { described_class.new(job, global) }
  let(:job) { global[:jobs][:deploy] }

  let(:global) do
    # We may need factory for that
    #
    Gitlab::Ci::Config::Node::Global.new(config)
  end

  before do
    # We will phase public `.compose!` out
    #
    global.compose!
    rule.apply!
  end

  context 'when environment is stoppable' do
    context 'when teardown job is not defined' do
      let(:config) do
        { deploy: {
            script: 'rspec',
            environment: {
              name: 'test',
              on_stop: 'teardown_job'
            }
          }
        }
      end

      it 'adds error about missing on stop job' do
        expect(global.errors)
          .to include 'jobs:deploy:environment on stop job not defined'
      end
    end

    context 'when teardown job is defined' do
      context 'when teardown job does not have environment defined' do
        let(:config) do
          { deploy: {
              script: 'rspec',
              environment: {
                name: 'test',
                on_stop: 'teardown'
              }
            },

            teardown: {
              script: 'echo teardown'
            }
          }
        end

        it 'adds error about incomplete teardown job' do
          expect(global.errors)
            .to include 'jobs:teardown environment not defined'
        end
      end

      context 'when teardown job is defined' do
      end
    end
  end

  def define_config(hash)
    Gitlab::Ci::Config::Node::Global.new(hash)
  end
end
