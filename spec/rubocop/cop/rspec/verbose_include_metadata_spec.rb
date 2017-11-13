require 'spec_helper'
require 'rubocop'
require 'rubocop/rspec/support'
require_relative '../../../../rubocop/cop/rspec/verbose_include_metadata'

describe RuboCop::Cop::RSpec::VerboseIncludeMetadata do
  include CopHelper

  subject(:cop) { described_class.new }

  let(:source_file) { 'foo_spec.rb' }

  # Override `CopHelper#inspect_source` to always appear to be in a spec file,
  # so that our RSpec-only cop actually runs
  def inspect_source(*args)
    super(*args, source_file)
  end

  shared_examples 'examples with include syntax' do |title|
    it "flags violation for #{title} examples that uses verbose include syntax" do
      inspect_source(cop, "#{title} 'Test', js: true do; end")

      expect(cop.offenses.size).to eq(1)
      offense = cop.offenses.first

      expect(offense.line).to eq(1)
      expect(cop.highlights).to eq(["#{title} 'Test', js: true"])
      expect(offense.message).to eq('Use `:js` instead of `js: true`.')
    end

    it "doesn't flag violation for #{title} examples that uses compact include syntax", :aggregate_failures do
      inspect_source(cop, "#{title} 'Test', :js do; end")

      expect(cop.offenses).to be_empty
    end

    it "doesn't flag violation for #{title} examples that uses flag: symbol" do
      inspect_source(cop, "#{title} 'Test', flag: :symbol do; end")

      expect(cop.offenses).to be_empty
    end

    it "autocorrects #{title} examples that uses verbose syntax into compact syntax" do
      autocorrected = autocorrect_source(cop, "#{title} 'Test', js: true do; end", source_file)

      expect(autocorrected).to eql("#{title} 'Test', :js do; end")
    end
  end

  %w(describe context feature example_group it specify example scenario its).each do |example|
    it_behaves_like 'examples with include syntax', example
  end
end
