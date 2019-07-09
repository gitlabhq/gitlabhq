# frozen_string_literal: true

require 'spec_helper'

describe Peek::Views::RedisDetailed do
  let(:redis_detailed_class) do
    Class.new do
      include Peek::Views::RedisDetailed
    end
  end

  subject { redis_detailed_class.new }

  using RSpec::Parameterized::TableSyntax

  where(:cmd, :expected) do
    [:auth, 'test'] | 'auth <redacted>'
    [:set, 'key', 'value'] | 'set key <redacted>'
    [:set, 'bad'] | 'set bad'
    [:hmset, 'key1', 'value1', 'key2', 'value2'] | 'hmset key1 <redacted>'
    [:get, 'key'] | 'get key'
  end

  with_them do
    it 'scrubs Redis commands', :request_store do
      subject.detail_store << { cmd: cmd, duration: 1.second }

      expect(subject.details.count).to eq(1)
      expect(subject.details.first)
        .to eq({
                 cmd: expected,
                 duration: 1000
               })
    end
  end
end
