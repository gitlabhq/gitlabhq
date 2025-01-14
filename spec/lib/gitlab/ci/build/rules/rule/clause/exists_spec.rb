# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Build::Rules::Rule::Clause::Exists, feature_category: :pipeline_composition do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, :small_repo, files: { 'subdir/my_file.txt' => '' }) }
  let_it_be(:other_project) { create(:project, :small_repo, files: { 'file.txt' => '' }) }
  let(:pipeline) { instance_double(Ci::Pipeline, project: project, sha: 'sha', user: user) }

  let(:variables) do
    Gitlab::Ci::Variables::Collection.new([
      { key: 'SUBDIR', value: 'subdir' },
      { key: 'FILE_TXT', value: 'file.txt' },
      { key: 'FULL_PATH_VALID', value: 'subdir/my_file.txt' },
      { key: 'FULL_PATH_INVALID', value: 'subdir/does_not_exist.txt' },
      { key: 'NESTED_FULL_PATH_VALID', value: '$SUBDIR/my_file.txt' },
      { key: 'NEW_BRANCH', value: 'new_branch' },
      { key: 'MASKED_VAR', value: 'masked_value', masked: true }
    ])
  end

  let(:globs) {}
  let(:project_path) {}
  let(:ref) {}
  let(:clause) { { paths: globs, project: project_path, ref: ref }.compact }

  before_all do
    other_project.repository.add_branch(user, 'new_branch', other_project.default_branch)
    other_project.repository.create_file(user, 'file_on_new_branch.txt', '', message: 'Test', branch_name: 'new_branch')
  end

  describe '#satisfied_by?' do
    subject(:satisfied_by?) { described_class.new(clause).satisfied_by?(pipeline, context) }

    before do
      allow(context).to receive(:variables).and_return(variables)
    end

    context 'when there are no globs' do
      let(:globs) { [] }
      let(:context) { Gitlab::Ci::Config::External::Context.new(project: project) }

      it { is_expected.to be_falsey }

      it 'does not fetch worktree paths' do
        expect(context).not_to receive(:top_level_worktree_paths)

        satisfied_by?
      end
    end

    shared_examples 'a rules:exists with a context' do
      it_behaves_like 'a glob matching rule' do
        let(:project) { create(:project, :small_repo, files: files) }
      end

      context 'when a file path is in a variable' do
        let(:globs) { ['$FULL_PATH_VALID'] }

        context 'when the variable matches' do
          it { is_expected.to be_truthy }
        end

        context 'when the variable does not match' do
          let(:globs) { ['$FULL_PATH_INVALID'] }

          it { is_expected.to be_falsey }
        end

        context 'when the variable is nested and matches' do
          let(:globs) { ['$NESTED_FULL_PATH_VALID'] }

          it { is_expected.to be_truthy }
        end
      end

      context 'when a file path has a variable' do
        let(:globs) { ['$SUBDIR/**/*'] }

        context 'when the variable matches' do
          it { is_expected.to be_truthy }
        end

        context 'when the variable does not match' do
          let(:globs) { ['$UNKNOWN/**/*'] }

          it { is_expected.to be_falsey }
        end
      end

      context 'when the pattern comparision limit is reached' do
        let_it_be(:project) { create(:project, :repository) }
        let(:globs) { ['*definitely_not_a_matching_glob*'] }

        before do
          stub_const('Gitlab::Ci::Build::Rules::Rule::Clause::Exists::MAX_PATTERN_COMPARISONS', 2)
          expect(File).not_to receive(:fnmatch?)
        end

        it { is_expected.to be_truthy }

        it 'logs the pattern comparison limit exceeded' do
          expect(Gitlab::AppJsonLogger).to receive(:info).with(
            class: described_class.name,
            message: 'rules:exists pattern comparisons limit exceeded',
            project_id: project.id,
            paths_size: kind_of(Integer),
            globs_size: 1,
            comparisons: kind_of(Integer)
          )

          satisfied_by?
        end
      end

      context 'when rules:exists:project is provided' do
        let(:globs) { ['file.txt'] }
        let(:project_path) { other_project.full_path }

        context 'when the user has access to the project' do
          before_all do
            other_project.add_developer(user)
          end

          it { is_expected.to be_truthy }

          context 'when the file does not exist on the project' do
            let(:globs) { ['file_does_not_exist.txt'] }

            it { is_expected.to be_falsey }
          end

          context 'when the project path contains a variable' do
            let(:globs) { ['$FILE_TXT'] }

            it { is_expected.to be_truthy }
          end

          context 'when the project path is invalid' do
            let(:project_path) { 'invalid/path' }

            it 'raises an error' do
              expect { satisfied_by? }.to raise_error(
                Gitlab::Ci::Build::Rules::Rule::Clause::ParseError,
                "rules:exists:project `invalid/path` not found or access denied"
              )
            end

            context 'when the project path contains a variable' do
              let(:project_path) { 'invalid/path/$SUBDIR' }

              it 'raises an error' do
                expect { satisfied_by? }.to raise_error(
                  Gitlab::Ci::Build::Rules::Rule::Clause::ParseError,
                  "rules:exists:project `invalid/path/subdir` not found or access denied"
                )
              end
            end

            context 'when the project path contains a masked variable' do
              let(:project_path) { 'invalid/path/$MASKED_VAR' }

              it 'raises an error with the variable masked' do
                expect { satisfied_by? }.to raise_error(
                  Gitlab::Ci::Build::Rules::Rule::Clause::ParseError,
                  "rules:exists:project `invalid/path/[MASKED]xxxx` not found or access denied"
                )
              end
            end
          end

          context 'with ref:' do
            let(:globs) { ['file_on_new_branch.txt'] }
            let(:ref) { 'new_branch' }

            it { is_expected.to be_truthy }

            context 'when the file does not exist on the ref' do
              let(:ref) { other_project.commit.sha }

              it { is_expected.to be_falsey }
            end

            context 'when the ref contains a variable' do
              let(:ref) { '$NEW_BRANCH' }

              it { is_expected.to be_truthy }
            end

            context 'when the ref is invalid' do
              let(:ref) { 'invalid/ref' }

              it 'raises an error' do
                expect { satisfied_by? }.to raise_error(
                  Gitlab::Ci::Build::Rules::Rule::Clause::ParseError,
                  "rules:exists:ref `invalid/ref` is not a valid ref in project `#{other_project.full_path}`"
                )
              end

              context 'when the ref contains a variable' do
                let(:ref) { 'invalid/ref/$NEW_BRANCH' }

                it 'raises an error' do
                  expect { satisfied_by? }.to raise_error(
                    Gitlab::Ci::Build::Rules::Rule::Clause::ParseError,
                    "rules:exists:ref `invalid/ref/new_branch` is not a valid ref " \
                    "in project `#{other_project.full_path}`"
                  )
                end
              end

              context 'when the ref contains a masked variable' do
                let(:ref) { 'invalid/ref/$MASKED_VAR' }

                it 'raises an error with the variable masked' do
                  expect { satisfied_by? }.to raise_error(
                    Gitlab::Ci::Build::Rules::Rule::Clause::ParseError,
                    "rules:exists:ref `invalid/ref/[MASKED]xxxx` is not a valid ref " \
                    "in project `#{other_project.full_path}`"
                  )
                end
              end
            end
          end
        end

        context 'when the user does not have access to the project' do
          it 'raises an error without leaking information' do
            expect { satisfied_by? }.to raise_error(
              Gitlab::Ci::Build::Rules::Rule::Clause::ParseError,
              "rules:exists:project `#{other_project.full_path}` not found or access denied"
            )
          end
        end
      end
    end

    context 'when the rules are being evaluated at job level' do
      let(:pipeline) { build(:ci_pipeline, project: project, sha: project.commit.sha, user: user) }
      let(:context) { Gitlab::Ci::Build::Context::Build.new(pipeline) }

      it_behaves_like 'a rules:exists with a context'
    end

    context 'when the rules are being evaluated for an entire pipeline' do
      let(:pipeline) { build(:ci_pipeline, project: project, sha: project.commit.sha, user: user) }
      let(:context) { Gitlab::Ci::Build::Context::Global.new(pipeline, yaml_variables: {}) }

      it_behaves_like 'a rules:exists with a context'
    end

    context 'when rules are being evaluated with `include`' do
      let(:context) do
        Gitlab::Ci::Config::External::Context.new(
          project: project, sha: project&.commit&.sha, user: user, variables: variables)
      end

      it_behaves_like 'a rules:exists with a context'

      context 'when context has no project' do
        let(:globs) { ['Dockerfile'] }
        let(:project) {}

        it { is_expected.to be_falsey }
      end
    end
  end
end
