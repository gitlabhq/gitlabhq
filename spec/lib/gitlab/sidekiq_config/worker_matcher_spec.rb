# frozen_string_literal: true

require 'fast_spec_helper'
require 'rspec-parameterized'

RSpec.describe Gitlab::SidekiqConfig::WorkerMatcher do
  describe '#match?' do
    using RSpec::Parameterized::TableSyntax

    let(:worker_metadatas) do
      [
        {
          name: 'a',
          feature_category: :category_a,
          has_external_dependencies: false,
          urgency: :low,
          resource_boundary: :cpu,
          tags: [:no_disk_io, :git_access]
        },
        {
          name: 'a:2',
          feature_category: :category_a,
          has_external_dependencies: false,
          urgency: :high,
          resource_boundary: :none,
          tags: [:git_access]
        },
        {
          name: 'b',
          feature_category: :category_b,
          has_external_dependencies: true,
          urgency: :high,
          resource_boundary: :memory,
          tags: [:no_disk_io]
        },
        {
          name: 'c',
          feature_category: :category_c,
          has_external_dependencies: false,
          urgency: :throttled,
          resource_boundary: :memory,
          tags: []
        }
      ]
    end

    context 'with valid input' do
      where(:query, :expected_metadatas) do
        # feature_category
        'feature_category=category_a' | %w(a a:2)
        'feature_category=category_a,category_c' | %w(a a:2 c)
        'feature_category=category_a|feature_category=category_c' | %w(a a:2 c)
        'feature_category!=category_a' | %w(b c)

        # has_external_dependencies
        'has_external_dependencies=true' | %w(b)
        'has_external_dependencies=false' | %w(a a:2 c)
        'has_external_dependencies=true,false' | %w(a a:2 b c)
        'has_external_dependencies=true|has_external_dependencies=false' | %w(a a:2 b c)
        'has_external_dependencies!=true' | %w(a a:2 c)

        # urgency
        'urgency=high' | %w(a:2 b)
        'urgency=low' | %w(a)
        'urgency=high,low,throttled' | %w(a a:2 b c)
        'urgency=low|urgency=throttled' | %w(a c)
        'urgency!=high' | %w(a c)

        # name
        'name=a' | %w(a)
        'name=a,b' | %w(a b)
        'name=a,a:2|name=b' | %w(a a:2 b)
        'name!=a,a:2' | %w(b c)

        # resource_boundary
        'resource_boundary=memory' | %w(b c)
        'resource_boundary=memory,cpu' | %w(a b c)
        'resource_boundary=memory|resource_boundary=cpu' | %w(a b c)
        'resource_boundary!=memory,cpu' | %w(a:2)

        # tags
        'tags=no_disk_io' | %w(a b)
        'tags=no_disk_io,git_access' | %w(a a:2 b)
        'tags=no_disk_io|tags=git_access' | %w(a a:2 b)
        'tags=no_disk_io&tags=git_access' | %w(a)
        'tags!=no_disk_io' | %w(a:2 c)
        'tags!=no_disk_io,git_access' | %w(c)
        'tags=unknown_tag' | []
        'tags!=no_disk_io' | %w(a:2 c)
        'tags!=no_disk_io,git_access' | %w(c)
        'tags!=unknown_tag' | %w(a a:2 b c)

        # combinations
        'feature_category=category_a&urgency=high' | %w(a:2)
        'feature_category=category_a&urgency=high|feature_category=category_c' | %w(a:2 c)

        # Match all
        '*' | %w(a a:2 b c)
      end

      with_them do
        it do
          matched_metadatas = worker_metadatas.select do |metadata|
            described_class.new(query).match?(metadata)
          end
          expect(matched_metadatas.map { |m| m[:name] }).to match_array(expected_metadatas)
        end
      end
    end

    context 'with invalid input' do
      where(:query, :error) do
        'feature_category="category_a"' | described_class::InvalidTerm
        'feature_category=' | described_class::InvalidTerm
        'feature_category~category_a' | described_class::InvalidTerm
        'worker_name=a' | described_class::UnknownPredicate
      end

      with_them do
        it do
          worker_metadatas.each do |metadata|
            expect { described_class.new(query).match?(metadata) }
              .to raise_error(error)
          end
        end
      end
    end
  end
end
