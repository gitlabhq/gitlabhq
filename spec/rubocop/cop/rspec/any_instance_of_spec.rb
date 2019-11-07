# frozen_string_literal: true

require 'spec_helper'

require_relative '../../../../rubocop/cop/rspec/any_instance_of'

describe RuboCop::Cop::RSpec::AnyInstanceOf do
  include CopHelper

  subject(:cop) { described_class.new }

  context 'when calling allow_any_instance_of' do
    let(:source) do
      <<~SRC
      allow_any_instance_of(User).to receive(:invalidate_issue_cache_counts)
      SRC
    end
    let(:corrected_source) do
      <<~SRC
      allow_next_instance_of(User) do |instance|
        allow(instance).to receive(:invalidate_issue_cache_counts)
      end
      SRC
    end

    it 'registers an offence' do
      inspect_source(source)

      expect(cop.offenses.size).to eq(1)
    end

    it 'can autocorrect the source' do
      expect(autocorrect_source(source)).to eq(corrected_source)
    end
  end

  context 'when calling expect_any_instance_of' do
    let(:source) do
      <<~SRC
      expect_any_instance_of(User).to receive(:invalidate_issue_cache_counts).with(args).and_return(double)
      SRC
    end
    let(:corrected_source) do
      <<~SRC
      expect_next_instance_of(User) do |instance|
        expect(instance).to receive(:invalidate_issue_cache_counts).with(args).and_return(double)
      end
      SRC
    end

    it 'registers an offence' do
      inspect_source(source)

      expect(cop.offenses.size).to eq(1)
    end

    it 'can autocorrect the source' do
      expect(autocorrect_source(source)).to eq(corrected_source)
    end
  end
end
