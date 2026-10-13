# frozen_string_literal: true

require 'fast_spec_helper'
require_relative '../../../../../tooling/lib/tooling/mappings/graphql_query_document_mappings'

RSpec.describe Tooling::Mappings::GraphqlQueryDocumentMappings, feature_category: :tooling do
  attr_accessor :spec_folder

  let(:instance) { described_class.new(changed_files) }
  let(:changed_files) { [] }

  around do |example|
    Dir.mktmpdir('graphql-query-document-mappings') do |folder|
      self.spec_folder = folder

      example.run
    end
  end

  before do
    stub_const("#{described_class}::SPEC_GLOB", File.join(spec_folder, '**', '*_spec.rb'))
  end

  describe '#filter_files' do
    subject(:filtered_files) { instance.filter_files }

    let(:changed_files) do
      %w[
        app/assets/javascripts/work_items/graphql/project_work_items.query.graphql
        app/models/user.rb
      ]
    end

    it 'returns only the changed .graphql files' do
      expect(filtered_files).to contain_exactly(
        'app/assets/javascripts/work_items/graphql/project_work_items.query.graphql'
      )
    end
  end

  describe '#execute' do
    subject(:matching_specs) { instance.execute }

    context 'when no .graphql files were changed' do
      it 'returns an empty array' do
        expect(matching_specs).to be_empty
      end
    end

    context 'when a changed .graphql file is not read by any spec' do
      let(:changed_files) { %w[app/assets/javascripts/unrelated/query.graphql] }

      before do
        File.write(File.join(spec_folder, 'unrelated_spec.rb'), "RSpec.describe 'unrelated' do\nend\n")
      end

      it 'returns an empty array' do
        expect(matching_specs).to be_empty
      end
    end

    context 'when a changed .graphql file is read by a spec' do
      let(:changed_files) { %w[app/assets/javascripts/work_items/graphql/project_work_items.query.graphql] }

      before do
        File.write(File.join(spec_folder, 'project_work_items_spec.rb'), <<~RUBY)
          RSpec.describe 'work items' do
            let(:query) { get_graphql_query_as_string('work_items/graphql/project_work_items.query.graphql') }
          end
        RUBY
      end

      it 'returns the spec file' do
        expect(matching_specs).to contain_exactly(File.join(spec_folder, 'project_work_items_spec.rb'))
      end
    end

    context 'when a changed EE .graphql file is read by a spec via ee: true' do
      let(:changed_files) do
        %w[ee/app/assets/javascripts/graphql_shared/queries/autocomplete_users.query.graphql]
      end

      before do
        File.write(File.join(spec_folder, 'autocomplete_users_spec.rb'), <<~RUBY)
          RSpec.describe 'autocomplete users' do
            let(:query) do
              get_graphql_query_as_string(
                'graphql_shared/queries/autocomplete_users.query.graphql',
                ee: true
              )
            end
          end
        RUBY
      end

      it 'returns the spec file' do
        expect(matching_specs).to contain_exactly(File.join(spec_folder, 'autocomplete_users_spec.rb'))
      end
    end

    context 'when the same query document is read by more than one spec' do
      let(:changed_files) { %w[app/assets/javascripts/work_items/graphql/project_work_items.query.graphql] }

      before do
        File.write(File.join(spec_folder, 'one_spec.rb'), <<~RUBY)
          RSpec.describe 'one' do
            let(:query) { get_graphql_query_as_string('work_items/graphql/project_work_items.query.graphql') }
          end
        RUBY

        File.write(File.join(spec_folder, 'two_spec.rb'), <<~RUBY)
          RSpec.describe 'two' do
            let(:query) { get_graphql_query_as_string('work_items/graphql/project_work_items.query.graphql') }
          end
        RUBY
      end

      it 'returns every spec that reads it' do
        expect(matching_specs).to contain_exactly(
          File.join(spec_folder, 'one_spec.rb'),
          File.join(spec_folder, 'two_spec.rb')
        )
      end
    end

    context 'when a changed .graphql file is a fragment' do
      let(:changed_files) { %w[app/assets/javascripts/work_items/graphql/fragments/widget.fragment.graphql] }

      before do
        File.write(File.join(spec_folder, 'reader_spec.rb'), <<~RUBY)
          RSpec.describe 'reader' do
            let(:query) { get_graphql_query_as_string('work_items/graphql/project_work_items.query.graphql') }
          end
        RUBY

        File.write(File.join(spec_folder, 'unrelated_spec.rb'), "RSpec.describe 'unrelated' do\nend\n")
      end

      it 'returns every spec that reads a query document, not just ones quoting the fragment path' do
        expect(matching_specs).to contain_exactly(File.join(spec_folder, 'reader_spec.rb'))
      end
    end

    context 'when a changed .graphql file is read via a variable assigned elsewhere in the spec' do
      let(:changed_files) { %w[app/assets/javascripts/work_items/graphql/project_work_items.query.graphql] }

      before do
        File.write(File.join(spec_folder, 'variable_spec.rb'), <<~RUBY)
          RSpec.describe 'variable' do
            query_path = 'work_items/graphql/project_work_items.query.graphql'

            let(:query) { get_graphql_query_as_string(query_path) }
          end
        RUBY
      end

      it 'returns the spec file' do
        expect(matching_specs).to contain_exactly(File.join(spec_folder, 'variable_spec.rb'))
      end
    end
  end
end
