# frozen_string_literal: true

require 'spec_helper'

require 'rubocop'
require 'rubocop/rspec/support'

require_relative '../../../../rubocop/cop/rspec/be_success_matcher'

describe RuboCop::Cop::RSpec::BeSuccessMatcher do
  include CopHelper

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

  shared_examples 'cop' do |good:, bad:|
    context "using #{bad} call" do
      it_behaves_like 'an offensive be_success call', bad
      it_behaves_like 'an autocorrected be_success call', bad, good
    end

    context "using #{good} call" do
      it 'does not register an offense' do
        inspect_source(good)

        expect(cop.offenses.size).to eq(0)
      end
    end
  end

  describe 'using different code examples' do
    it_behaves_like 'cop',
      bad: 'expect(response).to be_success',
      good: 'expect(response).to be_successful'

    it_behaves_like 'cop',
      bad: 'expect(response).to_not be_success',
      good: 'expect(response).to_not be_successful'

    it_behaves_like 'cop',
      bad: 'expect(response).not_to be_success',
      good: 'expect(response).not_to be_successful'

    it_behaves_like 'cop',
      bad: 'is_expected.to be_success',
      good: 'is_expected.to be_successful'

    it_behaves_like 'cop',
      bad: 'is_expected.to_not be_success',
      good: 'is_expected.to_not be_successful'

    it_behaves_like 'cop',
      bad: 'is_expected.not_to be_success',
      good: 'is_expected.not_to be_successful'
  end
end
