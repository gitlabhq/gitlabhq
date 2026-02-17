# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Graphql::Authz::GranularTokenAuthorization, feature_category: :permissions do
  include Authz::GranularTokenAuthorizationHelper

  let_it_be(:project) { create(:project) }
  let_it_be(:user) { create(:user, developer_of: project) }
  let_it_be(:access_token) { create(:granular_pat) }

  let(:object) { project }
  let(:arguments) { {} }
  let(:context) { { access_token: } }
  let(:resolve_block) { ->(_obj, _args) { 'field_value' } }
  let(:field) { create_field_with_directive(boundary: 'itself', permissions: ['READ_WIKI']) }

  subject(:extension) { described_class.new(field: field, options: {}) }

  describe 'field extension behavior' do
    it 'is a GraphQL field extension' do
      expect(described_class).to be < GraphQL::Schema::FieldExtension
    end
  end

  describe '#resolve' do
    subject(:resolve) { extension.resolve(object:, arguments:, context:, &resolve_block) }

    it 'raises an ResourceNotAvailable error that includes the message from the service response' do
      expect { resolve }.to raise_error(Gitlab::Graphql::Errors::ResourceNotAvailable, 'Access denied: ' \
        "Your Personal Access Token lacks the required permissions: [read_wiki] for \"#{project.full_path}\".")
    end

    context 'when the token is nil' do
      let(:access_token) { nil }

      it { is_expected.to eq('field_value') }
    end

    context 'when the token is a legacy PAT' do
      let(:access_token) { create(:personal_access_token) }

      it { is_expected.to eq('field_value') }
    end

    context 'when the `granular_personal_access_tokens_for_graphql` flag is disabled' do
      before do
        stub_feature_flags(granular_personal_access_tokens_for_graphql: false)
      end

      it { is_expected.to eq('field_value') }
    end

    context 'when field authorization should be skipped' do
      before do
        allow_next_instance_of(Gitlab::Graphql::Authz::SkipRules, field) do |skip_rules|
          allow(skip_rules).to receive(:should_skip?).and_return(true)
        end
      end

      it { is_expected.to eq('field_value') }
    end

    context 'with a granular token' do
      let_it_be(:access_token) do
        boundary = Authz::Boundary.for(project)
        create(:granular_pat, boundary: boundary, permissions: [:read_wiki, :write_work_item], user: user)
      end

      it { is_expected.to eq('field_value') }

      context 'when a directive cannot be found' do
        let(:field) { create_base_field }

        it 'raises an ResourceNotAvailable error that includes the message from the service response' do
          expect { resolve }.to raise_error(Gitlab::Graphql::Errors::ResourceNotAvailable,
            'Unable to determine boundaries and permissions for authorization')
        end
      end

      context 'with standalone boundaries' do
        context 'when boundary is user' do
          let(:field) { create_field_with_directive(boundary: 'user', permissions: ['READ_WIKI']) }

          it 'raises an ResourceNotAvailable error' do
            expect { resolve }.to raise_error(Gitlab::Graphql::Errors::ResourceNotAvailable)
          end
        end

        context 'when boundary is instance' do
          let(:field) { create_field_with_directive(boundary: 'instance', permissions: ['READ_WIKI']) }

          it 'raises an ResourceNotAvailable error' do
            expect { resolve }.to raise_error(Gitlab::Graphql::Errors::ResourceNotAvailable)
          end
        end
      end

      context 'with caching' do
        it 'does not call service when cached result exists' do
          expect(::Authz::Tokens::AuthorizeGranularScopesService).not_to receive(:new)

          context[:authz_cache] = Set[
            [['read_wiki'], Authz::Boundary::ProjectBoundary, project.project_namespace.id]]

          resolve
        end

        it 'calls service again for different permissions' do
          expect(::Authz::Tokens::AuthorizeGranularScopesService).to receive(:new).twice.and_call_original

          resolve

          different_field = create_field_with_directive(boundary: 'itself', permissions: ['CREATE_ISSUE'])
          different_extension = described_class.new(field: different_field, options: {})
          different_extension.resolve(object: object, arguments: arguments, context: context, &resolve_block)

          expect(context[:authz_cache]).to eq(Set[
            [['read_wiki'], Authz::Boundary::ProjectBoundary, project.project_namespace.id],
            [['create_issue'], Authz::Boundary::ProjectBoundary, project.project_namespace.id]])
        end
      end
    end
  end
end
