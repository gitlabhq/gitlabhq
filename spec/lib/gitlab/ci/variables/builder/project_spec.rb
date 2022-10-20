# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Variables::Builder::Project do
  let_it_be(:project) { create(:project, :repository) }

  let(:builder) { described_class.new(project) }

  describe '#secret_variables' do
    let(:environment) { '*' }
    let(:protected_ref) { false }

    let_it_be(:variable) do
      create(:ci_variable,
        value: 'secret',
        project: project)
    end

    let_it_be(:protected_variable) do
      create(:ci_variable, :protected,
        value: 'protected',
        project: project)
    end

    let(:variable_item) { item(variable) }
    let(:protected_variable_item) { item(protected_variable) }

    subject do
      builder.secret_variables(
        environment: environment,
        protected_ref: protected_ref)
    end

    context 'when the ref is protected' do
      let(:protected_ref) { true }

      it 'contains all the variables' do
        is_expected.to contain_exactly(variable_item, protected_variable_item)
      end
    end

    context 'when the ref is not protected' do
      let(:protected_ref) { false }

      it 'contains only the unprotected variables' do
        is_expected.to contain_exactly(variable_item)
      end
    end

    context 'when environment name is specified' do
      let(:environment) { 'review/name' }

      before do
        Ci::Variable.update_all(environment_scope: environment_scope)
      end

      context 'when environment scope is exactly matched' do
        let(:environment_scope) { 'review/name' }

        it { is_expected.to contain_exactly(variable_item) }
      end

      context 'when environment scope is matched by wildcard' do
        let(:environment_scope) { 'review/*' }

        it { is_expected.to contain_exactly(variable_item) }
      end

      context 'when environment scope does not match' do
        let(:environment_scope) { 'review/*/special' }

        it { is_expected.not_to contain_exactly(variable_item) }
      end

      context 'when environment scope has _' do
        let(:environment_scope) { '*_*' }

        it 'does not treat it as wildcard' do
          is_expected.not_to contain_exactly(variable_item)
        end
      end

      context 'when environment name contains underscore' do
        let(:environment) { 'foo_bar/test' }
        let(:environment_scope) { 'foo_bar/*' }

        it 'matches literally for _' do
          is_expected.to contain_exactly(variable_item)
        end
      end

      # The environment name and scope cannot have % at the moment,
      # but we're considering relaxing it and we should also make sure
      # it doesn't break in case some data sneaked in somehow as we're
      # not checking this integrity in database level.
      context 'when environment scope has %' do
        let(:environment_scope) { '*%*' }

        it 'does not treat it as wildcard' do
          is_expected.not_to contain_exactly(variable_item)
        end
      end

      context 'when environment name contains a percent' do
        let(:environment) { 'foo%bar/test' }
        let(:environment_scope) { 'foo%bar/*' }

        it 'matches literally for _' do
          is_expected.to contain_exactly(variable_item)
        end
      end
    end

    context 'when variables with the same name have different environment scopes' do
      let(:environment) { 'review/name' }

      let_it_be(:partially_matched_variable) do
        create(:ci_variable,
          key: variable.key,
          value: 'partial',
          environment_scope: 'review/*',
          project: project)
      end

      let_it_be(:perfectly_matched_variable) do
        create(:ci_variable,
          key: variable.key,
          value: 'prefect',
          environment_scope: 'review/name',
          project: project)
      end

      it 'puts variables matching environment scope more in the end' do
        variables_collection = Gitlab::Ci::Variables::Collection.new(
          [
            variable,
            partially_matched_variable,
            perfectly_matched_variable
          ]).to_runner_variables

        expect(subject.to_runner_variables).to eq(variables_collection)
      end
    end
  end

  def item(variable)
    Gitlab::Ci::Variables::Collection::Item.fabricate(variable)
  end
end
