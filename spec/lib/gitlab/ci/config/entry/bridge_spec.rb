# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Config::Entry::Bridge, feature_category: :continuous_integration do
  subject(:entry) { described_class.new(config, name: :my_bridge) }

  it_behaves_like 'with inheritable CI config' do
    let(:config) { { trigger: 'some/project' } }
    let(:inheritable_key) { 'default' }
    let(:inheritable_class) { Gitlab::Ci::Config::Entry::Default }

    # These are entries defined in Default
    # that we know that we don't want to inherit
    # as they do not have sense in context of Bridge
    let(:ignored_inheritable_columns) do
      %i[before_script after_script hooks image services cache timeout
         retry tags artifacts id_tokens]
    end

    before do
      allow(entry).to receive_message_chain(:inherit_entry, :default_entry, :inherit?).and_return(true)
    end
  end

  describe '.visible?' do
    it 'always returns true' do
      expect(described_class.visible?).to be_truthy
    end
  end

  describe '.matching?' do
    subject { described_class.matching?(name, config) }

    context 'when config is not a hash' do
      let(:name) { :my_trigger }
      let(:config) { 'string' }

      it { is_expected.to be_falsey }
    end

    context 'when config is a regular job' do
      let(:name) { :my_trigger }
      let(:config) do
        { script: 'ls -al' }
      end

      it { is_expected.to be_falsey }

      context 'with rules' do
        let(:config) do
          {
            script: 'ls -al',
            rules: [{ if: '$VAR == "value"', when: 'always' }]
          }
        end

        it { is_expected.to be_falsey }
      end
    end

    context 'when config is a bridge job' do
      let(:name) { :my_trigger }
      let(:config) do
        { trigger: 'other-project' }
      end

      it { is_expected.to be_truthy }

      context 'with rules' do
        let(:config) do
          {
            trigger: 'other-project',
            rules: [{ if: '$VAR == "value"', when: 'always' }]
          }
        end

        it { is_expected.to be_truthy }
      end
    end

    context 'when config is a hidden job' do
      let(:name) { '.my_trigger' }
      let(:config) do
        { trigger: 'other-project' }
      end

      it { is_expected.to be_falsey }
    end
  end

  describe '.new' do
    before do
      subject.compose!
    end

    let(:base_config) do
      {
        trigger: { project: 'some/project', branch: 'feature' },
        extends: '.some-key',
        stage: 'deploy',
        variables: { VARIABLE: '123' }
      }
    end

    context 'when trigger config is a non-empty string' do
      let(:config) { { trigger: 'some/project' } }

      describe '#valid?' do
        it { is_expected.to be_valid }
      end

      describe '#value' do
        it 'is returns a bridge job configuration' do
          expect(subject.value).to eq(
            name: :my_bridge,
            trigger: { project: 'some/project' },
            ignore: false,
            stage: 'test',
            only: { refs: %w[branches tags] },
            job_variables: {},
            root_variables_inheritance: true,
            scheduling_type: :stage
          )
        end
      end
    end

    context 'when bridge trigger is a hash' do
      let(:config) do
        { trigger: { project: 'some/project', branch: 'feature' } }
      end

      describe '#valid?' do
        it { is_expected.to be_valid }
      end

      describe '#value' do
        it 'is returns a bridge job configuration hash' do
          expect(subject.value).to eq(
            name: :my_bridge,
            trigger: { project: 'some/project', branch: 'feature' },
            ignore: false,
            stage: 'test',
            only: { refs: %w[branches tags] },
            job_variables: {},
            root_variables_inheritance: true,
            scheduling_type: :stage
          )
        end
      end
    end

    context 'when bridge configuration contains trigger, when, extends, stage, only, except, and variables' do
      let(:config) do
        base_config.merge({
          when: 'always',
          only: { variables: %w[$SOMEVARIABLE] },
          except: { refs: %w[feature] }
        })
      end

      it { is_expected.to be_valid }
    end

    context 'when bridge configuration uses rules' do
      let(:config) { base_config.merge({ rules: [{ if: '$VAR == null', when: 'never' }] }) }

      it { is_expected.to be_valid }
    end

    context 'when bridge configuration uses rules with job:when' do
      let(:config) do
        base_config.merge({
          when: 'always',
          rules: [{ if: '$VAR == null', when: 'never' }]
        })
      end

      it { is_expected.to be_valid }
    end

    context 'when bridge configuration uses rules with only' do
      let(:config) do
        base_config.merge({
          only: { variables: %w[$SOMEVARIABLE] },
          rules: [{ if: '$VAR == null', when: 'never' }]
        })
      end

      it { is_expected.not_to be_valid }
    end

    context 'when bridge configuration uses rules with except' do
      let(:config) do
        base_config.merge({
          except: { refs: %w[feature] },
          rules: [{ if: '$VAR == null', when: 'never' }]
        })
      end

      it { is_expected.not_to be_valid }
    end

    context 'when bridge has only job needs' do
      let(:config) do
        {
          needs: ['some_job']
        }
      end

      describe '#valid?' do
        it { is_expected.not_to be_valid }
      end
    end

    context 'when bridge config contains unknown keys' do
      let(:config) { { unknown: 123 } }

      describe '#valid?' do
        it { is_expected.not_to be_valid }
      end

      describe '#errors' do
        it 'is returns an error about unknown config key' do
          expect(subject.errors.first)
            .to match(/config contains unknown keys: unknown/)
        end
      end
    end

    context 'when bridge config contains build-specific attributes' do
      let(:config) { { script: 'something' } }

      describe '#valid?' do
        it { is_expected.not_to be_valid }
      end

      describe '#errors' do
        it 'returns an error message' do
          expect(subject.errors.first)
            .to match(/contains unknown keys: script/)
        end
      end
    end

    context 'when bridge config contains exit_codes' do
      let(:config) do
        { script: 'rspec', allow_failure: { exit_codes: [42] } }
      end

      describe '#valid?' do
        it { is_expected.not_to be_valid }
      end

      describe '#errors' do
        it 'returns an error message' do
          expect(subject.errors)
            .to include(/allow failure should be a boolean value/)
        end
      end
    end

    context 'when bridge config contains parallel' do
      let(:config) { { trigger: 'some/project', parallel: parallel_config } }

      context 'when parallel config is a number' do
        let(:parallel_config) { 2 }

        describe '#valid?' do
          it { is_expected.not_to be_valid }
        end

        describe '#errors' do
          it 'returns an error message' do
            expect(subject.errors)
              .to include(/cannot use "parallel: <number>"/)
          end
        end
      end

      context 'when parallel config is a matrix' do
        let(:parallel_config) do
          { matrix: [{ PROVIDER: 'aws', STACK: %w[monitoring app1] },
                     { PROVIDER: 'gcp', STACK: %w[data] }] }
        end

        describe '#valid?' do
          it { is_expected.to be_valid }
        end

        describe '#value' do
          it 'is returns a bridge job configuration' do
            expect(subject.value).to eq(
              name: :my_bridge,
              trigger: { project: 'some/project' },
              ignore: false,
              stage: 'test',
              only: { refs: %w[branches tags] },
              parallel: { matrix: [{ 'PROVIDER' => ['aws'], 'STACK' => %w[monitoring app1] },
                                   { 'PROVIDER' => ['gcp'], 'STACK' => %w[data] }] },
              job_variables: {},
              root_variables_inheritance: true,
              scheduling_type: :stage
            )
          end
        end
      end
    end

    context 'when bridge trigger contains forward' do
      let(:config) do
        { trigger: { project: 'some/project', forward: { pipeline_variables: true } } }
      end

      describe '#valid?' do
        it { is_expected.to be_valid }
      end

      describe '#value' do
        it 'returns a bridge job configuration hash' do
          expect(subject.value).to eq(
            name: :my_bridge,
            trigger: { project: 'some/project', forward: { pipeline_variables: true } },
            ignore: false,
            stage: 'test',
            only: { refs: %w[branches tags] },
            job_variables: {},
            root_variables_inheritance: true,
            scheduling_type: :stage
          )
        end
      end
    end
  end

  describe '#manual_action?' do
    context 'when job is a manual action' do
      let(:config) { { script: 'deploy', when: 'manual' } }

      it { is_expected.to be_manual_action }
    end

    context 'when job is not a manual action' do
      let(:config) { { script: 'deploy' } }

      it { is_expected.not_to be_manual_action }
    end
  end

  describe '#ignored?' do
    context 'when job is a manual action' do
      context 'when it is not specified if job is allowed to fail' do
        let(:config) do
          { script: 'deploy', when: 'manual' }
        end

        it { is_expected.to be_ignored }
      end

      context 'when job is allowed to fail' do
        let(:config) do
          { script: 'deploy', when: 'manual', allow_failure: true }
        end

        it { is_expected.to be_ignored }
      end

      context 'when job is not allowed to fail' do
        let(:config) do
          { script: 'deploy', when: 'manual', allow_failure: false }
        end

        it { is_expected.not_to be_ignored }
      end
    end

    context 'when job is not a manual action' do
      context 'when it is not specified if job is allowed to fail' do
        let(:config) { { script: 'deploy' } }

        it { is_expected.not_to be_ignored }
      end

      context 'when job is allowed to fail' do
        let(:config) { { script: 'deploy', allow_failure: true } }

        it { is_expected.to be_ignored }
      end

      context 'when job is not allowed to fail' do
        let(:config) { { script: 'deploy', allow_failure: false } }

        it { is_expected.not_to be_ignored }
      end
    end
  end

  describe '#when' do
    context 'when bridge is a manual action' do
      let(:config) { { script: 'deploy', when: 'manual' } }

      it { expect(entry.when).to eq('manual') }
    end

    context 'when bridge has no `when` attribute' do
      let(:config) { { script: 'deploy' } }

      it { expect(entry.when).to be_nil }
    end

    context 'when the `when` keyword is not a string' do
      context 'when it is an array' do
        let(:config) { { script: 'exit 0', when: ['always'] } }

        it 'returns error' do
          expect(entry).not_to be_valid
          expect(entry.errors).to include 'bridge when should be a string'
        end
      end

      context 'when it is a boolean' do
        let(:config) { { script: 'exit 0', when: true } }

        it 'returns error' do
          expect(entry).not_to be_valid
          expect(entry.errors).to include 'bridge when should be a string'
        end
      end
    end
  end
end
