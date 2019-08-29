# frozen_string_literal: true

require 'spec_helper'

describe Peek::Views::RedisDetailed, :request_store do
  subject { described_class.new }

  using RSpec::Parameterized::TableSyntax

  where(:cmd, :expected) do
    [:auth, 'test'] | 'auth <redacted>'
    [:set, 'key', 'value'] | 'set key <redacted>'
    [:set, 'bad'] | 'set bad'
    [:hmset, 'key1', 'value1', 'key2', 'value2'] | 'hmset key1 <redacted>'
    [:get, 'key'] | 'get key'
  end

  with_them do
    it 'scrubs Redis commands' do
      subject.detail_store << { cmd: cmd, duration: 1.second }

      expect(subject.results[:details].count).to eq(1)
      expect(subject.results[:details].first)
        .to include({
                      cmd: expected,
                      duration: 1000
                    })
    end
  end

  it 'returns aggregated results' do
    subject.detail_store << { cmd: [:get, 'test'], duration: 0.001 }
    subject.detail_store << { cmd: [:get, 'test'], duration: 1.second }

    expect(subject.results[:calls]).to eq(2)
    expect(subject.results[:duration]).to eq('1001.00ms')
    expect(subject.results[:details].count).to eq(2)
  end
end
