# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Graphql::Authz::BoundaryExtractors::Preloader, :request_store,
  feature_category: :permissions do
  include Authz::GranularTokenAuthorizationHelper

  let_it_be(:group) { create(:group) }
  let_it_be_with_reload(:project) { create(:project, group: group) }

  let(:directives) { [create_directive(boundary: 'project', boundary_type: 'project')] }
  let(:type) { granular_type }
  let(:access_token) { create(:granular_pat) }
  let(:context) { { access_token: access_token } }

  def granular_type
    class_double(Types::BaseObject,
      granular_scope_authorization: ::Gitlab::Graphql::Authz::GranularScopeAuthorization.new(directives))
  end

  def boundary_cache
    ::Gitlab::SafeRequestStore.read(described_class::GRANULAR_TOKENS_BOUNDARY_CACHE_KEY)
  end

  describe '.preload_boundaries' do
    let_it_be_with_reload(:issues) { create_list(:issue, 3, project: project) }

    let(:single_node) { [issues.first] }
    let(:multiple_nodes) { issues }
    let(:nodes) { multiple_nodes }

    subject(:preload) { described_class.preload_boundaries(type, nodes, context) }

    shared_examples 'skips preloading' do
      specify do
        expect(ActiveRecord::Associations::Preloader).not_to receive(:new)

        preload
      end
    end

    context 'when there are no granular directives' do
      let(:directives) { [] }

      it_behaves_like 'skips preloading'

      it { is_expected.to be_nil }
    end

    context 'when the request has no access token' do
      let(:access_token) { nil }

      it_behaves_like 'skips preloading'
    end

    context 'when the access token is not a granular token' do
      let(:access_token) { instance_double(DeployToken) }

      it_behaves_like 'skips preloading'
    end

    context 'when a directive has no boundary method' do
      let(:directives) { [create_directive(boundary_type: 'project')] }

      it_behaves_like 'skips preloading'
    end

    context 'when a project boundary does not match an association on the nodes' do
      let(:directives) { [create_directive(boundary: 'nonexistent', boundary_type: 'project')] }

      it_behaves_like 'skips preloading'
    end

    context 'when a group boundary does not match an association on the nodes' do
      let(:directives) { [create_directive(boundary: 'nonexistent', boundary_type: 'group')] }

      it_behaves_like 'skips preloading'
    end

    context 'when a project boundary resolves to a non-project association' do
      let(:directives) { [create_directive(boundary: 'author', boundary_type: 'project')] }

      it_behaves_like 'skips preloading'
    end

    context 'when the directives resolve a project boundary' do
      it 'loads the boundary and its project namespace on each node' do
        preload

        expect(nodes.map { |node| node.association(:project) }).to all(be_loaded)
        expect(nodes.map { |node| node.project.association(:project_namespace) }).to all(be_loaded)
      end

      it 'caches the loaded boundary and project namespace records' do
        preload

        expect(boundary_cache.values).to include(project, project.project_namespace)
      end
    end

    context 'when the boundary is already in the request cache' do
      let(:nodes) { single_node }

      before do
        ::Gitlab::SafeRequestStore.write(
          described_class::GRANULAR_TOKENS_BOUNDARY_CACHE_KEY,
          { [project.class.name, project.id] => project }
        )
      end

      it 'reuses the cached records as available_records' do
        expect(ActiveRecord::Associations::Preloader)
          .to receive(:new)
          .with(hash_including(available_records: include(project)))
          .and_call_original

        preload
      end
    end

    context 'when the boundary is the project itself' do
      let(:directives) { [create_directive(boundary: 'itself', boundary_type: 'project')] }
      let(:nodes) { [project] }

      it 'loads the project namespace on each node' do
        preload

        expect(nodes.map { |node| node.association(:project_namespace) }).to all(be_loaded)
      end
    end

    context 'when the directives resolve a group boundary' do
      let_it_be_with_reload(:milestone) { create(:milestone, group: group) }

      let(:directives) { [create_directive(boundary: 'group', boundary_type: 'group')] }
      let(:nodes) { [milestone] }

      it 'loads the boundary association on each node' do
        preload

        expect(nodes.map { |node| node.association(:group) }).to all(be_loaded)
      end

      it 'caches the loaded boundary records' do
        preload

        expect(boundary_cache.values).to include(group)
      end
    end

    context 'with a legacy token' do
      let(:access_token) { create(:personal_access_token) }

      it 'also preloads root namespace enforcement' do
        expect_next_instance_of(::Authz::Tokens::EnforcementCache) do |cache|
          expect(cache).to receive(:any_enforced?).and_call_original
        end

        preload
      end
    end

    context 'with a granular token' do
      it 'does not preload root namespace enforcement' do
        expect(::Authz::Tokens::EnforcementCache).not_to receive(:new)

        preload
      end
    end
  end

  describe '.granular_directives' do
    let_it_be(:issue) { create(:issue, project: project) }

    let(:nodes) { [issue] }

    subject(:granular_directives) { described_class.granular_directives(type, nodes, context) }

    context 'when the type defines granular authorization' do
      it { is_expected.to eq(directives) }
    end

    context 'when the type defines granular authorization without directives' do
      let(:directives) { [] }

      it { is_expected.to eq([]) }
    end

    context 'when the type is an interface that resolves to a concrete type' do
      let(:type) { class_double(Types::MemberInterface) }
      let(:concrete_type) { granular_type }

      before do
        allow(type).to receive(:resolve_type).with(nodes.first, context).and_return(concrete_type)
      end

      it { is_expected.to eq(directives) }
    end

    context 'when the type defines neither granular authorization nor resolve_type' do
      let(:type) { class_double(Types::BaseObject, granular_scope_authorization: nil) }

      it { is_expected.to eq([]) }
    end
  end
end
