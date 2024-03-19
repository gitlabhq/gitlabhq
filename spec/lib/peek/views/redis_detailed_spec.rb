# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Peek::Views::RedisDetailed, :request_store do
  subject { described_class.new }

  using RSpec::Parameterized::TableSyntax

  where(:commands, :expected_commands, :expected_cmd) do
    [[:auth, 'test']] | [[:auth, '<redacted>']] | 'auth <redacted>'
    [[:set, 'key', 'value']] | [[:set, 'key', '<redacted>']] | 'set key <redacted>'
    [[:set, 'bad']] | [[:set, 'bad']] | 'set bad'
    [[:hmset, 'key1', 'value1', 'key2', 'value2']] | [[:hmset, 'key1', '<redacted>']] | 'hmset key1 <redacted>'
    [[:get, 'key']] | [[:get, 'key']] | 'get key'
    [[:get, 'key1'], [:get, 'key2']] | [[:get, 'key1'], [:get, 'key2']] | 'get key1, get key2'
    [[:set, 'key1', 'value'],
      [:set, 'key2',
        'value']] | [[:set, 'key1', '<redacted>'],
          [:set, 'key2', '<redacted>']] | 'set key1 <redacted>, set key2 <redacted>'
  end

  with_them do
    before do
      Gitlab::Instrumentation::Redis::SharedState.detail_store << { commands: commands, duration: 1.second }
    end

    it 'scrubs Redis commands' do
      expect(subject.results[:details].count).to eq(1)
      expect(subject.results[:details].first)
        .to include({
          commands: expected_commands,
          cmd: expected_cmd,
          duration: 1000
                    })
    end

    it 'does not mutate input variable for redacted commands' do
      input = commands.deep_dup

      subject.results

      expect(commands).to eq(input)
    end
  end

  it 'does not mutate input variable for auth commands' do
    commands = [[:auth, 'test']]
    Gitlab::Instrumentation::Redis::SharedState.detail_store << { commands: commands, duration: 1.second }

    expect(subject.results[:details].first)
        .to include({ commands: [[:auth, "<redacted>"]], cmd: 'auth <redacted>', duration: 1000 })

    expect(commands).to eq([[:auth, 'test']])
  end

  it 'returns aggregated results' do
    Gitlab::Instrumentation::Redis::Cache.detail_store << { commands: [[:get, 'test']], duration: 0.001 }
    Gitlab::Instrumentation::Redis::Cache.detail_store << { commands: [[:get, 'test']], duration: 1.second }
    Gitlab::Instrumentation::Redis::SharedState.detail_store << { commands: [[:get, 'test']], duration: 1.second }

    expect(subject.results[:calls]).to eq(3)
    expect(subject.results[:duration]).to eq('2001.00ms')
    expect(subject.results[:details].count).to eq(3)
  end
end
