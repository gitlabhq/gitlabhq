# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Loggable, feature_category: :observability do
  subject(:klass_instance) do
    Class.new do
      include Gitlab::Loggable

      def self.name
        'MyTestClass'
      end
    end.new
  end

  describe '#build_structured_payload' do
    it 'adds class and returns formatted json' do
      expected = {
        'class' => 'MyTestClass',
        'message' => 'test'
      }

      expect(klass_instance.build_structured_payload(message: 'test')).to eq(expected)
    end

    it 'appends additional params and returns formatted json' do
      expected = {
        'class' => 'MyTestClass',
        'message' => 'test',
        'extra_param' => 1
      }

      expect(klass_instance.build_structured_payload(message: 'test', extra_param: 1)).to eq(expected)
    end

    it 'does not raise an error in loggers when passed non-symbols' do
      expected = {
        'class' => 'MyTestClass',
        'message' => 'test',
        '["hello", "thing"]' => :world
      }

      payload = klass_instance.build_structured_payload(message: 'test', %w[hello thing] => :world)
      expect(payload).to eq(expected)
      expect { Gitlab::Export::Logger.info(payload) }.not_to raise_error
    end

    it 'handles anonymous classes' do
      anonymous_klass_instance = Class.new { include Gitlab::Loggable }.new

      expected = {
        'class' => '<Anonymous>',
        'message' => 'test'
      }

      expect(anonymous_klass_instance.build_structured_payload(message: 'test')).to eq(expected)
    end

    it 'handles duplicate keys' do
      expected = {
        'class' => 'MyTestClass',
        'message' => 'test2'
      }

      expect(klass_instance.build_structured_payload(message: 'test', 'message' => 'test2')).to eq(expected)
    end
  end
end
