# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Graphql::Authz::GranularTokenAuthorization, feature_category: :permissions do
  include Authz::GranularTokenAuthorizationHelper

  let_it_be(:project) { create(:project) }
  let_it_be(:user) { create(:user, developer_of: project) }
  let_it_be(:access_token) { create(:granular_pat, user: user) }

  let(:object) { project }
  let(:arguments) { {} }
  let(:context) { { access_token: } }
  let(:resolve_block) { ->(_obj, _args) { 'field_value' } }
  let(:field) { create_field_with_directive(boundary: 'itself', permissions: ['read_wiki']) }
  let(:owner_without_directive) do
    Class.new(GraphQL::Schema::Object) { graphql_name 'GranularTokenAuthorizationOwnerType' }
  end

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
        'This operation requires a fine-grained personal access token ' \
        "with the following project permissions: [Wiki: Read].")
    end

    context 'when the token is nil' do
      let(:access_token) { nil }

      it { is_expected.to eq('field_value') }
    end

    context 'when the token is a legacy PAT' do
      let(:access_token) { create(:personal_access_token) }

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
        create(:granular_pat, boundary: boundary, permissions: [:read_wiki, :create_work_item], user: user)
      end

      it { is_expected.to eq('field_value') }

      context 'when a directive cannot be found' do
        let(:field) { create_base_field(owner: owner_without_directive) }

        it 'raises an ResourceNotAvailable error that includes the message from the service response' do
          expect { resolve }.to raise_error(Gitlab::Graphql::Errors::ResourceNotAvailable,
            "Access denied: This operation doesn't support fine-grained personal access tokens.")
        end
      end

      context 'with standalone boundaries' do
        context 'when boundary is user' do
          let(:field) { create_field_with_directive(boundary: 'user', permissions: ['read_wiki']) }

          it 'raises an ResourceNotAvailable error' do
            expect { resolve }.to raise_error(Gitlab::Graphql::Errors::ResourceNotAvailable)
          end
        end

        context 'when boundary is instance' do
          let(:field) { create_field_with_directive(boundary: 'instance', permissions: ['read_wiki']) }

          it 'raises an ResourceNotAvailable error' do
            expect { resolve }.to raise_error(Gitlab::Graphql::Errors::ResourceNotAvailable)
          end
        end
      end

      context 'with multi-boundary directives' do
        let(:project_directive) do
          create_directive(boundary: 'itself', permissions: ['read_wiki'], boundary_type: 'project')
        end

        let(:group_directive) do
          create_directive(boundary: 'itself', permissions: ['read_wiki'], boundary_type: 'group')
        end

        before do
          allow(field).to receive(:directives).and_return([project_directive, group_directive])
        end

        context 'when the correct boundary needs to be selected among multiple directives' do
          let_it_be(:group) { create(:group) }
          let_it_be(:project_in_group) { create(:project, group: group) }
          let_it_be(:group_member) { create(:user, developer_of: group) }
          let_it_be(:project_member) { create(:user, developer_of: project_in_group) }

          let(:group_scoped_token) do
            create(:granular_pat, boundary: Authz::Boundary.for(group), permissions: [:read_wiki], user: group_member)
          end

          let(:project_scoped_token) do
            create(:granular_pat, boundary: Authz::Boundary.for(project_in_group), permissions: [:read_wiki],
              user: project_member)
          end

          let(:instance_scoped_token) do
            create(:granular_pat, boundary: Authz::Boundary.for(:instance), permissions: [:read_wiki],
              user: group_member)
          end

          let(:instance_directive) do
            create_directive(boundary: 'instance', permissions: ['read_wiki'], boundary_type: 'instance')
          end

          def expect_boundary_selected(directives_order, expected_boundary_class)
            allow(field).to receive(:directives).and_return(directives_order)
            expect(extension).to receive(:authorize_with_cache!).with(
              context, instance_of(expected_boundary_class), anything
            ).and_call_original
            resolve
          end

          context 'when the object is a group, and both group and a standalone directive are present' do
            let(:object) { group }
            let(:context) { { access_token: group_scoped_token } }

            it 'selects group over instance when instance is listed first' do
              expect_boundary_selected([instance_directive, group_directive], Authz::Boundary::GroupBoundary)
            end
          end

          context 'when the object is a project, and both project and group directives are present' do
            let(:object) { project_in_group }
            let(:context) { { access_token: project_scoped_token } }

            it 'selects project over group when group is listed first' do
              expect_boundary_selected([group_directive, project_directive], Authz::Boundary::ProjectBoundary)
            end
          end

          context 'when the object is a group, and both project and group directives are present' do
            let(:object) { group }
            let(:context) { { access_token: group_scoped_token } }

            it 'tries project first, fails to match, then falls back to group' do
              expect_boundary_selected([group_directive, project_directive], Authz::Boundary::GroupBoundary)
            end
          end

          context 'when the object is instance-level, and both group and a standalone directive are present' do
            let(:object) { nil }
            let(:context) { { access_token: instance_scoped_token } }

            it 'tries group first, fails to extract, then falls back to instance' do
              expect_boundary_selected([group_directive, instance_directive], Authz::Boundary::NilBoundary)
            end
          end
        end

        context 'when a directive is misconfigured and boundary extraction raises ArgumentError' do
          before do
            allow_next_instance_of(Gitlab::Graphql::Authz::BoundaryExtractor) do |extractor|
              allow(extractor).to receive(:extract).and_raise(ArgumentError)
            end
          end

          it 'propagates the ArgumentError so misconfigured directives are not silently swallowed' do
            expect { resolve }.to raise_error(ArgumentError)
          end
        end

        context 'when a directive has nil boundary_type' do
          let(:nil_type_directive) do
            create_directive(boundary: 'itself', permissions: ['read_wiki'], boundary_type: nil)
          end

          before do
            allow(field).to receive(:directives).and_return([nil_type_directive, group_directive])
          end

          it 'matches the first extractable boundary regardless of type' do
            expect { resolve }.not_to raise_error
          end
        end

        context 'when the first directive does not extract a boundary and a later directive matches' do
          before do
            allow(field).to receive(:directives).and_return([group_directive, project_directive])
            allow(extension).to receive(:boundary).with(object, arguments, context, group_directive).and_return(nil)
            allow(extension).to receive(:boundary).with(object, arguments, context, project_directive).and_call_original
          end

          it 'skips the non-extractable directive and keeps searching' do
            expect { resolve }.not_to raise_error
          end
        end

        context 'when a later matching directive uses a registered boundary proc' do
          let(:owner_with_proc) do
            Class.new(Types::BaseObject) { graphql_name 'GranularTokenProcOwnerType' }
          end

          let(:boundary_proc) { ->(_obj) { project } }

          let(:field) do
            create_field_with_directive(
              owner: owner_with_proc,
              boundary_type: 'project',
              permissions: ['read_wiki']
            )
          end

          before do
            allow(field).to receive(:directives).and_return([group_directive, project_directive])
            allow(extension).to receive(:boundary).and_call_original
            allow(extension).to receive(:boundary)
              .with(object, arguments, context, group_directive)
              .and_return(nil)
            allow(owner_with_proc).to receive(:granular_token_boundary_procs)
              .and_return({ 'project' => boundary_proc })
            allow(Gitlab::Graphql::Authz::BoundaryExtractor).to receive(:new).and_call_original
          end

          it 'passes the proc to BoundaryExtractor for the matching directive' do
            expect(Gitlab::Graphql::Authz::BoundaryExtractor).to receive(:new).with(
              hash_including(boundary_proc: boundary_proc)
            ).at_least(:once).and_call_original

            expect { resolve }.not_to raise_error
          end
        end
      end

      context 'with a boundary proc registered on the field owner' do
        let(:owner_with_proc) do
          Class.new(Types::BaseObject) { graphql_name 'GranularTokenProcOwnerType' }
        end

        let(:boundary_proc) { ->(_obj) { project } }

        let(:field) do
          create_field_with_directive(
            owner: owner_with_proc,
            boundary_type: 'project',
            permissions: ['read_wiki']
          )
        end

        before do
          allow(owner_with_proc).to receive(:granular_token_boundary_procs)
            .and_return({ 'project' => boundary_proc })
        end

        it 'passes the proc to BoundaryExtractor' do
          expect(Gitlab::Graphql::Authz::BoundaryExtractor).to receive(:new).with(
            hash_including(boundary_proc: boundary_proc)
          ).and_call_original

          expect { resolve }.not_to raise_error
        end

        context 'when no proc is registered for the boundary_type' do
          before do
            allow(owner_with_proc).to receive(:granular_token_boundary_procs).and_return({})
          end

          it 'passes nil boundary_proc to BoundaryExtractor' do
            expect(Gitlab::Graphql::Authz::BoundaryExtractor).to receive(:new).with(
              hash_including(boundary_proc: nil)
            ).and_call_original

            expect { resolve }.to raise_error(Gitlab::Graphql::Errors::ResourceNotAvailable)
          end
        end

        context 'when the field owner does not respond to granular_token_boundary_procs' do
          let(:field) do
            create_field_with_directive(
              owner: owner_without_directive,
              boundary_type: 'project',
              permissions: ['read_wiki']
            )
          end

          it 'passes nil boundary_proc to BoundaryExtractor' do
            expect(Gitlab::Graphql::Authz::BoundaryExtractor).to receive(:new).with(
              hash_including(boundary_proc: nil)
            ).and_call_original

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

          different_field = create_field_with_directive(boundary: 'itself', permissions: ['create_issue'])
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
