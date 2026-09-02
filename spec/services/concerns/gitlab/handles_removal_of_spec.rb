# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::HandlesRemovalOf, feature_category: :database do
  let(:service_class) do
    Class.new do
      include Gitlab::HandlesRemovalOf

      handles_removal_of :widgets, 'gadgets'
    end
  end

  describe '.handled_tables' do
    it 'exposes declared tables as strings' do
      expect(service_class.handled_tables).to contain_exactly('widgets', 'gadgets')
    end

    it 'accumulates tables across multiple declarations' do
      service_class.handles_removal_of(:sprockets)

      expect(service_class.handled_tables).to contain_exactly('widgets', 'gadgets', 'sprockets')
    end

    context 'with a subclass' do
      let(:subclass) do
        Class.new(service_class) do
          handles_removal_of :sprockets
        end
      end

      it 'includes tables declared by ancestors' do
        expect(subclass.handled_tables).to contain_exactly('widgets', 'gadgets', 'sprockets')
      end

      it 'exposes only its own declarations through own_handled_tables' do
        expect(subclass.own_handled_tables).to contain_exactly('sprockets')
      end

      it 'does not leak subclass declarations into the parent' do
        expect(subclass.handled_tables).to include('sprockets')
        expect(service_class.handled_tables).to contain_exactly('widgets', 'gadgets')
      end
    end
  end
end
