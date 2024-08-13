# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Config::Entry::Processable, feature_category: :pipeline_composition do
  let(:node_class) do
    Class.new(::Gitlab::Config::Entry::Node) do
      include Gitlab::Ci::Config::Entry::Processable

      entry :tags, ::Gitlab::Config::Entry::ArrayOfStrings,
        description: 'Set the default tags.',
        inherit: true

      def self.name
        'job'
      end
    end
  end

  let(:entry) { node_class.new(config, name: :rspec) }

  describe 'validations' do
    before do
      entry.compose!
    end

    context 'when entry config value is correct' do
      let(:config) { { stage: 'test' } }

      describe '#valid?' do
        it 'is valid' do
          expect(entry).to be_valid
        end
      end

      context 'when config uses both "when:" and "rules:"' do
        let(:config) do
          {
            script: 'echo',
            when: 'on_failure',
            rules: [{ if: '$VARIABLE', when: 'on_success' }]
          }
        end

        it 'is valid' do
          expect(entry).to be_valid
        end
      end

      context 'when job name is more than 255' do
        let(:entry) { node_class.new(config, name: ('a' * 256).to_sym) }

        it 'shows a validation error' do
          expect(entry.errors).to include "job name is too long (maximum is 255 characters)"
        end
      end

      context 'when job name is empty' do
        let(:entry) { node_class.new(config, name: :"") }

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

      context 'when extends key is not a string' do
        let(:config) { { extends: 123 } }

        it 'returns error about wrong value type' do
          expect(entry).not_to be_valid
          expect(entry.errors).to include "job extends should be an array of strings or a string"
        end
      end

      context 'when resource_group key is not a string' do
        let(:config) { { resource_group: 123 } }

        it 'returns error about wrong value type' do
          expect(entry).not_to be_valid
          expect(entry.errors).to include "job resource group should be a string"
        end
      end

      context 'when a variable has an invalid data attribute' do
        let(:config) do
          {
            script: 'echo',
            variables: { 'VAR1' => 'val 1', 'VAR2' => { value: 'val 2', description: 'hello var 2' } }
          }
        end

        it 'reports error about variable' do
          expect(entry.errors)
            .to include 'variables:var2 config uses invalid data keys: description'
        end
      end
    end

    context 'when script: and trigger: are used together' do
      let(:config) do
        {
          script: 'echo',
          trigger: 'test-group/test-project'
        }
      end

      it 'returns is invalid' do
        expect(entry).not_to be_valid
        expect(entry.errors).to include(/these keys cannot be used together: script, trigger/)
      end
    end

    context 'when run: and trigger: are used together' do
      let(:config) do
        {
          run: [{ name: 'step1', step: 'some reference' }],
          trigger: 'test-group/test-project'
        }
      end

      it 'is invalid' do
        expect(entry).not_to be_valid
        expect(entry.errors).to include(/these keys cannot be used together: run, trigger/)
      end
    end

    context 'when only: is used with rules:' do
      let(:config) { { only: ['merge_requests'], rules: [{ if: '$THIS' }] } }

      it 'returns error about mixing only: with rules:' do
        expect(entry).not_to be_valid
        expect(entry.errors).to include(/may not be used with `rules`: only/)
      end

      context 'and only: is blank' do
        let(:config) { { only: nil, rules: [{ if: '$THIS' }] } }

        it 'is valid' do
          expect(entry).to be_valid
        end
      end

      context 'and rules: is blank' do
        let(:config) { { only: ['merge_requests'], rules: nil } }

        it 'is valid' do
          expect(entry).to be_valid
        end
      end
    end

    context 'when except: is used with rules:' do
      let(:config) { { except: { refs: %w[master] }, rules: [{ if: '$THIS' }] } }

      it 'returns error about mixing except: with rules:' do
        expect(entry).not_to be_valid
        expect(entry.errors).to include(/may not be used with `rules`: except/)
      end

      context 'and except: is blank' do
        let(:config) { { except: nil, rules: [{ if: '$THIS' }] } }

        it 'is valid' do
          expect(entry).to be_valid
        end
      end

      context 'and rules: is blank' do
        let(:config) { { except: { refs: %w[master] }, rules: nil } }

        it 'is valid' do
          expect(entry).to be_valid
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
        expect(entry.errors).to include(/may not be used with `rules`: only, except/)
      end

      context 'when only: and except: as both blank' do
        let(:config) do
          { only: nil, except: nil, rules: [{ if: '$THIS' }] }
        end

        it 'is valid' do
          expect(entry).to be_valid
        end
      end

      context 'when rules: is blank' do
        let(:config) do
          { only: %w[merge_requests], except: { refs: %w[master] }, rules: nil }
        end

        it 'is valid' do
          expect(entry).to be_valid
        end
      end
    end

    context 'when interruptible is not a boolean' do
      let(:config) { { interruptible: 123 } }

      it 'returns error about wrong value type' do
        expect(entry).not_to be_valid
        expect(entry.errors).to include "interruptible config should be a boolean value"
      end
    end
  end

  describe '#relevant?' do
    it 'is a relevant entry' do
      entry = node_class.new({ stage: 'test' }, name: :rspec)

      expect(entry).to be_relevant
    end
  end

  describe '#compose!' do
    let(:unspecified) { double('unspecified', 'specified?' => false) }
    let(:default) { double('default', '[]' => unspecified) }
    let(:workflow) { double('workflow', 'has_rules?' => false) }

    let(:deps) do
      double('deps',
        default_entry: default,
        workflow_entry: workflow)
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

        it name.to_s do
          expect(workflow).to receive(:has_rules?) { has_workflow_rules? }

          entry.compose!(deps)

          expect(entry.only_value).to eq(result)
        end
      end
    end

    shared_examples 'has no warnings' do
      it 'does not raise the warning' do
        expect(entry.warnings).to be_empty
      end
    end

    context 'when workflow rules is used' do
      let(:workflow) { double('workflow', 'has_rules?' => true) }

      before do
        entry.compose!(deps)
      end

      context 'when rules are used' do
        let(:config) { { script: 'ls', cache: { key: 'test' }, rules: [] } }

        it 'does not define only' do
          expect(entry).not_to be_only_defined
        end
      end

      context 'when rules are not used and only is defined' do
        let(:config) { { script: 'ls', cache: { key: 'test' }, only: [] } }

        it 'keeps only entry' do
          expect(entry).to be_only_defined
        end
      end
    end

    context 'when workflow rules is not used' do
      let(:workflow) { double('workflow', 'has_rules?' => false) }

      before do
        entry.compose!(deps)
      end

      context 'when rules are valid' do
        let(:config) do
          {
            script: 'ls',
            rules: [
              { if: '$CI_COMMIT_BRANCH', when: 'on_success' },
              last_rule
            ]
          }
        end

        context 'when last rule contains only `when`' do
          let(:last_rule) { { when: when_value } }

          context 'and its value is not `never`' do
            let(:when_value) { 'on_success' }

            it 'raises a warning' do
              expect(entry.warnings).to contain_exactly(/may allow multiple pipelines/)
            end
          end

          context 'and its value is `never`' do
            let(:when_value) { 'never' }

            it_behaves_like 'has no warnings'
          end
        end

        context 'when last rule does not contain only `when`' do
          let(:last_rule) { { if: '$CI_MERGE_REQUEST_ID', when: 'always' } }

          it_behaves_like 'has no warnings'
        end
      end

      context 'when rules are invalid' do
        let(:config) { { script: 'ls', rules: { when: 'always' } } }

        it_behaves_like 'has no warnings'
      end
    end

    context 'when workflow rules is used' do
      let(:workflow) { double('workflow', 'has_rules?' => true) }

      before do
        entry.compose!(deps)
      end

      context 'when last rule contains only `when' do
        let(:config) do
          {
            script: 'ls',
            rules: [
              { if: '$CI_COMMIT_BRANCH', when: 'on_success' },
              { when: 'always' }
            ]
          }
        end

        it_behaves_like 'has no warnings'
      end
    end

    context 'with resource group' do
      using RSpec::Parameterized::TableSyntax

      where(:resource_group, :result) do
        'iOS'                         | 'iOS'
        'review/$CI_COMMIT_REF_NAME'  | 'review/$CI_COMMIT_REF_NAME'
        nil                           | nil
      end

      with_them do
        let(:config) { { script: 'ls', resource_group: resource_group }.compact }

        it do
          entry.compose!(deps)

          expect(entry.resource_group).to eq(result)
        end
      end
    end

    context 'with environment' do
      context 'when environment name is specified' do
        let(:config) { { script: 'ls', environment: 'prod' }.compact }

        it 'sets environment name and action to the entry value' do
          entry.compose!(deps)

          expect(entry.value[:environment]).to eq({ action: 'start', name: 'prod' })
          expect(entry.value[:environment_name]).to eq('prod')
        end
      end

      context 'when environment name, url and action are specified' do
        let(:config) do
          {
            script: 'ls',
            environment: {
              name: 'staging',
              url: 'https://gitlab.com',
              action: 'prepare'
            }
          }.compact
        end

        it 'sets environment name, action and url to the entry value' do
          entry.compose!(deps)

          expect(entry.value[:environment]).to eq({ action: 'prepare', name: 'staging', url: 'https://gitlab.com' })
          expect(entry.value[:environment_name]).to eq('staging')
        end
      end
    end

    context 'with inheritance' do
      context 'of default:tags' do
        using RSpec::Parameterized::TableSyntax

        where(:name, :default_tags, :tags, :inherit_default, :result) do
          "only local tags"       | nil     | %w[a b] | nil       | %w[a b]
          "only local tags"       | nil     | %w[a b] | true      | %w[a b]
          "only local tags"       | nil     | %w[a b] | false     | %w[a b]
          "global and local tags" | %w[b c] | %w[a b] | nil       | %w[a b]
          "global and local tags" | %w[b c] | %w[a b] | true      | %w[a b]
          "global and local tags" | %w[b c] | %w[a b] | false     | %w[a b]
          "only global tags"      | %w[b c] | nil     | nil       | %w[b c]
          "only global tags"      | %w[b c] | nil     | true      | %w[b c]
          "only global tags"      | %w[b c] | nil     | false     | nil
          "only global tags"      | %w[b c] | nil     | %w[image] | nil
          "only global tags"      | %w[b c] | nil     | %w[tags]  | %w[b c]
        end

        with_them do
          let(:config) do
            { tags: tags,
              inherit: { default: inherit_default } }
          end

          let(:default_specified_tags) do
            double('tags',
              'specified?' => true,
              'valid?' => true,
              'value' => default_tags,
              'errors' => [])
          end

          before do
            allow(default).to receive('[]').with(:tags).and_return(default_specified_tags)

            entry.compose!(deps)

            expect(entry).to be_valid
          end

          it { expect(entry.tags_value).to eq(result) }
        end
      end
    end

    context 'with interruptible' do
      context 'when interruptible is not defined' do
        let(:config) { { script: 'ls' } }

        it 'sets interruptible to nil' do
          entry.compose!(deps)

          expect(entry.value[:interruptible]).to be_nil
        end
      end

      context 'when interruptible is defined' do
        let(:config) { { script: 'ls', interruptible: true } }

        it 'sets interruptible to the value' do
          entry.compose!(deps)

          expect(entry.value[:interruptible]).to eq(true)
        end
      end
    end
  end

  context 'when composed' do
    before do
      entry.compose!
    end

    describe '#value' do
      context 'when entry is correct' do
        let(:config) do
          { stage: 'test' }
        end

        it 'returns correct value' do
          expect(entry.value).to eq(
            name: :rspec,
            stage: 'test',
            only: { refs: %w[branches tags] },
            job_variables: {},
            root_variables_inheritance: true
          )
        end
      end

      context 'when variables have "expand" data' do
        let(:config) do
          {
            script: 'echo',
            variables: { 'VAR1' => 'val 1',
                         'VAR2' => { value: 'val 2', expand: false },
                         'VAR3' => { value: 'val 3', expand: true } }
          }
        end

        it 'returns correct value' do
          expect(entry.value).to eq(
            name: :rspec,
            stage: 'test',
            only: { refs: %w[branches tags] },
            job_variables: { 'VAR1' => { value: 'val 1' },
                             'VAR2' => { value: 'val 2', raw: true },
                             'VAR3' => { value: 'val 3', raw: false } },
            root_variables_inheritance: true
          )
        end
      end
    end
  end
end
