# frozen_string_literal: true

require 'fast_spec_helper'
require 'webmock/rspec'
require 'tempfile'
require 'tmpdir'
require 'open3'
require_relative '../../../scripts/lint/validate_release_categories'
require_relative '../../support/silence_stdout'

RSpec.describe Lint::ValidateReleaseCategories, :silence_output, feature_category: :tooling do
  let(:valid_categories) { ['Category One', 'Category Two', 'Category Three'] }
  let(:categories_url) { 'https://example.com/categories.yml' }

  let(:linter) { described_class.new }

  describe '#fetch_valid_category_names' do
    it 'fetches and parses category names from the given URL' do
      stub_request(:get, categories_url)
        .to_return(status: 200, body: valid_categories.map { |name| "  name: '#{name}'\n" }.join)

      expect(linter.send(:fetch_valid_category_names, categories_url)).to eq(Set.new(valid_categories))
    end

    it 'raises an error for non-HTTPS URLs' do
      expect { linter.send(:fetch_valid_category_names, 'http://example.com/categories.yml') }
        .to raise_error(ArgumentError)
    end

    it 'raises an error for responses exceeding the size limit' do
      stub_request(:get, categories_url)
        .to_return(status: 200, body: 'a' * (described_class::MAX_RESPONSE_BYTES + 1))

      expect { linter.send(:fetch_valid_category_names, categories_url) }.to raise_error(ArgumentError)
    end
  end

  describe '#parse_frontmatter' do
    it 'parses YAML frontmatter and returns a hash' do
      content = <<~MD
        ---
        title: Release Notes
        categories: [ Category One, Category Two ]
        ---
        # Release Notes Content
      MD

      expect(linter.send(:parse_frontmatter, content)).to eq({
        'title' => 'Release Notes',
        'categories' => ['Category One', 'Category Two']
      })
    end

    it 'returns an empty hash when there is no frontmatter' do
      content = "# No Frontmatter Here"
      expect(linter.send(:parse_frontmatter, content)).to eq({})
    end

    it 'returns an empty hash when frontmatter cannot be parsed' do
      content = <<~MD
        ---
        title: Unclosed Frontmatter
        categories: [ Category One, Category Two ]
        # Missing closing "---"
      MD

      expect(linter.send(:parse_frontmatter, content)).to eq({})
    end
  end

  describe '#check_category_names' do
    let(:lower_map) { valid_categories.to_h { |name| [name.downcase, name] } } # rubocop:disable Rails/IndexBy -- This script does not depend on ActiveSupport.
    let(:context) { 'In frontmatter' }
    let(:errors) { [] }

    it 'records no error for a valid category name' do
      linter.send(:check_category_names, ['Category One'], context, valid_categories, lower_map, errors)

      expect(errors).to be_empty
    end

    it 'records a CASE MISMATCH error pointing to the correct casing' do
      linter.send(:check_category_names, ['category one'], context, valid_categories, lower_map, errors)

      expect(errors).to contain_exactly(
        "CASE MISMATCH | In frontmatter | 'category one' should be 'Category One'"
      )
    end

    it 'records an UNKNOWN error for a name not in categories.yml' do
      linter.send(:check_category_names, ['Nonexistent'], context, valid_categories, lower_map, errors)

      expect(errors).to contain_exactly(
        "UNKNOWN | In frontmatter | 'Nonexistent' not found in categories.yml"
      )
    end

    it 'checks every category and accumulates multiple errors' do
      linter.send(:check_category_names, ['Category One', 'category two', 'Nonexistent'], context,
        valid_categories, lower_map, errors)

      expect(errors).to contain_exactly(
        "CASE MISMATCH | In frontmatter | 'category two' should be 'Category Two'",
        "UNKNOWN | In frontmatter | 'Nonexistent' not found in categories.yml"
      )
    end

    it 'appends to any errors already present rather than replacing them', :aggregate_failures do
      errors << "CASE MISMATCH | In frontmatter | 'category two' should be 'Category Two'"

      linter.send(:check_category_names, ['Nonexistent'], context, valid_categories, lower_map, errors)

      expect(errors.size).to eq(2)
      expect(errors.first).to eq("CASE MISMATCH | In frontmatter | 'category two' should be 'Category Two'")
    end

    it 'records nothing when given no categories' do
      linter.send(:check_category_names, [], context, valid_categories, lower_map, errors)

      expect(errors).to be_empty
    end
  end

  describe '#parse_release_notes' do
    let(:content) do
      <<~MD
        ## Top level section

        ### Feature with a category

        <!-- categories: Category One -->

        Some description text.

        ### Feature without a category

        Just a description, no tag here.

        ### Feature with a details block

        <!-- categories: Category Two -->

        {{< details >}}
        <!-- categories: Should Be Ignored -->
        {{< /details >}}
      MD
    end

    subject(:results) { linter.send(:parse_release_notes, content) }

    it 'returns a [heading, categories] pair for every H3 heading' do
      expect(results.map(&:first)).to eq(
        ['Feature with a category', 'Feature without a category', 'Feature with a details block']
      )
    end

    # `eq` checks the whole array, in order.
    it 'returns the exact set of pairs' do
      expect(results).to eq([
        ['Feature with a category', ['Category One']],
        ['Feature without a category', nil],
        ['Feature with a details block', ['Category Two']]
      ])
    end
  end
end
