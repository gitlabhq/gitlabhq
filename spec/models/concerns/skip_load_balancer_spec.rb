# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SkipLoadBalancer, feature_category: :database do
  describe '.extended' do
    context 'when the class does not already have uses_load_balancer defined' do
      let(:klass) { Class.new(ActiveRecord::Base) }

      it 'defines uses_load_balancer and sets it to false' do
        klass.extend(described_class)

        expect(klass.uses_load_balancer).to be_falsey
      end
    end

    context 'when the class already has uses_load_balancer defined' do
      let(:klass) do
        Class.new(ActiveRecord::Base) do
          class_attribute :uses_load_balancer

          self.uses_load_balancer = true
        end
      end

      it 'does not redefine the class_attribute but sets it to false' do
        expect(klass).not_to receive(:class_attribute)

        klass.extend(described_class)

        expect(klass.uses_load_balancer).to be_falsey
      end
    end
  end
end
