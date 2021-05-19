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
          worker_name: 'WorkerA',
          feature_category: :category_a,
          has_external_dependencies: false,
          urgency: :low,
          resource_boundary: :cpu,
          tags: [:no_disk_io, :git_access]
        },
        {
          name: 'a:2',
          worker_name: 'WorkerA2',
          feature_category: :category_a,
          has_external_dependencies: false,
          urgency: :high,
          resource_boundary: :none,
          tags: [:git_access]
        },
        {
          name: 'b',
          worker_name: 'WorkerB',
          feature_category: :category_b,
          has_external_dependencies: true,
          urgency: :high,
          resource_boundary: :memory,
          tags: [:no_disk_io]
        },
        {
          name: 'c',
          worker_name: 'WorkerC',
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
        # worker_name
        'worker_name=WorkerA' | %w(WorkerA)
        'worker_name=WorkerA2' | %w(WorkerA2)
        'worker_name=WorkerB|worker_name=WorkerD' | %w(WorkerB)
        'worker_name!=WorkerA' | %w(WorkerA2 WorkerB WorkerC)

        # feature_category
        'feature_category=category_a' | %w(WorkerA WorkerA2)
        'feature_category=category_a,category_c' | %w(WorkerA WorkerA2 WorkerC)
        'feature_category=category_a|feature_category=category_c' | %w(WorkerA WorkerA2 WorkerC)
        'feature_category!=category_a' | %w(WorkerB WorkerC)

        # has_external_dependencies
        'has_external_dependencies=true' | %w(WorkerB)
        'has_external_dependencies=false' | %w(WorkerA WorkerA2 WorkerC)
        'has_external_dependencies=true,false' | %w(WorkerA WorkerA2 WorkerB WorkerC)
        'has_external_dependencies=true|has_external_dependencies=false' | %w(WorkerA WorkerA2 WorkerB WorkerC)
        'has_external_dependencies!=true' | %w(WorkerA WorkerA2 WorkerC)

        # urgency
        'urgency=high' | %w(WorkerA2 WorkerB)
        'urgency=low' | %w(WorkerA)
        'urgency=high,low,throttled' | %w(WorkerA WorkerA2 WorkerB WorkerC)
        'urgency=low|urgency=throttled' | %w(WorkerA WorkerC)
        'urgency!=high' | %w(WorkerA WorkerC)

        # name
        'name=a' | %w(WorkerA)
        'name=a,b' | %w(WorkerA WorkerB)
        'name=a,a:2|name=b' | %w(WorkerA WorkerA2 WorkerB)
        'name!=a,a:2' | %w(WorkerB WorkerC)

        # resource_boundary
        'resource_boundary=memory' | %w(WorkerB WorkerC)
        'resource_boundary=memory,cpu' | %w(WorkerA WorkerB WorkerC)
        'resource_boundary=memory|resource_boundary=cpu' | %w(WorkerA WorkerB WorkerC)
        'resource_boundary!=memory,cpu' | %w(WorkerA2)

        # tags
        'tags=no_disk_io' | %w(WorkerA WorkerB)
        'tags=no_disk_io,git_access' | %w(WorkerA WorkerA2 WorkerB)
        'tags=no_disk_io|tags=git_access' | %w(WorkerA WorkerA2 WorkerB)
        'tags=no_disk_io&tags=git_access' | %w(WorkerA)
        'tags!=no_disk_io' | %w(WorkerA2 WorkerC)
        'tags!=no_disk_io,git_access' | %w(WorkerC)
        'tags=unknown_tag' | []
        'tags!=no_disk_io' | %w(WorkerA2 WorkerC)
        'tags!=no_disk_io,git_access' | %w(WorkerC)
        'tags!=unknown_tag' | %w(WorkerA WorkerA2 WorkerB WorkerC)

        # combinations
        'feature_category=category_a&urgency=high' | %w(WorkerA2)
        'feature_category=category_a&urgency=high|feature_category=category_c' | %w(WorkerA2 WorkerC)

        # Match all
        '*' | %w(WorkerA WorkerA2 WorkerB WorkerC)
      end

      with_them do
        it do
          matched_metadatas = worker_metadatas.select do |metadata|
            described_class.new(query).match?(metadata)
          end
          expect(matched_metadatas.map { |m| m[:worker_name] }).to match_array(expected_metadatas)
        end
      end
    end

    context 'with invalid input' do
      where(:query, :error) do
        'feature_category="category_a"' | described_class::InvalidTerm
        'feature_category=' | described_class::InvalidTerm
        'feature_category~category_a' | described_class::InvalidTerm
        'invalid_term=a' | described_class::UnknownPredicate
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
