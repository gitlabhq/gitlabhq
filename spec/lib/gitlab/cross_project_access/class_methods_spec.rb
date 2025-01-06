# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Gitlab::CrossProjectAccess::ClassMethods do
  let(:dummy_class) do
    Class.new do
      extend Gitlab::CrossProjectAccess::ClassMethods
    end
  end

  let(:dummy_proc) { -> { false } }

  describe '#requires_cross_project_access' do
    it 'creates a correct check when a hash is passed' do
      expect(Gitlab::CrossProjectAccess)
        .to receive(:add_check).with(
          dummy_class,
          actions: { hello: true, world: false },
          positive_condition: dummy_proc,
          negative_condition: dummy_proc
        )

      dummy_class.requires_cross_project_access(
        hello: true, world: false, if: dummy_proc, unless: dummy_proc
      )
    end

    it 'creates a correct check when an array is passed' do
      expect(Gitlab::CrossProjectAccess)
        .to receive(:add_check).with(
          dummy_class,
          actions: { hello: true, world: true },
          positive_condition: nil,
          negative_condition: nil
        )

      dummy_class.requires_cross_project_access(:hello, :world)
    end

    it 'creates a correct check when an array and a hash is passed' do
      expect(Gitlab::CrossProjectAccess)
        .to receive(:add_check).with(
          dummy_class,
          actions: { hello: true, world: true },
          positive_condition: dummy_proc,
          negative_condition: dummy_proc
        )

      dummy_class.requires_cross_project_access(
        :hello, :world, if: dummy_proc, unless: dummy_proc
      )
    end
  end
end
