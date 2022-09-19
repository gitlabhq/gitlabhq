# frozen_string_literal: true

require 'spec_helper'

RSpec.describe FromSetOperator do
  let_it_be(:from_set_operator) do
    Class.new do
      extend FromSetOperator
      define_set_operator Gitlab::SQL::Union

      def table_name
        'groups'
      end

      def from(*args)
        ''
      end
    end
  end

  context 'when set operator method already exists' do
    let(:redefine_method) do
      Class.new do
        def self.from_union
          # This method intentionally left blank.
        end

        extend FromSetOperator
        define_set_operator Gitlab::SQL::Union
      end
    end

    it { expect { redefine_method }.to raise_exception(RuntimeError) }
  end

  context 'with members' do
    let_it_be(:group1) { create :group }
    let_it_be(:group2) { create :group }
    let_it_be(:groups) do
      [
        Group.where(id: group1),
        Group.where(id: group2)
      ]
    end

    shared_examples 'set operator called with correct members' do
      it do
        expect(Gitlab::SQL::Union).to receive(:new).with(groups, anything).and_call_original
        subject
      end
    end

    context 'as array' do
      subject { from_set_operator.new.from_union(groups) }

      it_behaves_like 'set operator called with correct members'

      it { expect { subject }.not_to make_queries }
    end

    context 'as multiple parameters' do
      subject { from_set_operator.new.from_union(*groups) }

      it_behaves_like 'set operator called with correct members'

      it { expect { subject }.not_to make_queries }
    end
  end
end
