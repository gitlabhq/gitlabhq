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

      context 'when teardown job has environment defined' do
        context 'when teardown job has invalid environment name' do
          let(:config) do
            { deploy: {
                script: 'rspec',
                environment: {
                  name: 'test',
                  on_stop: 'teardown'
                }
              },

              teardown: {
                script: 'echo teardown',
                environment: 'staging'
              }
            }
          end

          it 'adds errors about invalid environment name' do
            expect(global.errors)
              .to include 'jobs:teardown:environment name does not match ' \
                          'environment name defined in `deploy` job'
          end
        end

        context 'when teardown job has valid environment name' do
          context 'when teardown has invalid action name' do
            let(:config) do
              { deploy: {
                  script: 'rspec',
                  environment: {
                    name: 'test',
                    on_stop: 'teardown'
                  }
                },

                teardown: {
                  script: 'echo teardown',
                  environment: {
                    name: 'test',
                    action: 'start'
                  }
                }
              }
            end

            it 'adds error about invalid action name' do
              expect(global.errors)
                .to include 'jobs:teardown:environment action should be ' \
                            'defined as `stop`'
            end
          end

          context 'when teardown job has valid action name' do
            let(:config) do
              { deploy: {
                  script: 'rspec',
                  environment: {
                    name: 'test',
                    on_stop: 'teardown'
                  }
                },

                teardown: {
                  script: 'echo teardown',
                  environment: {
                    name: 'test',
                    action: 'stop'
                  }
                }
              }
            end

            it 'does not invalidate configuration' do
              expect(global).to be_valid
            end
          end
        end
      end
    end
  end
end
