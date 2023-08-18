# frozen_string_literal: true

require 'rubocop_spec_helper'

require_relative '../../../../rubocop/cop/rspec/before_all'

RSpec.describe Rubocop::Cop::RSpec::BeforeAll, feature_category: :tooling do
  context 'when using before(:all)' do
    let(:source) do
      <<~SRC
        before(:all) do
        ^^^^^^^^^^^^ Prefer using `before_all` over `before(:all)`. [...]
          create_table_structure
        end
      SRC
    end

    let(:corrected_source) do
      <<~SRC
        before_all do
          create_table_structure
        end
      SRC
    end

    it 'registers an offense and corrects', :aggregate_failures do
      expect_offense(source)

      expect_correction(corrected_source)
    end
  end

  context 'when using before_all' do
    let(:source) do
      <<~SRC
        before_all do
          create_table_structure
        end
      SRC
    end

    it 'does not register an offense' do
      expect_no_offenses(source)
    end
  end

  context 'when using before(:each)' do
    let(:source) do
      <<~SRC
        before(:each) do
          create_table_structure
        end
      SRC
    end

    it 'does not register an offense' do
      expect_no_offenses(source)
    end
  end

  context 'when using before' do
    let(:source) do
      <<~SRC
        before do
          create_table_structure
        end
      SRC
    end

    it 'does not register an offense' do
      expect_no_offenses(source)
    end
  end
end
