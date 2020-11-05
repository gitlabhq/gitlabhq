# frozen_string_literal: true

require 'fast_spec_helper'
require 'rubocop'
require_relative '../../../../rubocop/cop/rspec/be_success_matcher'

RSpec.describe RuboCop::Cop::RSpec::BeSuccessMatcher, type: :rubocop do
  include CopHelper

  let(:source_file) { 'spec/foo_spec.rb' }

  subject(:cop) { described_class.new }

  shared_examples 'cop' do |good:, bad:|
    context "using #{bad} call" do
      it 'registers an offense' do
        inspect_source(bad, source_file)

        expect(cop.offenses.size).to eq(1)
        expect(cop.offenses.map(&:line)).to eq([1])
        expect(cop.highlights).to eq([bad])
      end

      it "autocorrects it to `#{good}`" do
        autocorrected = autocorrect_source(bad, source_file)

        expect(autocorrected).to eql(good)
      end
    end

    context "using #{good} call" do
      it 'does not register an offense' do
        inspect_source(good)

        expect(cop.offenses).to be_empty
      end
    end
  end

  include_examples 'cop',
    bad: 'expect(response).to be_success',
    good: 'expect(response).to be_successful'

  include_examples 'cop',
    bad: 'expect(response).to_not be_success',
    good: 'expect(response).to_not be_successful'

  include_examples 'cop',
    bad: 'expect(response).not_to be_success',
    good: 'expect(response).not_to be_successful'

  include_examples 'cop',
    bad: 'is_expected.to be_success',
    good: 'is_expected.to be_successful'

  include_examples 'cop',
    bad: 'is_expected.to_not be_success',
    good: 'is_expected.to_not be_successful'

  include_examples 'cop',
    bad: 'is_expected.not_to be_success',
    good: 'is_expected.not_to be_successful'
end
