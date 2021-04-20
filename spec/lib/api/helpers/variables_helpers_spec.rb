# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Helpers::VariablesHelpers do
  let(:helper) { Class.new.include(described_class).new }

  describe '#filter_variable_parameters' do
    let(:project) { double }
    let(:params) { double }

    subject { helper.filter_variable_parameters(project, params) }

    it 'returns unmodified params (overridden in EE)' do
      expect(subject).to eq(params)
    end
  end

  describe '#find_variable' do
    let(:owner) { double }
    let(:params) { double }
    let(:variables) { [double] }

    subject { helper.find_variable(owner, params) }

    before do
      expect(Ci::VariablesFinder).to receive(:new).with(owner, params)
        .and_return(double(execute: variables))
    end

    it { is_expected.to eq(variables.first) }

    context 'there are multiple variables with the supplied key' do
      let(:variables) { [double, double] }

      it 'raises a conflict!' do
        expect(helper).to receive(:conflict!).with(/There are multiple variables with provided parameters/)

        subject
      end
    end
  end
end
