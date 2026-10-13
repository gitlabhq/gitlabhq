# frozen_string_literal: true

require 'fast_spec_helper'
require_relative '../../../tooling/ci/graphql_query_document_specs'

RSpec.describe CI::GraphqlQueryDocumentSpecs, feature_category: :tooling do
  let(:instance) { described_class.new(scope: scope) }
  let(:scope) { nil }

  describe '#changed_graphql_files' do
    before do
      allow(instance).to receive(:changed_files_with_old_paths).and_return(
        [
          'app/models/user.rb',
          'app/assets/javascripts/work_items/graphql/project_work_items.query.graphql',
          'ee/app/assets/javascripts/graphql_shared/queries/autocomplete_users.query.graphql',
          'doc/api/graphql/reference/_index.md'
        ]
      )
    end

    it 'returns only the changed frontend GraphQL query documents' do
      expect(instance.changed_graphql_files).to match_array(
        [
          'app/assets/javascripts/work_items/graphql/project_work_items.query.graphql',
          'ee/app/assets/javascripts/graphql_shared/queries/autocomplete_users.query.graphql'
        ]
      )
    end
  end

  describe '#changed_files_with_old_paths' do
    let(:git_diff_command) { 'git diff --name-only --no-renames HEAD~..HEAD' }

    it 'returns both the old and new path of a renamed file' do
      allow(instance).to receive(:`).with(git_diff_command) do
        system('true') # sets $? for real, so the method's own success check is exercised
        "app/assets/javascripts/old.query.graphql\napp/assets/javascripts/new.query.graphql\n"
      end

      expect(instance.changed_files_with_old_paths).to contain_exactly(
        'app/assets/javascripts/old.query.graphql',
        'app/assets/javascripts/new.query.graphql'
      )
    end

    it 'raises when git diff fails' do
      allow(instance).to receive(:`).with(git_diff_command) { system('false') }

      expect { instance.changed_files_with_old_paths }.to raise_error('git diff failed')
    end
  end

  describe '#matching_specs' do
    let(:mapped_specs) do
      [
        'spec/requests/api/graphql/project/work_items_spec.rb',
        'ee/spec/requests/api/graphql/project/autocomplete_users_spec.rb'
      ]
    end

    let(:mapping) { instance_double(Tooling::Mappings::GraphqlQueryDocumentMappings, execute: mapped_specs) }

    before do
      allow(instance).to receive(:changed_graphql_files).and_return(['some/query.graphql'])
      allow(Tooling::Mappings::GraphqlQueryDocumentMappings).to receive(:new)
        .with(['some/query.graphql'])
        .and_return(mapping)
    end

    context 'when no scope is given' do
      it 'returns every matching spec' do
        expect(instance.matching_specs).to match_array(mapped_specs)
      end
    end

    context 'when scope is foss' do
      let(:scope) { 'foss' }

      it 'excludes EE specs' do
        expect(instance.matching_specs).to contain_exactly('spec/requests/api/graphql/project/work_items_spec.rb')
      end
    end

    context 'when scope is ee' do
      let(:scope) { 'ee' }

      it 'only returns EE specs' do
        expect(instance.matching_specs).to contain_exactly(
          'ee/spec/requests/api/graphql/project/autocomplete_users_spec.rb'
        )
      end
    end

    context 'when nothing matches' do
      let(:mapped_specs) { [] }

      it 'returns an empty array' do
        expect(instance.matching_specs).to eq([])
      end
    end

    context 'when the mapping raises' do
      before do
        allow(Tooling::Mappings::GraphqlQueryDocumentMappings).to receive(:new)
          .with(['some/query.graphql'])
          .and_raise(StandardError, 'boom')
      end

      it 'propagates the error, so the job fails loudly instead of running the full suite' do
        expect { instance.matching_specs }.to raise_error(StandardError, 'boom')
      end
    end
  end
end
