# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Pipeline::Seed::Build do
  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:head_sha) { project.repository.head_commit.id }

  let(:pipeline) { build(:ci_empty_pipeline, project: project, sha: head_sha) }
  let(:root_variables) { [] }
  let(:seed_context) { double(pipeline: pipeline, root_variables: root_variables) }
  let(:attributes) { { name: 'rspec', ref: 'master', scheduling_type: :stage } }
  let(:previous_stages) { [] }
  let(:current_stage) { double(seeds_names: [attributes[:name]]) }

  let(:seed_build) { described_class.new(seed_context, attributes, previous_stages, current_stage) }

  describe '#attributes' do
    subject { seed_build.attributes }

    it { is_expected.to be_a(Hash) }
    it { is_expected.to include(:name, :project, :ref) }

    context 'with job:when' do
      let(:attributes) { { name: 'rspec', ref: 'master', when: 'on_failure' } }

      it { is_expected.to include(when: 'on_failure') }
    end

    context 'with job:when:delayed' do
      let(:attributes) { { name: 'rspec', ref: 'master', when: 'delayed', start_in: '3 hours' } }

      it { is_expected.to include(when: 'delayed', start_in: '3 hours') }
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

    context 'with job:rules but no explicit when:' do
      context 'is matched' do
        let(:attributes) { { name: 'rspec', ref: 'master', rules: [{ if: '$VAR == null' }] } }

        it { is_expected.to include(when: 'on_success') }
      end

      context 'is not matched' do
        let(:attributes) { { name: 'rspec', ref: 'master', rules: [{ if: '$VAR != null' }] } }

        it { is_expected.to include(when: 'never') }
      end
    end

    context 'with job:rules:[variables:]' do
      let(:attributes) do
        { name: 'rspec',
          ref: 'master',
          job_variables: [{ key: 'VAR1', value: 'var 1', public: true },
                          { key: 'VAR2', value: 'var 2', public: true }],
          rules: [{ if: '$VAR == null', variables: { VAR1: 'new var 1', VAR3: 'var 3' } }] }
      end

      it do
        is_expected.to include(yaml_variables: [{ key: 'VAR1', value: 'new var 1', public: true },
                                                { key: 'VAR2', value: 'var 2', public: true },
                                                { key: 'VAR3', value: 'var 3', public: true }])
      end
    end

    context 'with job:tags' do
      let(:attributes) do
        {
          name: 'rspec',
          ref: 'master',
          job_variables: [{ key: 'VARIABLE', value: 'value', public: true }],
          tag_list: ['static-tag', '$VARIABLE', '$NO_VARIABLE']
        }
      end

      it { is_expected.to include(tag_list: ['static-tag', 'value', '$NO_VARIABLE']) }
      it { is_expected.to include(yaml_variables: [{ key: 'VARIABLE', value: 'value', public: true }]) }
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
              cache: [a_hash_including(key: 'f155568ad0933d8358f66b846133614f76dd0ca4')]
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

        it { is_expected.to include(options: { cache: [a_hash_including( key: 'something-default' )] }) }
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
          yaml_variables: [{ key: 'VAR2', value: 'var 2', public: true },
                           { key: 'VAR3', value: 'var 3', public: true }],
          job_variables: [{ key: 'VAR2', value: 'var 2', public: true },
                          { key: 'VAR3', value: 'var 3', public: true }],
          root_variables_inheritance: root_variables_inheritance }
      end

      context 'when the pipeline has variables' do
        let(:root_variables) do
          [{ key: 'VAR1', value: 'var overridden pipeline 1', public: true },
           { key: 'VAR2', value: 'var pipeline 2', public: true },
           { key: 'VAR3', value: 'var pipeline 3', public: true },
           { key: 'VAR4', value: 'new var pipeline 4', public: true }]
        end

        context 'when root_variables_inheritance is true' do
          let(:root_variables_inheritance) { true }

          it 'returns calculated yaml variables' do
            expect(subject[:yaml_variables]).to match_array(
              [{ key: 'VAR1', value: 'var overridden pipeline 1', public: true },
               { key: 'VAR2', value: 'var 2', public: true },
               { key: 'VAR3', value: 'var 3', public: true },
               { key: 'VAR4', value: 'new var pipeline 4', public: true }]
            )
          end
        end

        context 'when root_variables_inheritance is false' do
          let(:root_variables_inheritance) { false }

          it 'returns job variables' do
            expect(subject[:yaml_variables]).to match_array(
              [{ key: 'VAR2', value: 'var 2', public: true },
               { key: 'VAR3', value: 'var 3', public: true }]
            )
          end
        end

        context 'when root_variables_inheritance is an array' do
          let(:root_variables_inheritance) { %w(VAR1 VAR2 VAR3) }

          it 'returns calculated yaml variables' do
            expect(subject[:yaml_variables]).to match_array(
              [{ key: 'VAR1', value: 'var overridden pipeline 1', public: true },
               { key: 'VAR2', value: 'var 2', public: true },
               { key: 'VAR3', value: 'var 3', public: true }]
            )
          end
        end
      end

      context 'when the pipeline has not a variable' do
        let(:root_variables_inheritance) { true }

        it 'returns seed yaml variables' do
          expect(subject[:yaml_variables]).to match_array(
            [{ key: 'VAR2', value: 'var 2', public: true },
             { key: 'VAR3', value: 'var 3', public: true }])
        end
      end
    end

    context 'when the job rule depends on variables' do
      let(:attributes) do
        { name: 'rspec',
          ref: 'master',
          yaml_variables: [{ key: 'VAR1', value: 'var 1', public: true }],
          job_variables: [{ key: 'VAR1', value: 'var 1', public: true }],
          root_variables_inheritance: root_variables_inheritance,
          rules: rules }
      end

      let(:root_variables_inheritance) { true }

      context 'when the rules use job variables' do
        let(:rules) do
          [{ if: '$VAR1 == "var 1"', variables: { VAR1: 'overridden var 1', VAR2: 'new var 2' } }]
        end

        it 'recalculates the variables' do
          expect(subject[:yaml_variables]).to contain_exactly({ key: 'VAR1', value: 'overridden var 1', public: true },
                                                              { key: 'VAR2', value: 'new var 2', public: true })
        end
      end

      context 'when the rules use root variables' do
        let(:root_variables) do
          [{ key: 'VAR2', value: 'var pipeline 2', public: true }]
        end

        let(:rules) do
          [{ if: '$VAR2 == "var pipeline 2"', variables: { VAR1: 'overridden var 1', VAR2: 'overridden var 2' } }]
        end

        it 'recalculates the variables' do
          expect(subject[:yaml_variables]).to contain_exactly({ key: 'VAR1', value: 'overridden var 1', public: true },
                                                              { key: 'VAR2', value: 'overridden var 2', public: true })
        end

        context 'when the root_variables_inheritance is false' do
          let(:root_variables_inheritance) { false }

          it 'does not recalculate the variables' do
            expect(subject[:yaml_variables]).to contain_exactly({ key: 'VAR1', value: 'var 1', public: true })
          end
        end
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

    context 'when job is not a bridge' do
      it { is_expected.to be_a(::Ci::Build) }
      it { is_expected.to be_valid }

      shared_examples_for 'deployment job' do
        it 'returns a job with deployment' do
          expect(subject.deployment).not_to be_nil
          expect(subject.deployment.deployable).to eq(subject)
          expect(subject.deployment.environment.name).to eq(expected_environment_name)
        end
      end

      shared_examples_for 'non-deployment job' do
        it 'returns a job without deployment' do
          expect(subject.deployment).to be_nil
        end
      end

      shared_examples_for 'ensures environment existence' do
        it 'has environment' do
          expect(subject).to be_has_environment
          expect(subject.environment).to eq(environment_name)
          expect(subject.metadata.expanded_environment_name).to eq(expected_environment_name)
          expect(Environment.exists?(name: expected_environment_name)).to eq(true)
        end
      end

      shared_examples_for 'ensures environment inexistence' do
        it 'does not have environment' do
          expect(subject).not_to be_has_environment
          expect(subject.environment).to be_nil
          expect(subject.metadata&.expanded_environment_name).to be_nil
          expect(Environment.exists?(name: expected_environment_name)).to eq(false)
        end
      end

      context 'when job deploys to production' do
        let(:environment_name) { 'production' }
        let(:expected_environment_name) { 'production' }
        let(:attributes) { { name: 'deploy', ref: 'master', environment: 'production' } }

        it_behaves_like 'deployment job'
        it_behaves_like 'ensures environment existence'

        context 'when the environment name is invalid' do
          let(:attributes) { { name: 'deploy', ref: 'master', environment: '!!!' } }

          it_behaves_like 'non-deployment job'
          it_behaves_like 'ensures environment inexistence'

          it 'tracks an exception' do
            expect(Gitlab::ErrorTracking).to receive(:track_exception)
              .with(an_instance_of(described_class::EnvironmentCreationFailure),
                    project_id: project.id,
                    reason: %q{Name can contain only letters, digits, '-', '_', '/', '$', '{', '}', '.', and spaces, but it cannot start or end with '/'})
              .once

            subject
          end
        end
      end

      context 'when job starts a review app' do
        let(:environment_name) { 'review/$CI_COMMIT_REF_NAME' }
        let(:expected_environment_name) { "review/#{pipeline.ref}" }

        let(:attributes) do
          {
            name: 'deploy', ref: 'master', environment: environment_name,
            options: { environment: { name: environment_name } }
          }
        end

        it_behaves_like 'deployment job'
        it_behaves_like 'ensures environment existence'
      end

      context 'when job stops a review app' do
        let(:environment_name) { 'review/$CI_COMMIT_REF_NAME' }
        let(:expected_environment_name) { "review/#{pipeline.ref}" }

        let(:attributes) do
          {
            name: 'deploy', ref: 'master', environment: environment_name,
            options: { environment: { name: environment_name, action: 'stop' } }
          }
        end

        it 'returns a job without deployment' do
          expect(subject.deployment).to be_nil
        end

        it_behaves_like 'non-deployment job'
        it_behaves_like 'ensures environment existence'
      end

      context 'when job belongs to a resource group' do
        let(:attributes) { { name: 'rspec', ref: 'master', resource_group_key: 'iOS' } }

        it 'returns a job with resource group' do
          expect(subject.resource_group).not_to be_nil
          expect(subject.resource_group.key).to eq('iOS')
        end
      end
    end

    context 'when job is a bridge' do
      let(:base_attributes) do
        {
          name: 'rspec', ref: 'master', options: { trigger: 'my/project' }, scheduling_type: :stage
        }
      end

      let(:attributes) { base_attributes }

      it { is_expected.to be_a(::Ci::Bridge) }
      it { is_expected.to be_valid }

      context 'when job belongs to a resource group' do
        let(:attributes) { base_attributes.merge(resource_group_key: 'iOS') }

        it 'returns a job with resource group' do
          expect(subject.resource_group).not_to be_nil
          expect(subject.resource_group.key).to eq('iOS')
        end
      end
    end

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
          %w[web trigger schedule api external].map  { |source| ['pushes', source] } +
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

      let(:attributes) { { name: 'rspec', rules: rule_set } }

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

            it 'correctly populates when:' do
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
              [[{ if: '$VARIABLE == "the wrong value"', when: 'delayed', start_in: '1 day' }, { if: '$CI_BUILD_NAME == "rspec"', when: 'on_failure' }]]
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
              [[{ changes: %w[*/**/*.rb],                 when: 'never' }, { changes: %w[*/**/*.rb],                 when: 'always' }]],
              [[{ changes: %w[app/models/ci/pipeline.rb], when: 'never' }, { changes: %w[app/models/ci/pipeline.rb], when: 'always' }]],
              [[{ changes: %w[spec/**/*.rb],              when: 'never' }, { changes: %w[spec/**/*.rb],              when: 'always' }]],
              [[{ changes: %w[*.yml],                     when: 'never' }, { changes: %w[*.yml],                     when: 'always' }]],
              [[{ changes: %w[.*.yml],                    when: 'never' }, { changes: %w[.*.yml],                    when: 'always' }]],
              [[{ changes: %w[**/*],                      when: 'never' }, { changes: %w[**/*],                      when: 'always' }]],
              [[{ changes: %w[*/**/*.rb *.yml],           when: 'never' }, { changes: %w[*/**/*.rb *.yml],           when: 'always' }]],
              [[{ changes: %w[.*.yml **/*],               when: 'never' }, { changes: %w[.*.yml **/*],               when: 'always' }]]
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
              [[{ changes: %w[*/**/*.rb],                 when: 'always' }, { changes: %w[*/**/*.rb],                 when: 'never' }]],
              [[{ changes: %w[app/models/ci/pipeline.rb], when: 'always' }, { changes: %w[app/models/ci/pipeline.rb], when: 'never' }]],
              [[{ changes: %w[spec/**/*.rb],              when: 'always' }, { changes: %w[spec/**/*.rb],              when: 'never' }]],
              [[{ changes: %w[*.yml],                     when: 'always' }, { changes: %w[*.yml],                     when: 'never' }]],
              [[{ changes: %w[.*.yml],                    when: 'always' }, { changes: %w[.*.yml],                    when: 'never' }]],
              [[{ changes: %w[**/*],                      when: 'always' }, { changes: %w[**/*],                      when: 'never' }]],
              [[{ changes: %w[*/**/*.rb *.yml],           when: 'always' }, { changes: %w[*/**/*.rb *.yml],           when: 'never' }]],
              [[{ changes: %w[.*.yml **/*],               when: 'always' }, { changes: %w[.*.yml **/*],               when: 'never' }]]
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
              [[{ changes: %w[*/**/*.rb]                 }]],
              [[{ changes: %w[app/models/ci/pipeline.rb] }]],
              [[{ changes: %w[spec/**/*.rb]              }]],
              [[{ changes: %w[*.yml]                     }]],
              [[{ changes: %w[.*.yml]                    }]],
              [[{ changes: %w[**/*]                      }]],
              [[{ changes: %w[*/**/*.rb *.yml]           }]],
              [[{ changes: %w[.*.yml **/*]               }]]
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

      context 'with no rules' do
        let(:rule_set) { [] }

        it { is_expected.not_to be_included }

        it 'correctly populates when:' do
          expect(seed_build.attributes).to include(when: 'never')
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
          "'rspec' job needs 'build' job, but 'build' is not in any previous stage")
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

      context 'when ci_same_stage_job_needs FF is disabled' do
        before do
          stub_feature_flags(ci_same_stage_job_needs: false)
        end

        it 'has errors' do
          expect(subject.errors).to contain_exactly("'rspec' job needs 'build' job, but 'build' is not in any previous stage")
        end
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

      context 'when FF :variable_inside_variable is enabled' do
        before do
          stub_feature_flags(variable_inside_variable: [project])
        end

        it "does not have errors" do
          expect(subject.errors).to be_empty
        end
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

      context 'when FF :variable_inside_variable is disabled' do
        before do
          stub_feature_flags(variable_inside_variable: false)
        end

        it "does not have errors" do
          expect(subject.errors).to be_empty
        end
      end

      context 'when FF :variable_inside_variable is enabled' do
        before do
          stub_feature_flags(variable_inside_variable: [project])
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
end
