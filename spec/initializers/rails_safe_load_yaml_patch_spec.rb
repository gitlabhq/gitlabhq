# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Rails YAML safe load patch' do
  let(:unsafe_load) { false }

  let(:klass) do
    Class.new(ActiveRecord::Base) do
      self.table_name = 'issues'

      serialize :description
    end
  end

  before do
    allow(ActiveRecord::Base).to receive(:use_yaml_unsafe_load).and_return(unsafe_load)
  end

  context 'with safe load' do
    let(:instance) { klass.new(description: data) }

    context 'with default permitted classes' do
      let(:data) do
        {
          "test" => Time.now,
          ab: 1
        }
      end

      it 'deserializes data' do
        expect(Gitlab::ErrorTracking).not_to receive(:track_and_raise_for_dev_exception)

        instance.save!

        expect(klass.find(instance.id).description).to eq(data)
      end
    end

    context 'with unpermitted classes' do
      let(:data) { DateTime.now }

      it 'logs an exception and loads the data' do
        expect(Gitlab::ErrorTracking).to receive(:track_and_raise_for_dev_exception).twice

        instance.save!

        expect(klass.find(instance.id).description).to eq(data)
      end
    end
  end

  context 'with unsafe load' do
    let(:unsafe_load) { true }
    let(:data) { DateTime.now }
    let(:instance) { klass.new(description: data) }

    it 'loads the data' do
      expect(Gitlab::ErrorTracking).not_to receive(:track_and_raise_for_dev_exception)

      instance.save!

      expect(klass.find(instance.id).description).to eq(data)
    end
  end
end
