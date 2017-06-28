require 'spec_helper'

require 'rubocop'
require 'rubocop/rspec/support'

require_relative '../../../rubocop/cop/gem_fetcher'

describe RuboCop::Cop::GemFetcher do
  include CopHelper

  subject(:cop) { described_class.new }

  context 'in Gemfile' do
    before do
      allow(cop).to receive(:gemfile?).and_return(true)
    end

    it 'registers an offense when a gem uses `git`' do
      inspect_source(cop, 'gem "foo", git: "https://gitlab.com/foo/bar.git"')

      aggregate_failures do
        expect(cop.offenses.size).to eq(1)
        expect(cop.offenses.map(&:line)).to eq([1])
        expect(cop.highlights).to eq(['git: "https://gitlab.com/foo/bar.git"'])
      end
    end

    it 'registers an offense when a gem uses `github`' do
      inspect_source(cop, 'gem "foo", github: "foo/bar.git"')

      aggregate_failures do
        expect(cop.offenses.size).to eq(1)
        expect(cop.offenses.map(&:line)).to eq([1])
        expect(cop.highlights).to eq(['github: "foo/bar.git"'])
      end
    end
  end

  context 'outside of Gemfile' do
    it 'registers no offense' do
      inspect_source(cop, 'gem "foo", git: "https://gitlab.com/foo/bar.git"')

      expect(cop.offenses.size).to eq(0)
    end
  end
end
