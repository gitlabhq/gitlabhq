# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Pipeline::Seed::Build, feature_category: :pipeline_composition do
  let_it_be_with_reload(:project) { create(:project, :repository) }
  let_it_be(:head_sha) { project.repository.head_commit.id }

  let(:pipeline) { build(:ci_empty_pipeline, project: project, sha: head_sha) }
  let(:root_variables) { [] }
  let(:seed_context) { Gitlab::Ci::Pipeline::Seed::Context.new(pipeline, root_variables: root_variables) }
  let(:attributes) { { name: 'rspec', ref: 'master', scheduling_type: :stage, when: 'on_success' } }
  let(:previous_stages) { [] }
  let(:current_stage) { instance_double(Gitlab::Ci::Pipeline::Seed::Stage, seeds_names: [attributes[:name]]) }

  let(:seed_build) { described_class.new(seed_context, attributes, previous_stages + [current_stage]) }

  describe '#attributes' do
    subject(:seed_attributes) { seed_build.attributes }

    it { is_expected.to be_a(Hash) }
    it { is_expected.to include(:name, :project, :ref) }

    context 'with job:when' do
      let(:attributes) { { name: 'rspec', ref: 'master', when: 'on_failure' } }

      it { is_expected.to include(when: 'on_failure') }
    end

    context 'with job:when:delayed' do
      let(:attributes) { { name: 'rspec', ref: 'master', when: 'delayed', options: { start_in: '3 hours' } } }

      it { is_expected.to include(when: 'delayed', options: { start_in: '3 hours' }) }
    end

    context 'with job:rules:[when:]' do
      context 'is matched' do
        let(:attributes) { { name: 'rspec', ref: 'master', rules: [{ if: '$VAR == null', when: 'always' }] } }

        it { is_expected.to include(when: 'always') }
      end

      context 'is not matched' do
        let(:attributes) { { name: 'rspec', ref: 'master', rules: [{ if: '$VAR != null', when: 'always' }] } }

        it { is_expected.to include(when: 'never') }
      end
    end

    context 'with job:run attribute' do
      let(:run_value) do
        [
          { name: 'step1', step: 'some_step_reference', env: { VAR1: 'value1', VAR2: 'value2' } },
          { name: 'step2', script: "echo 'Hello, World!'", inputs: { input1: 'input_value1', input2: 'input_value1223' } }
        ].map(&:deep_stringify_keys)
      end

      let(:attributes) do
        {
          name: 'rspec',
          ref: 'master',
          execution_config: {
            run_steps: run_value
          }
        }
      end

      it 'includes execution_config attribute with run steps' do
        expect(subject[:execution_config]).to an_object_having_attributes(
          project: pipeline.project,
          pipeline: pipeline,
          run_steps: run_value
        )
      end

      context 'when job:run attribute is not specified' do
        let(:attributes) do
          {
            name: 'rspec',
            ref: 'master'
          }
        end

        it 'does not include execution_config attribute' do
          expect(subject).not_to include(:execution_config)
        end
      end
    end

    context 'with job:rules:[when:delayed]' do
      context 'is matched' do
        let(:attributes) { { name: 'rspec', ref: 'master', rules: [{ if: '$VAR == null', when: 'delayed', start_in: '3 hours' }] } }

        it { is_expected.to include(when: 'delayed', options: { start_in: '3 hours' }) }
      end

      context 'is not matched' do
        let(:attributes) { { name: 'rspec', ref: 'master', rules: [{ if: '$VAR != null', when: 'delayed', start_in: '3 hours' }] } }

        it { is_expected.to include(when: 'never') }
      end
    end

    context 'with job: rules but no explicit when:' do
      let(:base_attributes) { { name: 'rspec', ref: 'master' } }

      context 'with a manual job' do
        context 'with a matched rule' do
          let(:attributes) { base_attributes.merge(when: 'manual', rules: [{ if: '$VAR == null' }]) }

          it { is_expected.to include(when: 'manual') }
        end

        context 'is not matched' do
          let(:attributes) { base_attributes.merge(when: 'manual', rules: [{ if: '$VAR != null' }]) }

          it { is_expected.to include(when: 'never') }
        end
      end

      context 'with an automatic job' do
        context 'is matched' do
          let(:attributes) { base_attributes.merge(when: 'on_success', rules: [{ if: '$VAR == null' }]) }

          it { is_expected.to include(when: 'on_success') }
        end

        context 'is not matched' do
          let(:attributes) { base_attributes.merge(when: 'on_success', rules: [{ if: '$VAR != null' }]) }

          it { is_expected.to include(when: 'never') }
        end
      end
    end

    context 'with job:rules:[variables:]' do
      let(:attributes) do
        { name: 'rspec',
          ref: 'master',
          job_variables: [{ key: 'VAR1', value: 'var 1' },
                          { key: 'VAR2', value: 'var 2' }],
          rules: [{ if: '$VAR == null', variables: { VAR1: 'new var 1', VAR3: 'var 3' } }] }
      end

      it do
        is_expected.to include(yaml_variables: [{ key: 'VAR1', value: 'new var 1' },
                                                { key: 'VAR3', value: 'var 3' },
                                                { key: 'VAR2', value: 'var 2' }])
      end
    end

    context 'with job:rules:[needs:]' do
      context 'with a single rule' do
        let(:job_needs_attributes) { [{ name: 'rspec' }] }

        context 'when job has needs set' do
          context 'when rule evaluates to true' do
            let(:attributes) do
              { name: 'rspec',
                ref: 'master',
                needs_attributes: job_needs_attributes,
                rules: [{ if: '$VAR == null', needs: { job: [{ name: 'build-job' }] } }] }
            end

            it 'overrides the job needs' do
              expect(subject).to include(needs_attributes: [{ name: 'build-job' }])
            end
          end

          context 'when rule evaluates to false' do
            let(:attributes) do
              { name: 'rspec',
                ref: 'master',
                needs_attributes: job_needs_attributes,
                rules: [{ if: '$VAR == true', needs: { job: [{ name: 'build-job' }] } }] }
            end

            it 'keeps the job needs' do
              expect(subject).to include(needs_attributes: job_needs_attributes)
            end
          end

          context 'with subkeys: artifacts, optional' do
            let(:attributes) do
              { name: 'rspec',
                ref: 'master',
                rules:
                [
                  { if: '$VAR == null',
                    needs: {
                      job: [{
                        name: 'build-job',
                        optional: false,
                        artifacts: true
                      }]
                    } }
                ] }
            end

            context 'when rule evaluates to true' do
              it 'sets the job needs as well as the job subkeys' do
                expect(subject[:needs_attributes]).to match_array([{ name: 'build-job', optional: false, artifacts: true }])
              end

              it 'sets the scheduling type to dag' do
                expect(subject[:scheduling_type]).to eq(:dag)
              end
            end
          end
        end

        context 'with multiple rules' do
          context 'when a rule evaluates to true' do
            let(:attributes) do
              { name: 'rspec',
                ref: 'master',
                needs_attributes: job_needs_attributes,
                rules: [
                  { if: '$VAR == true', needs: { job: [{ name: 'rspec-1' }] } },
                  { if: '$VAR2 == true', needs: { job: [{ name: 'rspec-2' }] } },
                  { if: '$VAR3 == null', needs: { job: [{ name: 'rspec' }, { name: 'lint' }] } }
                ] }
            end

            it 'overrides the job needs' do
              expect(subject).to include(needs_attributes: [{ name: 'rspec' }, { name: 'lint' }])
            end
          end

          context 'when all rules evaluates to false' do
            let(:attributes) do
              { name: 'rspec',
                ref: 'master',
                needs_attributes: job_needs_attributes,
                rules: [
                  { if: '$VAR == true', needs: { job: [{ name: 'rspec-1' }] }  },
                  { if: '$VAR2 == true', needs: { job: [{ name: 'rspec-2' }] } },
                  { if: '$VAR3 == true', needs: { job: [{ name: 'rspec-3' }] } }
                ] }
            end

            it 'keeps the job needs' do
              expect(subject).to include(needs_attributes: job_needs_attributes)
            end
          end
        end
      end
    end

    context 'with job:rules:[interruptible:]' do
      let(:attributes) do
        {
          name: 'rspec',
          ref: 'master',
          interruptible: false,
          rules: rules
        }
      end

      context 'when rule evaluates to true' do
        let(:rules) { [{ if: '$VAR == null', interruptible: true }] }

        it 'overrides the job interruptible value' do
          is_expected.to include(interruptible: true)
        end

        context 'when job does not have an interruptible value' do
          let(:attributes) do
            {
              name: 'rspec',
              ref: 'master',
              rules: rules
            }
          end

          it 'adds interruptible value to the job' do
            is_expected.to include(interruptible: true)
          end
        end

        context 'when rules:interruptible is not specified' do
          let(:rules) { [{ if: '$VAR == null' }] }

          it 'does not change the job interruptible value' do
            is_expected.to include(interruptible: false)
          end
        end
      end

      context 'when rule evaluates to false' do
        let(:rules) { [{ if: '$VAR == true', interruptible: true }] }

        it 'does not change the job interruptible value' do
          is_expected.to include(interruptible: false)
        end
      end
    end

    context 'with job:tags' do
      let(:attributes) do
        {
          name: 'rspec',
          ref: 'master',
          job_variables: [{ key: 'VARIABLE', value: 'value' }],
          tag_list: ['static-tag', '$VARIABLE', '$NO_VARIABLE']
        }
      end

      it { is_expected.to include(tag_list: ['static-tag', 'value', '$NO_VARIABLE']) }
      it { is_expected.to include(yaml_variables: [{ key: 'VARIABLE', value: 'value' }]) }
    end

    context 'with cache:key' do
      let(:attributes) do
        {
          name: 'rspec',
          ref: 'master',
          cache: [{
            key: 'a-value'
          }]
        }
      end

      it { is_expected.to include(options: { cache: [a_hash_including(key: 'a-value')] }) }

      context 'with cache:key:files' do
        let(:attributes) do
          {
            name: 'rspec',
            ref: 'master',
            cache: [{
              key: {
                files: ['VERSION']
              }
            }]
          }
        end

        it 'includes cache options' do
          cache_options = {
            options: {
              cache: [a_hash_including(key: '0_VERSION-f155568ad0933d8358f66b846133614f76dd0ca4')]
            }
          }

          is_expected.to include(cache_options)
        end
      end

      context 'with cache:key:prefix' do
        let(:attributes) do
          {
            name: 'rspec',
            ref: 'master',
            cache: [{
              key: {
                prefix: 'something'
              }
            }]
          }
        end

        it { is_expected.to include(options: { cache: [a_hash_including(key: 'something-default')] }) }
      end

      context 'with cache:key:files and prefix' do
        let(:attributes) do
          {
            name: 'rspec',
            ref: 'master',
            cache: [{
              key: {
                files: ['VERSION'],
                prefix: 'something'
              }
            }]
          }
        end

        it 'includes cache options' do
          cache_options = {
            options: {
              cache: [a_hash_including(key: 'something-f155568ad0933d8358f66b846133614f76dd0ca4')]
            }
          }

          is_expected.to include(cache_options)
        end
      end
    end

    context 'with empty cache' do
      let(:attributes) do
        {
          name: 'rspec',
          ref: 'master',
          cache: {}
        }
      end

      it { is_expected.to include({}) }
    end

    context 'with allow_failure' do
      let(:options) do
        { allow_failure_criteria: { exit_codes: [42] } }
      end

      let(:rules) do
        [{ if: '$VAR == null', when: 'always' }]
      end

      let(:attributes) do
        {
          name: 'rspec',
          ref: 'master',
          options: options,
          rules: rules
        }
      end

      context 'when rules does not override allow_failure' do
        it { is_expected.to match a_hash_including(options: options) }
      end

      context 'when rules set allow_failure to true' do
        let(:rules) do
          [{ if: '$VAR == null', when: 'always', allow_failure: true }]
        end

        it { is_expected.to match a_hash_including(options: { allow_failure_criteria: nil }) }
      end

      context 'when rules set allow_failure to false' do
        let(:rules) do
          [{ if: '$VAR == null', when: 'always', allow_failure: false }]
        end

        it { is_expected.to match a_hash_including(options: { allow_failure_criteria: nil }) }
      end
    end

    context 'with workflow:rules:[variables:]' do
      let(:attributes) do
        { name: 'rspec',
          ref: 'master',
          yaml_variables: [{ key: 'VAR2', value: 'var 2' },
                            { key: 'VAR3', value: 'var 3' }],
          job_variables: [{ key: 'VAR2', value: 'var 2' },
                          { key: 'VAR3', value: 'var 3' }],
          root_variables_inheritance: root_variables_inheritance }
      end

      context 'when the pipeline has variables' do
        let(:root_variables) do
          [{ key: 'VAR1', value: 'var overridden pipeline 1' },
            { key: 'VAR2', value: 'var pipeline 2' },
            { key: 'VAR3', value: 'var pipeline 3' },
            { key: 'VAR4', value: 'new var pipeline 4' }]
        end

        context 'when root_variables_inheritance is true' do
          let(:root_variables_inheritance) { true }

          it 'returns calculated yaml variables' do
            expect(subject[:yaml_variables]).to match_array(
              [{ key: 'VAR1', value: 'var overridden pipeline 1' },
                { key: 'VAR2', value: 'var 2' },
                { key: 'VAR3', value: 'var 3' },
                { key: 'VAR4', value: 'new var pipeline 4' }]
            )
          end
        end

        context 'when root_variables_inheritance is false' do
          let(:root_variables_inheritance) { false }

          it 'returns job variables' do
            expect(subject[:yaml_variables]).to match_array(
              [{ key: 'VAR2', value: 'var 2' },
                { key: 'VAR3', value: 'var 3' }]
            )
          end
        end

        context 'when root_variables_inheritance is an array' do
          let(:root_variables_inheritance) { %w[VAR1 VAR2 VAR3] }

          it 'returns calculated yaml variables' do
            expect(subject[:yaml_variables]).to match_array(
              [{ key: 'VAR1', value: 'var overridden pipeline 1' },
                { key: 'VAR2', value: 'var 2' },
                { key: 'VAR3', value: 'var 3' }]
            )
          end
        end
      end

      context 'when the pipeline has not a variable' do
        let(:root_variables_inheritance) { true }

        it 'returns seed yaml variables' do
          expect(subject[:yaml_variables]).to match_array(
            [{ key: 'VAR2', value: 'var 2' },
              { key: 'VAR3', value: 'var 3' }])
        end
      end
    end

    context 'when the job rule depends on variables' do
      let(:attributes) do
        { name: 'rspec',
          ref: 'master',
          yaml_variables: [{ key: 'VAR1', value: 'var 1' }],
          job_variables: [{ key: 'VAR1', value: 'var 1' }],
          root_variables_inheritance: root_variables_inheritance,
          rules: rules }
      end

      let(:root_variables_inheritance) { true }

      context 'when the rules use job variables' do
        let(:rules) do
          [{ if: '$VAR1 == "var 1"', variables: { VAR1: 'overridden var 1', VAR2: 'new var 2' } }]
        end

        it 'recalculates the variables' do
          expect(subject[:yaml_variables]).to contain_exactly(
            { key: 'VAR1', value: 'overridden var 1' },
            { key: 'VAR2', value: 'new var 2' }
          )
        end
      end

      context 'when the rules use root variables' do
        let(:root_variables) do
          [{ key: 'VAR2', value: 'var pipeline 2' }]
        end

        let(:rules) do
          [{ if: '$VAR2 == "var pipeline 2"', variables: { VAR1: 'overridden var 1', VAR2: 'overridden var 2' } }]
        end

        it 'recalculates the variables' do
          expect(subject[:yaml_variables]).to contain_exactly(
            { key: 'VAR1', value: 'overridden var 1' },
            { key: 'VAR2', value: 'overridden var 2' }
          )
        end

        context 'when the root_variables_inheritance is false' do
          let(:root_variables_inheritance) { false }

          it 'does not recalculate the variables' do
            expect(subject[:yaml_variables]).to contain_exactly({ key: 'VAR1', value: 'var 1' })
          end
        end
      end
    end

    describe 'propagating composite identity', :request_store do
      let_it_be(:user) { create(:user) }

      let(:attributes) do
        { name: 'rspec', options: { test: 123 } }
      end

      before do
        pipeline.update!(user: user)
      end

      it 'does not propagate composite identity by default' do
        expect(seed_attributes[:options].key?(:scoped_user_id)).to be(false)
      end
    end
  end

  describe '#bridge?' do
    subject { seed_build.bridge? }

    context 'when job is a downstream bridge' do
      let(:attributes) do
        { name: 'rspec', ref: 'master', options: { trigger: 'my/project' } }
      end

      it { is_expected.to be_truthy }

      context 'when trigger definition is empty' do
        let(:attributes) do
          { name: 'rspec', ref: 'master', options: { trigger: '' } }
        end

        it { is_expected.to be_falsey }
      end
    end

    context 'when job is an upstream bridge' do
      let(:attributes) do
        { name: 'rspec', ref: 'master', options: { bridge_needs: { pipeline: 'my/project' } } }
      end

      it { is_expected.to be_truthy }

      context 'when upstream definition is empty' do
        let(:attributes) do
          { name: 'rspec', ref: 'master', options: { bridge_needs: { pipeline: '' } } }
        end

        it { is_expected.to be_falsey }
      end
    end

    context 'when job is not a bridge' do
      it { is_expected.to be_falsey }
    end
  end

  describe '#to_resource' do
    subject { seed_build.to_resource }

    it 'memoizes a resource object' do
      expect(subject.object_id).to eq seed_build.to_resource.object_id
    end

    it 'can not be persisted without explicit assignment' do
      pipeline.save!

      expect(subject).not_to be_persisted
    end
  end

  describe 'applying job inclusion policies' do
    subject { seed_build }

    context 'when no branch policy is specified' do
      let(:attributes) do
        { name: 'rspec' }
      end

      it { is_expected.to be_included }
    end

    context 'when branch policy does not match' do
      context 'when using only' do
        let(:attributes) do
          { name: 'rspec', only: { refs: ['deploy'] } }
        end

        it { is_expected.not_to be_included }
      end

      context 'when using except' do
        let(:attributes) do
          { name: 'rspec', except: { refs: ['deploy'] } }
        end

        it { is_expected.to be_included }
      end

      context 'with both only and except policies' do
        let(:attributes) do
          {
            name: 'rspec',
            only: { refs: %w[deploy] },
            except: { refs: %w[deploy] }
          }
        end

        it { is_expected.not_to be_included }
      end
    end

    context 'when branch regexp policy does not match' do
      context 'when using only' do
        let(:attributes) do
          { name: 'rspec', only: { refs: %w[/^deploy$/] } }
        end

        it { is_expected.not_to be_included }
      end

      context 'when using except' do
        let(:attributes) do
          { name: 'rspec', except: { refs: %w[/^deploy$/] } }
        end

        it { is_expected.to be_included }
      end

      context 'with both only and except policies' do
        let(:attributes) do
          {
            name: 'rspec',
            only: { refs: %w[/^deploy$/] },
            except: { refs: %w[/^deploy$/] }
          }
        end

        it { is_expected.not_to be_included }
      end
    end

    context 'when branch policy matches' do
      context 'when using only' do
        let(:attributes) do
          { name: 'rspec', only: { refs: %w[deploy master] } }
        end

        it { is_expected.to be_included }
      end

      context 'when using except' do
        let(:attributes) do
          { name: 'rspec', except: { refs: %w[deploy master] } }
        end

        it { is_expected.not_to be_included }
      end

      context 'when using both only and except policies' do
        let(:attributes) do
          {
            name: 'rspec',
            only: { refs: %w[deploy master] },
            except: { refs: %w[deploy master] }
          }
        end

        it { is_expected.not_to be_included }
      end
    end

    context 'when keyword policy matches' do
      context 'when using only' do
        let(:attributes) do
          { name: 'rspec', only: { refs: %w[branches] } }
        end

        it { is_expected.to be_included }
      end

      context 'when using except' do
        let(:attributes) do
          { name: 'rspec', except: { refs: %w[branches] } }
        end

        it { is_expected.not_to be_included }
      end

      context 'when using both only and except policies' do
        let(:attributes) do
          {
            name: 'rspec',
            only: { refs: %w[branches] },
            except: { refs: %w[branches] }
          }
        end

        it { is_expected.not_to be_included }
      end
    end

    context 'when keyword policy does not match' do
      context 'when using only' do
        let(:attributes) do
          { name: 'rspec', only: { refs: %w[tags] } }
        end

        it { is_expected.not_to be_included }
      end

      context 'when using except' do
        let(:attributes) do
          { name: 'rspec', except: { refs: %w[tags] } }
        end

        it { is_expected.to be_included }
      end

      context 'when using both only and except policies' do
        let(:attributes) do
          {
            name: 'rspec',
            only: { refs: %w[tags] },
            except: { refs: %w[tags] }
          }
        end

        it { is_expected.not_to be_included }
      end
    end

    context 'with source-keyword policy' do
      using RSpec::Parameterized

      let(:pipeline) do
        build(:ci_empty_pipeline, ref: 'deploy', tag: false, source: source, project: project)
      end

      context 'matches' do
        where(:keyword, :source) do
          [
            %w[pushes push],
            %w[web web],
            %w[triggers trigger],
            %w[schedules schedule],
            %w[api api],
            %w[external external]
          ]
        end

        with_them do
          context 'using an only policy' do
            let(:attributes) do
              { name: 'rspec', only: { refs: [keyword] } }
            end

            it { is_expected.to be_included }
          end

          context 'using an except policy' do
            let(:attributes) do
              { name: 'rspec', except: { refs: [keyword] } }
            end

            it { is_expected.not_to be_included }
          end

          context 'using both only and except policies' do
            let(:attributes) do
              {
                name: 'rspec',
                only: { refs: [keyword] },
                except: { refs: [keyword] }
              }
            end

            it { is_expected.not_to be_included }
          end
        end
      end

      context 'non-matches' do
        where(:keyword, :source) do
          %w[web trigger schedule api external].map { |source| ['pushes', source] } +
            %w[push trigger schedule api external].map { |source| ['web', source] } +
            %w[push web schedule api external].map { |source| ['triggers', source] } +
            %w[push web trigger api external].map { |source| ['schedules', source] } +
            %w[push web trigger schedule external].map { |source| ['api', source] } +
            %w[push web trigger schedule api].map { |source| ['external', source] }
        end

        with_them do
          context 'using an only policy' do
            let(:attributes) do
              { name: 'rspec', only: { refs: [keyword] } }
            end

            it { is_expected.not_to be_included }
          end

          context 'using an except policy' do
            let(:attributes) do
              { name: 'rspec', except: { refs: [keyword] } }
            end

            it { is_expected.to be_included }
          end

          context 'using both only and except policies' do
            let(:attributes) do
              {
                name: 'rspec',
                only: { refs: [keyword] },
                except: { refs: [keyword] }
              }
            end

            it { is_expected.not_to be_included }
          end
        end
      end
    end

    context 'when repository path matches' do
      context 'when using only' do
        let(:attributes) do
          { name: 'rspec', only: { refs: ["branches@#{pipeline.project_full_path}"] } }
        end

        it { is_expected.to be_included }
      end

      context 'when using except' do
        let(:attributes) do
          { name: 'rspec', except: { refs: ["branches@#{pipeline.project_full_path}"] } }
        end

        it { is_expected.not_to be_included }
      end

      context 'when using both only and except policies' do
        let(:attributes) do
          {
            name: 'rspec',
            only: { refs: ["branches@#{pipeline.project_full_path}"] },
            except: { refs: ["branches@#{pipeline.project_full_path}"] }
          }
        end

        it { is_expected.not_to be_included }
      end

      context 'when using both only and except policies' do
        let(:attributes) do
          {
            name: 'rspec',
            only: {
              refs: ["branches@#{pipeline.project_full_path}"]
            },
            except: {
              refs: ["branches@#{pipeline.project_full_path}"]
            }
          }
        end

        it { is_expected.not_to be_included }
      end
    end

    context 'when repository path does not match' do
      context 'when using only' do
        let(:attributes) do
          { name: 'rspec', only: { refs: %w[branches@fork] } }
        end

        it { is_expected.not_to be_included }
      end

      context 'when using except' do
        let(:attributes) do
          { name: 'rspec', except: { refs: %w[branches@fork] } }
        end

        it { is_expected.to be_included }
      end

      context 'when using both only and except policies' do
        let(:attributes) do
          {
            name: 'rspec',
            only: { refs: %w[branches@fork] },
            except: { refs: %w[branches@fork] }
          }
        end

        it { is_expected.not_to be_included }
      end
    end

    context 'using rules:' do
      using RSpec::Parameterized

      let(:attributes) { { name: 'rspec', rules: rule_set, when: 'on_success' } }

      context 'with a matching if: rule' do
        context 'with an explicit `when: never`' do
          where(:rule_set) do
            [
              [[{ if: '$VARIABLE == null',              when: 'never' }]],
              [[{ if: '$VARIABLE == null',              when: 'never' }, { if: '$VARIABLE == null', when: 'always' }]],
              [[{ if: '$VARIABLE != "the wrong value"', when: 'never' }, { if: '$VARIABLE == null', when: 'always' }]]
            ]
          end

          with_them do
            it { is_expected.not_to be_included }

            it 'still correctly populates when:' do
              expect(seed_build.attributes).to include(when: 'never')
            end
          end
        end

        context 'with an explicit `when: always`' do
          where(:rule_set) do
            [
              [[{ if: '$VARIABLE == null',              when: 'always' }]],
              [[{ if: '$VARIABLE == null',              when: 'always' }, { if: '$VARIABLE == null', when: 'never' }]],
              [[{ if: '$VARIABLE != "the wrong value"', when: 'always' }, { if: '$VARIABLE == null', when: 'never' }]]
            ]
          end

          with_them do
            it { is_expected.to be_included }

            it 'correctly populates when:' do
              expect(seed_build.attributes).to include(when: 'always')
            end
          end
        end

        context 'with an explicit `when: on_failure`' do
          where(:rule_set) do
            [
              [[{ if: '$CI_JOB_NAME == "rspec" && $VAR == null', when: 'on_failure' }]],
              [[{ if: '$VARIABLE != null',              when: 'delayed', start_in: '1 day' }, { if: '$CI_JOB_NAME   == "rspec"', when: 'on_failure' }]],
              [[{ if: '$VARIABLE == "the wrong value"', when: 'delayed', start_in: '1 day' }, { if: '$CI_JOB_NAME == "rspec"', when: 'on_failure' }]]
            ]
          end

          with_them do
            it { is_expected.to be_included }

            it 'correctly populates when:' do
              expect(seed_build.attributes).to include(when: 'on_failure')
            end
          end
        end

        context 'with an explicit `when: delayed`' do
          where(:rule_set) do
            [
              [[{ if: '$VARIABLE == null',              when: 'delayed', start_in: '1 day' }]],
              [[{ if: '$VARIABLE == null',              when: 'delayed', start_in: '1 day' }, { if: '$VARIABLE == null', when: 'never' }]],
              [[{ if: '$VARIABLE != "the wrong value"', when: 'delayed', start_in: '1 day' }, { if: '$VARIABLE == null', when: 'never' }]]
            ]
          end

          with_them do
            it { is_expected.to be_included }

            it 'correctly populates when:' do
              expect(seed_build.attributes).to include(when: 'delayed', options: { start_in: '1 day' })
            end
          end
        end

        context 'without an explicit when: value' do
          where(:rule_set) do
            [
              [[{ if: '$VARIABLE == null'              }]],
              [[{ if: '$VARIABLE == null'              }, { if: '$VARIABLE == null' }]],
              [[{ if: '$VARIABLE != "the wrong value"' }, { if: '$VARIABLE == null' }]]
            ]
          end

          with_them do
            it { is_expected.to be_included }

            it 'correctly populates when:' do
              expect(seed_build.attributes).to include(when: 'on_success')
            end
          end
        end
      end

      context 'with a matching changes: rule' do
        let(:pipeline) do
          build(:ci_pipeline, project: project).tap do |pipeline|
            stub_pipeline_modified_paths(pipeline, %w[app/models/ci/pipeline.rb spec/models/ci/pipeline_spec.rb .gitlab-ci.yml])
          end
        end

        context 'with an explicit `when: never`' do
          where(:rule_set) do
            [
              [[{ changes: { paths: %w[*/**/*.rb] },                 when: 'never' }, { changes: { paths: %w[*/**/*.rb] },                 when: 'always' }]],
              [[{ changes: { paths: %w[app/models/ci/pipeline.rb] }, when: 'never' }, { changes: { paths: %w[app/models/ci/pipeline.rb] }, when: 'always' }]],
              [[{ changes: { paths: %w[spec/**/*.rb] },              when: 'never' }, { changes: { paths: %w[spec/**/*.rb] },              when: 'always' }]],
              [[{ changes: { paths: %w[*.yml] },                     when: 'never' }, { changes: { paths: %w[*.yml] },                     when: 'always' }]],
              [[{ changes: { paths: %w[.*.yml] },                    when: 'never' }, { changes: { paths: %w[.*.yml] },                    when: 'always' }]],
              [[{ changes: { paths: %w[**/*] },                      when: 'never' }, { changes: { paths: %w[**/*] },                      when: 'always' }]],
              [[{ changes: { paths: %w[*/**/*.rb *.yml] },           when: 'never' }, { changes: { paths: %w[*/**/*.rb *.yml] },           when: 'always' }]],
              [[{ changes: { paths: %w[.*.yml **/*] },               when: 'never' }, { changes: { paths: %w[.*.yml **/*] },               when: 'always' }]]
            ]
          end

          with_them do
            it { is_expected.not_to be_included }

            it 'correctly populates when:' do
              expect(seed_build.attributes).to include(when: 'never')
            end
          end
        end

        context 'with an explicit `when: always`' do
          where(:rule_set) do
            [
              [[{ changes: { paths: %w[*/**/*.rb] },                 when: 'always' }, { changes: { paths: %w[*/**/*.rb] },                 when: 'never' }]],
              [[{ changes: { paths: %w[app/models/ci/pipeline.rb] }, when: 'always' }, { changes: { paths: %w[app/models/ci/pipeline.rb] }, when: 'never' }]],
              [[{ changes: { paths: %w[spec/**/*.rb] },              when: 'always' }, { changes: { paths: %w[spec/**/*.rb] },              when: 'never' }]],
              [[{ changes: { paths: %w[*.yml] },                     when: 'always' }, { changes: { paths: %w[*.yml] },                     when: 'never' }]],
              [[{ changes: { paths: %w[.*.yml] },                    when: 'always' }, { changes: { paths: %w[.*.yml] },                    when: 'never' }]],
              [[{ changes: { paths: %w[**/*] },                      when: 'always' }, { changes: { paths: %w[**/*] },                      when: 'never' }]],
              [[{ changes: { paths: %w[*/**/*.rb *.yml] },           when: 'always' }, { changes: { paths: %w[*/**/*.rb *.yml] },           when: 'never' }]],
              [[{ changes: { paths: %w[.*.yml **/*] },               when: 'always' }, { changes: { paths: %w[.*.yml **/*] },               when: 'never' }]]
            ]
          end

          with_them do
            it { is_expected.to be_included }

            it 'correctly populates when:' do
              expect(seed_build.attributes).to include(when: 'always')
            end
          end
        end

        context 'without an explicit when: value' do
          where(:rule_set) do
            [
              [[{ changes:  { paths: %w[*/**/*.rb] }                 }]],
              [[{ changes:  { paths: %w[app/models/ci/pipeline.rb] } }]],
              [[{ changes:  { paths: %w[spec/**/*.rb] }              }]],
              [[{ changes:  { paths: %w[*.yml] }                     }]],
              [[{ changes:  { paths: %w[.*.yml] }                    }]],
              [[{ changes:  { paths: %w[**/*] }                      }]],
              [[{ changes:  { paths: %w[*/**/*.rb *.yml] }           }]],
              [[{ changes:  { paths: %w[.*.yml **/*] }               }]]
            ]
          end

          with_them do
            it { is_expected.to be_included }

            it 'correctly populates when:' do
              expect(seed_build.attributes).to include(when: 'on_success')
            end
          end
        end
      end

      context 'with no matching rule' do
        where(:rule_set) do
          [
            [[{ if: '$VARIABLE != null',              when: 'never'  }]],
            [[{ if: '$VARIABLE != null',              when: 'never'  }, { if: '$VARIABLE != null', when: 'always' }]],
            [[{ if: '$VARIABLE == "the wrong value"', when: 'never'  }, { if: '$VARIABLE != null', when: 'always' }]],
            [[{ if: '$VARIABLE != null',              when: 'always' }]],
            [[{ if: '$VARIABLE != null',              when: 'always' }, { if: '$VARIABLE != null', when: 'never' }]],
            [[{ if: '$VARIABLE == "the wrong value"', when: 'always' }, { if: '$VARIABLE != null', when: 'never' }]],
            [[{ if: '$VARIABLE != null'                              }]],
            [[{ if: '$VARIABLE != null'                              }, { if: '$VARIABLE != null' }]],
            [[{ if: '$VARIABLE == "the wrong value"'                 }, { if: '$VARIABLE != null' }]]
          ]
        end

        with_them do
          it { is_expected.not_to be_included }

          it 'correctly populates when:' do
            expect(seed_build.attributes).to include(when: 'never')
          end
        end
      end

      context 'with a rule using CI_ENVIRONMENT_NAME variable' do
        let(:rule_set) do
          [{ if: '$CI_ENVIRONMENT_NAME == "test"' }]
        end

        context 'when environment:name satisfies the rule' do
          let(:attributes) { { name: 'rspec', rules: rule_set, environment: 'test', when: 'on_success' } }

          it { is_expected.to be_included }

          it 'correctly populates when:' do
            expect(seed_build.attributes).to include(when: 'on_success')
          end
        end

        context 'when environment:name does not satisfy rule' do
          let(:attributes) { { name: 'rspec', rules: rule_set, environment: 'dev', when: 'on_success' } }

          it { is_expected.not_to be_included }

          it 'correctly populates when:' do
            expect(seed_build.attributes).to include(when: 'never')
          end
        end

        context 'when environment:name is not set' do
          it { is_expected.not_to be_included }

          it 'correctly populates when:' do
            expect(seed_build.attributes).to include(when: 'never')
          end
        end
      end

      context 'with a rule using CI_ENVIRONMENT_ACTION variable' do
        let(:rule_set) do
          [{ if: '$CI_ENVIRONMENT_ACTION == "start"' }]
        end

        context 'when environment:action satisfies the rule' do
          let(:attributes) do
            { name: 'rspec', rules: rule_set, environment: 'test', when: 'on_success',
              options: { environment: { action: 'start' } } }
          end

          it { is_expected.to be_included }

          it 'correctly populates when:' do
            expect(seed_build.attributes).to include(when: 'on_success')
          end
        end

        context 'when environment:action does not satisfy rule' do
          let(:attributes) do
            { name: 'rspec', rules: rule_set, environment: 'test', when: 'on_success',
              options: { environment: { action: 'stop' } } }
          end

          it { is_expected.not_to be_included }

          it 'correctly populates when:' do
            expect(seed_build.attributes).to include(when: 'never')
          end
        end

        context 'when environment:action is not set' do
          it { is_expected.not_to be_included }

          it 'correctly populates when:' do
            expect(seed_build.attributes).to include(when: 'never')
          end
        end
      end

      context 'with a rule using CI_ENVIRONMENT_TIER variable' do
        let(:rule_set) do
          [{ if: '$CI_ENVIRONMENT_TIER == "production"' }]
        end

        context 'when environment:deployment_tier satisfies the rule' do
          let(:attributes) do
            { name: 'rspec', rules: rule_set, environment: 'test', when: 'on_success',
              options: { environment: { deployment_tier: 'production' } } }
          end

          it { is_expected.to be_included }

          it 'correctly populates when:' do
            expect(seed_build.attributes).to include(when: 'on_success')
          end
        end

        context 'when environment:deployment_tier does not satisfy rule' do
          let(:attributes) do
            { name: 'rspec', rules: rule_set, environment: 'test', when: 'on_success',
              options: { environment: { deployment_tier: 'development' } } }
          end

          it { is_expected.not_to be_included }

          it 'correctly populates when:' do
            expect(seed_build.attributes).to include(when: 'never')
          end
        end

        context 'when environment:action is not set' do
          it { is_expected.not_to be_included }

          it 'correctly populates when:' do
            expect(seed_build.attributes).to include(when: 'never')
          end
        end
      end

      context 'with a rule using CI_ENVIRONMENT_URL variable' do
        let(:rule_set) do
          [{ if: '$CI_ENVIRONMENT_URL == "http://gitlab.com"' }]
        end

        context 'when environment:url satisfies the rule' do
          let(:attributes) do
            { name: 'rspec', rules: rule_set, environment: 'test', when: 'on_success',
              options: { environment: { url: 'http://gitlab.com' } } }
          end

          it { is_expected.to be_included }

          it 'correctly populates when:' do
            expect(seed_build.attributes).to include(when: 'on_success')
          end
        end

        context 'when environment:url does not satisfy rule' do
          let(:attributes) do
            { name: 'rspec', rules: rule_set, environment: 'test', when: 'on_success',
              options: { environment: { url: 'http://staging.gitlab.com' } } }
          end

          it { is_expected.not_to be_included }

          it 'correctly populates when:' do
            expect(seed_build.attributes).to include(when: 'never')
          end
        end

        context 'when environment:action is not set' do
          it { is_expected.not_to be_included }

          it 'correctly populates when:' do
            expect(seed_build.attributes).to include(when: 'never')
          end
        end
      end

      context 'with no rules' do
        let(:rule_set) { [] }

        it { is_expected.not_to be_included }

        it 'correctly populates when:' do
          expect(seed_build.attributes).to include(when: 'never')
        end
      end

      context 'with invalid rules raising error' do
        let(:rule_set) do
          [
            { changes: { paths: ['README.md'], compare_to: 'invalid-ref' }, when: 'never' }
          ]
        end

        it { is_expected.not_to be_included }

        it 'correctly populates when:' do
          expect(seed_build.attributes).to include(when: 'never')
        end

        it 'returns an error' do
          expect(seed_build.errors).to contain_exactly(
            'Failed to parse rule for rspec: rules:changes:compare_to is not a valid ref'
          )
        end
      end
    end
  end

  describe 'applying needs: dependency' do
    subject { seed_build }

    let(:needs_count) { 1 }

    let(:needs_attributes) do
      Array.new(needs_count, name: 'build')
    end

    let(:attributes) do
      {
        name: 'rspec',
        needs_attributes: needs_attributes
      }
    end

    context 'when build job is not present in prior stages' do
      it "is included" do
        is_expected.to be_included
      end

      it "returns an error" do
        expect(subject.errors).to contain_exactly(
          "'rspec' job needs 'build' job, but 'build' does not exist in the pipeline. " \
            'This might be because of the only, except, or rules keywords. ' \
            'To need a job that sometimes does not exist in the pipeline, use needs:optional.'
        )
      end

      context 'when the needed job is optional' do
        let(:needs_attributes) { [{ name: 'build', optional: true }] }

        it "does not return an error" do
          expect(subject.errors).to be_empty
        end
      end
    end

    context 'when build job is part of prior stages' do
      let(:stage_attributes) do
        {
          name: 'build',
          index: 0,
          builds: [{ name: 'build' }]
        }
      end

      let(:stage_seed) do
        Gitlab::Ci::Pipeline::Seed::Stage.new(seed_context, stage_attributes, [])
      end

      let(:previous_stages) { [stage_seed] }

      it "is included" do
        is_expected.to be_included
      end

      it "does not have errors" do
        expect(subject.errors).to be_empty
      end
    end

    context 'when build job is part of the same stage' do
      let(:current_stage) { double(seeds_names: [attributes[:name], 'build']) }

      it 'is included' do
        is_expected.to be_included
      end

      it 'does not have errors' do
        expect(subject.errors).to be_empty
      end
    end

    context 'when using 101 needs' do
      let(:needs_count) { 101 }

      it "returns an error" do
        expect(subject.errors).to contain_exactly(
          "rspec: one job can only need 50 others, but you have listed 101. See needs keyword documentation for more details")
      end

      context 'when ci_needs_size_limit is set to 100' do
        before do
          project.actual_limits.update!(ci_needs_size_limit: 100)
        end

        it "returns an error" do
          expect(subject.errors).to contain_exactly(
            "rspec: one job can only need 100 others, but you have listed 101. See needs keyword documentation for more details")
        end
      end

      context 'when ci_needs_size_limit is set to 0' do
        before do
          project.actual_limits.update!(ci_needs_size_limit: 0)
        end

        it "returns an error" do
          expect(subject.errors).to contain_exactly(
            "rspec: one job can only need 0 others, but you have listed 101. See needs keyword documentation for more details")
        end
      end
    end
  end

  describe 'applying pipeline variables' do
    subject { seed_build }

    let(:pipeline_variables) { [] }
    let(:pipeline) do
      build(:ci_empty_pipeline, project: project, sha: head_sha, variables: pipeline_variables)
    end

    context 'containing variable references' do
      let(:pipeline_variables) do
        [
          build(:ci_pipeline_variable, key: 'A', value: '$B'),
          build(:ci_pipeline_variable, key: 'B', value: '$C')
        ]
      end

      it "does not have errors" do
        expect(subject.errors).to be_empty
      end
    end

    context 'containing cyclic reference' do
      let(:pipeline_variables) do
        [
          build(:ci_pipeline_variable, key: 'A', value: '$B'),
          build(:ci_pipeline_variable, key: 'B', value: '$C'),
          build(:ci_pipeline_variable, key: 'C', value: '$A')
        ]
      end

      it "returns an error" do
        expect(subject.errors).to contain_exactly(
          'rspec: circular variable reference detected: ["A", "B", "C"]')
      end

      context 'with job:rules:[if:]' do
        let(:attributes) { { name: 'rspec', ref: 'master', rules: [{ if: '$C != null', when: 'always' }] } }

        it "included? does not raise" do
          expect { subject.included? }.not_to raise_error
        end

        it "included? returns true" do
          expect(subject.included?).to eq(true)
        end
      end
    end
  end
end
