require 'spec_helper'

require 'rubocop'
require 'rubocop/rspec/support'

require_relative '../../../../rubocop/cop/rspec/be_success_matcher'

describe RuboCop::Cop::RSpec::BeSuccessMatcher do
  include CopHelper

  OFFENSE_CALL_EXPECT_TO_BE_SUCCESS = %(expect(response).to be_success).freeze
  OFFENSE_CALL_IS_EXPECTED_TO_BE_SUCCESS = %(is_expected.to be_success).freeze
  CALL_EXPECT_TO_BE_SUCCESSFUL = %(expect(response).to be_successful).freeze
  CALL_IS_EXPECTED_TO_BE_SUCCESSFUL = %(is_expected.to be_successful).freeze

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

    context "using expect(response).to be_success call" do
      it_behaves_like 'an offensive be_success call', OFFENSE_CALL_EXPECT_TO_BE_SUCCESS
      it_behaves_like 'an autocorrected be_success call', OFFENSE_CALL_EXPECT_TO_BE_SUCCESS, CALL_EXPECT_TO_BE_SUCCESSFUL
    end

    context "using is_expected.to be_success call" do
      it_behaves_like 'an offensive be_success call', OFFENSE_CALL_IS_EXPECTED_TO_BE_SUCCESS
      it_behaves_like 'an autocorrected be_success call', OFFENSE_CALL_IS_EXPECTED_TO_BE_SUCCESS, CALL_IS_EXPECTED_TO_BE_SUCCESSFUL
    end

    context "using expect(response).to be_successful" do
      it "does not register an offense" do
        inspect_source(CALL_EXPECT_TO_BE_SUCCESSFUL)

        expect(cop.offenses.size).to eq(0)
      end
    end

    context "using is_expected.to be_successful" do
      it "does not register an offense" do
        inspect_source(CALL_IS_EXPECTED_TO_BE_SUCCESSFUL)

        expect(cop.offenses.size).to eq(0)
      end
    end
  end

  context 'outside of a controller spec file' do
    context "using expect(response).to be_success call" do
      it "does not register an offense" do
        inspect_source(OFFENSE_CALL_EXPECT_TO_BE_SUCCESS)

        expect(cop.offenses.size).to eq(0)
      end
    end

    context "using is_expected.to be_success call" do
      it "does not register an offense" do
        inspect_source(OFFENSE_CALL_IS_EXPECTED_TO_BE_SUCCESS)

        expect(cop.offenses.size).to eq(0)
      end
    end
  end
end
