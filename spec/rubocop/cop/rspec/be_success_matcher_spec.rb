# frozen_string_literal: true

require 'spec_helper'

require 'rubocop'
require 'rubocop/rspec/support'

require_relative '../../../../rubocop/cop/rspec/be_success_matcher'

describe RuboCop::Cop::RSpec::BeSuccessMatcher do
  include CopHelper

  CODE_EXAMPLES = [
    {
      bad: %(expect(response).to be_success).freeze,
      good: %(expect(response).to be_successful).freeze
    },
    {
      bad: %(is_expected.to be_success).freeze,
      good: %(is_expected.to be_successful).freeze
    }
  ]

  let(:source_file) { 'spec/foo_spec.rb' }

  subject(:cop) { described_class.new }

  shared_examples 'an offensive be_success call' do |content|
    it "registers an offense for `#{content}`" do
      inspect_source(content, source_file)

      expect(cop.offenses.size).to eq(1)
      expect(cop.offenses.map(&:line)).to eq([1])
      expect(cop.highlights).to eq([content])
    end
  end

  shared_examples 'an autocorrected be_success call' do |content, autocorrected_content|
    it "registers an offense for `#{content}` and autocorrects it to `#{autocorrected_content}`" do
      autocorrected = autocorrect_source(content, source_file)

      expect(autocorrected).to eql(autocorrected_content)
    end
  end

  context 'in a controller spec file' do
    before do
      allow(cop).to receive(:in_controller_spec?).and_return(true)
    end

    CODE_EXAMPLES.each do |code_example|
      context "using #{code_example[:bad]} call" do
        it_behaves_like 'an offensive be_success call', code_example[:bad]
        it_behaves_like 'an autocorrected be_success call', code_example[:bad], code_example[:good]
      end

      context "using #{code_example[:good]} call" do
        it "does not register an offense" do
          inspect_source(code_example[:good])

          expect(cop.offenses.size).to eq(0)
        end
      end
    end
  end

  context 'outside of a controller spec file' do
    CODE_EXAMPLES.each do |code_example|
      context "using #{code_example[:bad]} call" do
        it 'does not register an offense' do
          inspect_source(code_example[:bad])

          expect(cop.offenses.size).to eq(0)
        end
      end
    end
  end
end
