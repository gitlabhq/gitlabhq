# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Ci::Config::Entry::Job do
  let(:entry) { described_class.new(config, name: :rspec) }

  it_behaves_like 'with inheritable CI config' do
    let(:inheritable_key) { 'default' }
    let(:inheritable_class) { Gitlab::Ci::Config::Entry::Default }

    # These are entries defined in Default
    # that we know that we don't want to inherit
    # as they do not have sense in context of Job
    let(:ignored_inheritable_columns) do
      %i[]
    end
  end

  describe '.nodes' do
    context 'when filtering all the entry/node names' do
      subject { described_class.nodes.keys }

      let(:result) do
        %i[before_script script stage type after_script cache
           image services only except rules needs variables artifacts
           environment coverage retry interruptible timeout release tags]
      end

      it { is_expected.to match_array result }
    end
  end

  describe '.matching?' do
    subject { described_class.matching?(name, config) }

    context 'when config is not a hash' do
      let(:name) { :rspec }
      let(:config) { 'string' }

      it { is_expected.to be_falsey }
    end

    context 'when config is a regular job' do
      let(:name) { :rspec }
      let(:config) do
        { script: 'ls -al' }
      end

      it { is_expected.to be_truthy }
    end

    context 'when config is a bridge job' do
      let(:name) { :rspec }
      let(:config) do
        { trigger: 'other-project' }
      end

      it { is_expected.to be_falsey }
    end

    context 'when config is a hidden job' do
      let(:name) { '.rspec' }
      let(:config) do
        { script: 'ls -al' }
      end

      it { is_expected.to be_falsey }
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

      context 'when delayed job' do
        context 'when start_in is specified' do
          let(:config) { { script: 'echo', when: 'delayed', start_in: '1 week' } }

          it { expect(entry).to be_valid }
        end
      end

      context 'when has needs' do
        let(:config) do
          {
            stage: 'test',
            script: 'echo',
            needs: ['another-job']
          }
        end

        it { expect(entry).to be_valid }

        context 'when has dependencies' do
          let(:config) do
            {
              stage: 'test',
              script: 'echo',
              dependencies: ['another-job'],
              needs: ['another-job']
            }
          end

          it { expect(entry).to be_valid }
        end

        context 'when it is a release' do
          let(:config) do
            {
              script: ["make changelog | tee release_changelog.txt"],
              release: {
                tag_name: "v0.06",
                name: "Release $CI_TAG_NAME",
                description: "./release_changelog.txt"
              }
            }
          end

          it { expect(entry).to be_valid }
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

      context 'when extends key is not a string' do
        let(:config) { { extends: 123 } }

        it 'returns error about wrong value type' do
          expect(entry).not_to be_valid
          expect(entry.errors).to include "job extends should be an array of strings or a string"
        end
      end

      context 'when parallel value is not correct' do
        context 'when it is not a numeric value' do
          let(:config) { { parallel: true } }

          it 'returns error about invalid type' do
            expect(entry).not_to be_valid
            expect(entry.errors).to include 'job parallel is not a number'
          end
        end

        context 'when it is lower than two' do
          let(:config) { { parallel: 1 } }

          it 'returns error about value too low' do
            expect(entry).not_to be_valid
            expect(entry.errors)
              .to include 'job parallel must be greater than or equal to 2'
          end
        end

        context 'when it is bigger than 50' do
          let(:config) { { parallel: 51 } }

          it 'returns error about value too high' do
            expect(entry).not_to be_valid
            expect(entry.errors)
              .to include 'job parallel must be less than or equal to 50'
          end
        end

        context 'when it is not an integer' do
          let(:config) { { parallel: 1.5 } }

          it 'returns error about wrong value' do
            expect(entry).not_to be_valid
            expect(entry.errors).to include 'job parallel must be an integer'
          end
        end

        context 'when it uses both "when:" and "rules:"' do
          let(:config) do
            {
              script: 'echo',
              when: 'on_failure',
              rules: [{ if: '$VARIABLE', when: 'on_success' }]
            }
          end

          it 'returns an error about when: being combined with rules' do
            expect(entry).not_to be_valid
            expect(entry.errors).to include 'job config key may not be used with `rules`: when'
          end
        end
      end

      context 'when delayed job' do
        context 'when start_in is specified' do
          let(:config) { { script: 'echo', when: 'delayed', start_in: '1 week' } }

          it { expect(entry).to be_valid }
        end

        context 'when start_in is empty' do
          let(:config) { { when: 'delayed', start_in: nil } }

          it 'returns error about invalid type' do
            expect(entry).not_to be_valid
            expect(entry.errors).to include 'job start in should be a duration'
          end
        end

        context 'when start_in is not formatted as a duration' do
          let(:config) { { when: 'delayed', start_in: 'test' } }

          it 'returns error about invalid type' do
            expect(entry).not_to be_valid
            expect(entry.errors).to include 'job start in should be a duration'
          end
        end

        context 'when start_in is longer than one week' do
          let(:config) { { when: 'delayed', start_in: '8 days' } }

          it 'returns error about exceeding the limit' do
            expect(entry).not_to be_valid
            expect(entry.errors).to include 'job start in should not exceed the limit'
          end
        end
      end

      context 'when only: is used with rules:' do
        let(:config) { { only: ['merge_requests'], rules: [{ if: '$THIS' }] } }

        it 'returns error about mixing only: with rules:' do
          expect(entry).not_to be_valid
          expect(entry.errors).to include /may not be used with `rules`/
        end

        context 'and only: is blank' do
          let(:config) { { only: nil, rules: [{ if: '$THIS' }] } }

          it 'returns error about mixing only: with rules:' do
            expect(entry).not_to be_valid
            expect(entry.errors).to include /may not be used with `rules`/
          end
        end

        context 'and rules: is blank' do
          let(:config) { { only: ['merge_requests'], rules: nil } }

          it 'returns error about mixing only: with rules:' do
            expect(entry).not_to be_valid
            expect(entry.errors).to include /may not be used with `rules`/
          end
        end
      end

      context 'when except: is used with rules:' do
        let(:config) { { except: { refs: %w[master] }, rules: [{ if: '$THIS' }] } }

        it 'returns error about mixing except: with rules:' do
          expect(entry).not_to be_valid
          expect(entry.errors).to include /may not be used with `rules`/
        end

        context 'and except: is blank' do
          let(:config) { { except: nil, rules: [{ if: '$THIS' }] } }

          it 'returns error about mixing except: with rules:' do
            expect(entry).not_to be_valid
            expect(entry.errors).to include /may not be used with `rules`/
          end
        end

        context 'and rules: is blank' do
          let(:config) { { except: { refs: %w[master] }, rules: nil } }

          it 'returns error about mixing except: with rules:' do
            expect(entry).not_to be_valid
            expect(entry.errors).to include /may not be used with `rules`/
          end
        end
      end

      context 'when only: and except: are both used with rules:' do
        let(:config) do
          {
            only: %w[merge_requests],
            except: { refs: %w[master] },
            rules: [{ if: '$THIS' }]
          }
        end

        it 'returns errors about mixing both only: and except: with rules:' do
          expect(entry).not_to be_valid
          expect(entry.errors).to include /may not be used with `rules`/
          expect(entry.errors).to include /may not be used with `rules`/
        end

        context 'when only: and except: as both blank' do
          let(:config) do
            { only: nil, except: nil, rules: [{ if: '$THIS' }] }
          end

          it 'returns errors about mixing both only: and except: with rules:' do
            expect(entry).not_to be_valid
            expect(entry.errors).to include /may not be used with `rules`/
            expect(entry.errors).to include /may not be used with `rules`/
          end
        end

        context 'when rules: is blank' do
          let(:config) do
            { only: %w[merge_requests], except: { refs: %w[master] }, rules: nil }
          end

          it 'returns errors about mixing both only: and except: with rules:' do
            expect(entry).not_to be_valid
            expect(entry.errors).to include /may not be used with `rules`/
            expect(entry.errors).to include /may not be used with `rules`/
          end
        end
      end

      context 'when start_in specified without delayed specification' do
        let(:config) { { start_in: '1 day' } }

        it 'returns error about invalid type' do
          expect(entry).not_to be_valid
          expect(entry.errors).to include 'job start in must be blank'
        end
      end

      context 'when has dependencies' do
        context 'that are not a array of strings' do
          let(:config) do
            { script: 'echo', dependencies: 'build-job' }
          end

          it 'returns error about invalid type' do
            expect(entry).not_to be_valid
            expect(entry.errors).to include 'job dependencies should be an array of strings'
          end
        end
      end

      context 'when has needs' do
        context 'when have dependencies that are not subset of needs' do
          let(:config) do
            {
              stage: 'test',
              script: 'echo',
              dependencies: ['another-job'],
              needs: ['build-job']
            }
          end

          it 'returns error about invalid data' do
            expect(entry).not_to be_valid
            expect(entry.errors).to include 'job dependencies the another-job should be part of needs'
          end
        end

        context 'when stage: is missing' do
          let(:config) do
            {
              script: 'echo',
              needs: ['build-job']
            }
          end

          it 'returns error about invalid data' do
            expect(entry).not_to be_valid
            expect(entry.errors).to include 'job config missing required keys: stage'
          end
        end
      end

      context 'when timeout value is not correct' do
        context 'when it is higher than instance wide timeout' do
          let(:config) { { timeout: '3 months', script: 'test' } }

          it 'returns error about value too high' do
            expect(entry).not_to be_valid
            expect(entry.errors)
              .to include "timeout config should not exceed the limit"
          end
        end

        context 'when it is not a duration' do
          let(:config) { { timeout: 100, script: 'test' } }

          it 'returns error about wrong value' do
            expect(entry).not_to be_valid
            expect(entry.errors).to include 'timeout config should be a duration'
          end
        end
      end

      context 'when timeout value is correct' do
        let(:config) { { script: 'echo', timeout: '1m 1s' } }

        it 'returns correct timeout' do
          expect(entry).to be_valid
          expect(entry.errors).to be_empty
          expect(entry.timeout).to eq('1m 1s')
        end
      end

      context 'when it is a release' do
        context 'when `release:description` is missing' do
          let(:config) do
            {
              script: ["make changelog | tee release_changelog.txt"],
              release: {
                tag_name: "v0.06",
                name: "Release $CI_TAG_NAME"
              }
            }
          end

          it "returns error" do
            expect(entry).not_to be_valid
            expect(entry.errors).to include "release description can't be blank"
          end
        end
      end
    end
  end

  describe '#relevant?' do
    it 'is a relevant entry' do
      entry = described_class.new({ script: 'rspec' }, name: :rspec)

      expect(entry).to be_relevant
    end
  end

  describe '#compose!' do
    let(:specified) do
      double('specified', 'specified?' => true, value: 'specified')
    end

    let(:unspecified) { double('unspecified', 'specified?' => false) }
    let(:default) { double('default', '[]' => unspecified) }
    let(:workflow) { double('workflow', 'has_rules?' => false) }
    let(:deps) { double('deps', 'default' => default, '[]' => unspecified, 'workflow' => workflow) }

    context 'when job config overrides default config' do
      before do
        entry.compose!(deps)
      end

      let(:config) do
        { script: 'rspec', image: 'some_image', cache: { key: 'test' } }
      end

      it 'overrides default config' do
        expect(entry[:image].value).to eq(name: 'some_image')
        expect(entry[:cache].value).to eq(key: 'test', policy: 'pull-push')
      end
    end

    context 'when job config does not override default config' do
      before do
        allow(default).to receive('[]').with(:image).and_return(specified)

        entry.compose!(deps)
      end

      let(:config) { { script: 'ls', cache: { key: 'test' } } }

      it 'uses config from default entry' do
        expect(entry[:image].value).to eq 'specified'
        expect(entry[:cache].value).to eq(key: 'test', policy: 'pull-push')
      end
    end

    context 'with workflow rules' do
      using RSpec::Parameterized::TableSyntax

      where(:name, :has_workflow_rules?, :only, :rules, :result) do
        "uses default only"    | false | nil          | nil    | { refs: %w[branches tags] }
        "uses user only"       | false | %w[branches] | nil    | { refs: %w[branches] }
        "does not define only" | false | nil          | []     | nil
        "does not define only" | true  | nil          | nil    | nil
        "uses user only"       | true  | %w[branches] | nil    | { refs: %w[branches] }
        "does not define only" | true  | nil          | []     | nil
      end

      with_them do
        let(:config) { { script: 'ls', rules: rules, only: only }.compact }

        it "#{name}" do
          expect(workflow).to receive(:has_rules?) { has_workflow_rules? }

          entry.compose!(deps)

          expect(entry.only_value).to eq(result)
        end
      end
    end

    context 'when workflow rules is used' do
      context 'when rules are used' do
        let(:config) { { script: 'ls', cache: { key: 'test' }, rules: [] } }

        it 'does not define only' do
          expect(entry).not_to be_only_defined
        end
      end

      context 'when rules are not used' do
        let(:config) { { script: 'ls', cache: { key: 'test' }, only: [] } }

        it 'does not define only' do
          expect(entry).not_to be_only_defined
        end
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
                   stage: 'test',
                   ignore: false,
                   after_script: %w[cleanup],
                   only: { refs: %w[branches tags] },
                   variables: {})
        end
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

  describe '#delayed?' do
    context 'when job is a delayed' do
      let(:config) { { script: 'deploy', when: 'delayed' } }

      it 'is a delayed' do
        expect(entry).to be_delayed
      end
    end

    context 'when job is not a delayed' do
      let(:config) { { script: 'deploy' } }

      it 'is not a delayed' do
        expect(entry).not_to be_delayed
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
