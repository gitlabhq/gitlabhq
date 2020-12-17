# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Build::Rules::Rule::Clause do
  describe '.fabricate' do
    using RSpec::Parameterized::TableSyntax

    let(:value) { 'some value' }

    subject { described_class.fabricate(type, value) }

    context 'when type is valid' do
      where(:type, :result) do
        'changes' | Gitlab::Ci::Build::Rules::Rule::Clause::Changes
        'exists'  | Gitlab::Ci::Build::Rules::Rule::Clause::Exists
        'if'      | Gitlab::Ci::Build::Rules::Rule::Clause::If
      end

      with_them do
        it { is_expected.to be_instance_of(result) }
      end
    end

    context 'when type is invalid' do
      let(:type) { 'when' }

      it { is_expected.to be_nil }

      context "when type is 'variables'" do
        let(:type) { 'variables' }

        it { is_expected.to be_nil }
      end
    end
  end
end
