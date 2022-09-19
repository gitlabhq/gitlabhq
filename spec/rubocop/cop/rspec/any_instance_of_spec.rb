# frozen_string_literal: true

require 'rubocop_spec_helper'

require_relative '../../../../rubocop/cop/rspec/any_instance_of'

RSpec.describe RuboCop::Cop::RSpec::AnyInstanceOf do
  context 'when calling allow_any_instance_of' do
    let(:source) do
      <<~SRC
        allow_any_instance_of(User).to receive(:invalidate_issue_cache_counts)
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Do not use `allow_any_instance_of` [...]
      SRC
    end

    let(:corrected_source) do
      <<~SRC
        allow_next_instance_of(User) do |instance|
          allow(instance).to receive(:invalidate_issue_cache_counts)
        end
      SRC
    end

    it 'registers an offense and corrects', :aggregate_failures do
      expect_offense(source)

      expect_correction(corrected_source)
    end
  end

  context 'when calling expect_any_instance_of' do
    let(:source) do
      <<~SRC
        expect_any_instance_of(User).to receive(:invalidate_issue_cache_counts).with(args).and_return(double)
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Do not use `expect_any_instance_of` [...]
      SRC
    end

    let(:corrected_source) do
      <<~SRC
        expect_next_instance_of(User) do |instance|
          expect(instance).to receive(:invalidate_issue_cache_counts).with(args).and_return(double)
        end
      SRC
    end

    it 'registers an offense and corrects', :aggregate_failures do
      expect_offense(source)

      expect_correction(corrected_source)
    end
  end
end
