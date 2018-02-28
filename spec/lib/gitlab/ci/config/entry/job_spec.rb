require 'spec_helper'

describe Gitlab::Ci::Config::Entry::Job do
  let(:entry) { described_class.new(config, name: :rspec) }

  describe '.nodes' do
    context 'when filtering all the entry/node names' do
      subject { described_class.nodes.keys }

      let(:result) do
        %i[before_script script stage type after_script cache
           image services only except variables artifacts
           environment coverage]
      end

      it { is_expected.to match_array result }
    end
  end

  describe 'validations' do
    before do
      entry.compose!
    end

    context 'when entry config value is correct' do
      let(:config) { { script: 'rspec' } }

      describe '#valid?' do
        it 'is valid' do
          expect(entry).to be_valid
        end
      end

      context 'when job name is empty' do
        let(:entry) { described_class.new(config, name: ''.to_sym) }

        it 'reports error' do
          expect(entry.errors).to include "job name can't be blank"
        end
      end
    end

    context 'when entry value is not correct' do
      context 'incorrect config value type' do
        let(:config) { ['incorrect'] }

        describe '#errors' do
          it 'reports error about a config type' do
            expect(entry.errors)
              .to include 'job config should be a hash'
          end
        end
      end

      context 'when config is empty' do
        let(:config) { {} }

        describe '#valid' do
          it 'is invalid' do
            expect(entry).not_to be_valid
          end
        end
      end

      context 'when unknown keys detected' do
        let(:config) { { unknown: true } }

        describe '#valid' do
          it 'is not valid' do
            expect(entry).not_to be_valid
          end
        end
      end

      context 'when script is not provided' do
        let(:config) { { stage: 'test' } }

        it 'returns error about missing script entry' do
          expect(entry).not_to be_valid
          expect(entry.errors).to include "job script can't be blank"
        end
      end

      context 'when retry value is not correct' do
        context 'when it is not a numeric value' do
          let(:config) { { retry: true } }

          it 'returns error about invalid type' do
            expect(entry).not_to be_valid
            expect(entry.errors).to include 'job retry is not a number'
          end
        end

        context 'when it is lower than zero' do
          let(:config) { { retry: -1 } }

          it 'returns error about value too low' do
            expect(entry).not_to be_valid
            expect(entry.errors)
              .to include 'job retry must be greater than or equal to 0'
          end
        end

        context 'when it is not an integer' do
          let(:config) { { retry: 1.5 } }

          it 'returns error about wrong value' do
            expect(entry).not_to be_valid
            expect(entry.errors).to include 'job retry must be an integer'
          end
        end

        context 'when the value is too high' do
          let(:config) { { retry: 10 } }

          it 'returns error about value too high' do
            expect(entry).not_to be_valid
            expect(entry.errors).to include 'job retry must be less than or equal to 2'
          end
        end
      end
    end
  end

  describe '#relevant?' do
    it 'is a relevant entry' do
      expect(entry).to be_relevant
    end
  end

  describe '#compose!' do
    let(:unspecified) { double('unspecified', 'specified?' => false) }

    let(:specified) do
      double('specified', 'specified?' => true, value: 'specified')
    end

    let(:deps) { double('deps', '[]' => unspecified) }

    context 'when job config overrides global config' do
      before do
        entry.compose!(deps)
      end

      let(:config) do
        { script: 'rspec', image: 'some_image', cache: { key: 'test' } }
      end

      it 'overrides global config' do
        expect(entry[:image].value).to eq(name: 'some_image')
        expect(entry[:cache].value).to eq(key: 'test', policy: 'pull-push')
      end
    end

    context 'when job config does not override global config' do
      before do
        allow(deps).to receive('[]').with(:image).and_return(specified)
        entry.compose!(deps)
      end

      let(:config) { { script: 'ls', cache: { key: 'test' } } }

      it 'uses config from global entry' do
        expect(entry[:image].value).to eq 'specified'
        expect(entry[:cache].value).to eq(key: 'test', policy: 'pull-push')
      end
    end
  end

  context 'when composed' do
    before do
      entry.compose!
    end

    describe '#value' do
      before do
        entry.compose!
      end

      context 'when entry is correct' do
        let(:config) do
          { before_script: %w[ls pwd],
            script: 'rspec',
            after_script: %w[cleanup] }
        end

        it 'returns correct value' do
          expect(entry.value)
            .to eq(name: :rspec,
                   before_script: %w[ls pwd],
                   script: %w[rspec],
                   commands: "ls\npwd\nrspec",
                   stage: 'test',
                   ignore: false,
                   after_script: %w[cleanup])
        end
      end
    end

    describe '#commands' do
      let(:config) do
        { before_script: %w[ls pwd], script: 'rspec' }
      end

      it 'returns a string of commands concatenated with new line character' do
        expect(entry.commands).to eq "ls\npwd\nrspec"
      end
    end
  end

  describe '#manual_action?' do
    context 'when job is a manual action' do
      let(:config) { { script: 'deploy', when: 'manual' } }

      it 'is a manual action' do
        expect(entry).to be_manual_action
      end
    end

    context 'when job is not a manual action' do
      let(:config) { { script: 'deploy' } }

      it 'is not a manual action' do
        expect(entry).not_to be_manual_action
      end
    end
  end

  describe '#ignored?' do
    context 'when job is a manual action' do
      context 'when it is not specified if job is allowed to fail' do
        let(:config) do
          { script: 'deploy', when: 'manual' }
        end

        it 'is an ignored job' do
          expect(entry).to be_ignored
        end
      end

      context 'when job is allowed to fail' do
        let(:config) do
          { script: 'deploy', when: 'manual', allow_failure: true }
        end

        it 'is an ignored job' do
          expect(entry).to be_ignored
        end
      end

      context 'when job is not allowed to fail' do
        let(:config) do
          { script: 'deploy', when: 'manual', allow_failure: false }
        end

        it 'is not an ignored job' do
          expect(entry).not_to be_ignored
        end
      end
    end

    context 'when job is not a manual action' do
      context 'when it is not specified if job is allowed to fail' do
        let(:config) { { script: 'deploy' } }

        it 'is not an ignored job' do
          expect(entry).not_to be_ignored
        end
      end

      context 'when job is allowed to fail' do
        let(:config) { { script: 'deploy', allow_failure: true } }

        it 'is an ignored job' do
          expect(entry).to be_ignored
        end
      end

      context 'when job is not allowed to fail' do
        let(:config) { { script: 'deploy', allow_failure: false } }

        it 'is not an ignored job' do
          expect(entry).not_to be_ignored
        end
      end
    end
  end
end
