require 'spec_helper'

describe Project, models: true do
  describe '#secret_variables_for' do
    let(:project) { create(:empty_project) }

    let!(:secret_variable) do
      create(:ci_variable, value: 'secret', project: project)
    end

    let!(:protected_variable) do
      create(:ci_variable, :protected, value: 'protected', project: project)
    end

    subject { project.secret_variables_for(ref: 'ref') }

    before do
      stub_application_setting(
        default_branch_protection: Gitlab::Access::PROTECTION_NONE)
    end

    context 'when environment is specified' do
      let(:environment) { create(:environment, name: 'review/name') }

      subject do
        project.secret_variables_for(ref: 'ref', environment: environment)
      end

      before do
        # Skip this validation so that we could test for existing data
        allow_any_instance_of(Ci::Variable)
          .to receive(:verify_updating_environment_scope).and_return(true)
      end

      shared_examples 'matching environment scope' do
        context 'when variable environment scope is available' do
          before do
            stub_feature(:variable_environment_scope, true)
          end

          it 'contains the secret variable' do
            is_expected.to contain_exactly(secret_variable)
          end
        end

        context 'when variable environment scope is unavailable' do
          before do
            stub_feature(:variable_environment_scope, false)
          end

          it 'does not contain the secret variable' do
            is_expected.not_to contain_exactly(secret_variable)
          end
        end
      end

      shared_examples 'not matching environment scope' do
        context 'when variable environment scope is available' do
          before do
            stub_feature(:variable_environment_scope, true)
          end

          it 'does not contain the secret variable' do
            is_expected.not_to contain_exactly(secret_variable)
          end
        end

        context 'when variable environment scope is unavailable' do
          before do
            stub_feature(:variable_environment_scope, false)
          end

          it 'does not contain the secret variable' do
            is_expected.not_to contain_exactly(secret_variable)
          end
        end
      end

      context 'when environment scope is exactly matched' do
        before do
          secret_variable.update(environment_scope: 'review/name')
        end

        it_behaves_like 'matching environment scope'
      end

      context 'when environment scope is matched by wildcard' do
        before do
          secret_variable.update(environment_scope: 'review/*')
        end

        it_behaves_like 'matching environment scope'
      end

      context 'when environment scope does not match' do
        before do
          secret_variable.update(environment_scope: 'review/*/special')
        end

        it_behaves_like 'not matching environment scope'
      end

      context 'when environment scope has _' do
        before do
          stub_feature(:variable_environment_scope, true)
        end

        it 'does not treat it as wildcard' do
          secret_variable.update(environment_scope: '*_*')

          is_expected.not_to contain_exactly(secret_variable)
        end

        it 'matches literally for _' do
          secret_variable.update(environment_scope: 'foo_bar/*')
          environment.update(name: 'foo_bar/test')

          is_expected.to contain_exactly(secret_variable)
        end
      end

      # The environment name and scope cannot have % at the moment,
      # but we're considering relaxing it and we should also make sure
      # it doesn't break in case some data sneaked in somehow as we're
      # not checking this integrity in database level.
      context 'when environment scope has %' do
        before do
          stub_feature(:variable_environment_scope, true)
        end

        it 'does not treat it as wildcard' do
          secret_variable.update_attribute(:environment_scope, '*%*')

          is_expected.not_to contain_exactly(secret_variable)
        end

        it 'matches literally for _' do
          secret_variable.update(environment_scope: 'foo%bar/*')
          environment.update_attribute(:name, 'foo%bar/test')

          is_expected.to contain_exactly(secret_variable)
        end
      end

      context 'when variables with the same name have different environment scopes' do
        let!(:partially_matched_variable) do
          create(:ci_variable,
                 key: secret_variable.key,
                 value: 'partial',
                 environment_scope: 'review/*',
                 project: project)
        end

        let!(:perfectly_matched_variable) do
          create(:ci_variable,
                 key: secret_variable.key,
                 value: 'prefect',
                 environment_scope: 'review/name',
                 project: project)
        end

        before do
          stub_feature(:variable_environment_scope, true)
        end

        it 'puts variables matching environment scope more in the end' do
          is_expected.to eq(
            [secret_variable,
             partially_matched_variable,
             perfectly_matched_variable])
        end
      end
    end
  end
end
