require 'spec_helper'

describe Gitlab::Ci::Config::Node::Job do
  let(:entry) { described_class.new(config, global: global) }
  let(:global) { spy('Global') }

  before do
    entry.process!
    entry.validate!
  end

  describe 'validations' do
    context 'when entry config value is correct' do
      let(:config) { { script: 'rspec' } }

      describe '#valid?' do
        it 'is valid' do
          expect(entry).to be_valid
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
    end
  end

  describe '#value' do
    context 'when entry is correct' do
      let(:config) do
        { before_script: %w[ls pwd],
          script: 'rspec',
          after_script: %w[cleanup] }
      end

      it 'returns correct value' do
        expect(entry.value)
          .to eq(before_script: %w[ls pwd],
                 script: %w[rspec],
                 commands: "ls\npwd\nrspec",
                 stage: 'test',
                 after_script: %w[cleanup])
      end
    end
  end

  describe '#before_script' do
    context 'when global entry has before script' do
      before do
        allow(global).to receive(:before_script)
          .and_return(%w[ls pwd])
      end

      context 'when before script is overridden' do
        let(:config) do
          { before_script: %w[whoami],
            script: 'rspec' }
        end

        it 'returns correct script' do
          expect(entry.before_script).to eq %w[whoami]
        end
      end

      context 'when before script is not overriden' do
        let(:config) do
          { script: %w[spinach] }
        end

        it 'returns correct script' do
          expect(entry.before_script).to eq %w[ls pwd]
        end
      end
    end

    context 'when global entry does not have before script' do
      before do
        allow(global).to receive(:before_script)
          .and_return(nil)
      end

      context 'when job has before script' do
        let(:config) do
          { before_script: %w[whoami],
            script: 'rspec' }
        end

        it 'returns correct script' do
          expect(entry.before_script).to eq %w[whoami]
        end
      end

      context 'when job does not have before script' do
        let(:config) do
          { script: %w[ls test] }
        end

        it 'returns correct script' do
          expect(entry.before_script).to be_nil
        end
      end
    end
  end

  describe '#relevant?' do
    it 'is a relevant entry' do
      expect(entry).to be_relevant
    end
  end

  describe '#commands' do
    context 'when global entry has before script' do
      before do
        allow(global).to receive(:before_script)
          .and_return(%w[ls pwd])
      end

      context 'when before script is overridden' do
        let(:config) do
          { before_script: %w[whoami],
            script: 'rspec' }
        end

        it 'returns correct commands' do
          expect(entry.commands).to eq "whoami\nrspec"
        end
      end

      context 'when before script is not overriden' do
        let(:config) do
          { script: %w[rspec spinach] }
        end

        it 'returns correct commands' do
          expect(entry.commands).to eq "ls\npwd\nrspec\nspinach"
        end
      end
    end

    context 'when global entry does not have before script' do
      before do
        allow(global).to receive(:before_script)
          .and_return(nil)
      end
      context 'when job has before script' do
        let(:config) do
          { before_script: %w[whoami],
            script: 'rspec' }
        end

        it 'returns correct commands' do
          expect(entry.commands).to eq "whoami\nrspec"
        end
      end

      context 'when job does not have before script' do
        let(:config) do
          { script: %w[ls test] }
        end

        it 'returns correct commands' do
          expect(entry.commands).to eq "ls\ntest"
        end
      end
    end
  end
end
