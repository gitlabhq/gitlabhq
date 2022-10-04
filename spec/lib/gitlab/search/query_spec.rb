# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Search::Query do
  let(:query) { 'base filter:wow anotherfilter:noway name:maybe other:mmm leftover' }
  let(:subject) do
    described_class.new(query) do
      filter :filter
      filter :name, parser: :upcase.to_proc
      filter :other
    end
  end

  it { expect(described_class).to be < SimpleDelegator }

  it 'leaves undefined filters in the main query' do
    expect(subject.term).to eq('base anotherfilter:noway leftover')
  end

  it 'parses filters' do
    expect(subject.filters.count).to eq(3)
    expect(subject.filters.map { |f| f[:value] }).to match_array(%w[wow MAYBE mmm])
  end

  context 'with an empty filter' do
    let(:query) { 'some bar name: baz' }

    it 'ignores empty filters' do
      expect(subject.term).to eq('some bar name: baz')
    end
  end

  context 'with a pipe' do
    let(:query) { 'base | nofilter' }

    it 'does not escape the pipe' do
      expect(subject.term).to eq(query)
    end
  end

  context 'with an exclusive filter' do
    let(:query) { 'something -name:bingo -other:dingo' }

    it 'negates the filter' do
      expect(subject.filters).to all(include(negated: true))
    end
  end

  context 'with filter value in quotes' do
    let(:query) { '"foo bar" name:"my test script.txt"' }

    it 'does not break the filter value in quotes' do
      expect(subject.term).to eq('"foo bar"')
      expect(subject.filters[0]).to include(name: :name, negated: false, value: "MY TEST SCRIPT.TXT")
    end
  end

  context 'with extra white spaces between the query words' do
    let(:query) { ' foo = bar  name:"my test.txt"' }

    it 'removes the extra whitespace between tokens' do
      expect(subject.term).to eq('foo = bar')
      expect(subject.filters[0]).to include(name: :name, negated: false, value: "MY TEST.TXT")
    end
  end

  context 'with mutliple filename filters' do
    let(:query) { 'something filename:myfile.txt -filename:ANOTHERFILE.yml filename:somethingelse.txt' }
    let(:subject) do
      described_class.new(query) do
        filter :filename
      end
    end

    it 'creates a filter for each filename in query' do
      expect(subject.filters.count).to eq(3)
      expect(subject.filters[0]).to include(name: :filename, negated: false, value: 'myfile.txt')
      expect(subject.filters[1]).to include(name: :filename, negated: true, value: 'anotherfile.yml')
      expect(subject.filters[2]).to include(name: :filename, negated: false, value: 'somethingelse.txt')
    end

    context 'when multiple extension filters are added' do
      let(:query) { 'something filename:myfile.txt -extension:yml -filename:ANOTHERFILE.yml extension:txt' }
      let(:subject) do
        described_class.new(query) do
          filter :filename
          filter :extension
        end
      end

      it 'creates a filter for each filename and extension in query' do
        expect(subject.filters.count).to eq(4)
        expect(subject.filters[0]).to include(name: :filename, negated: false, value: 'myfile.txt')
        expect(subject.filters[1]).to include(name: :filename, negated: true, value: 'anotherfile.yml')
        expect(subject.filters[2]).to include(name: :extension, negated: true, value: 'yml')
        expect(subject.filters[3]).to include(name: :extension, negated: false, value: 'txt')
      end
    end
  end
end
