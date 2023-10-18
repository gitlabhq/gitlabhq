# frozen_string_literal: true

# To use these shared examples, you may define a value in scope named
# `extra_design_fields`, to pass any extra fields in addition to the
# standard design fields.
RSpec.shared_examples 'a GraphQL type with design fields' do
  let(:extra_design_fields) { [] }

  it { expect(described_class).to require_graphql_authorizations(:read_design) }

  it 'exposes the expected design fields' do
    expected_fields = %i[
      id
      project
      issue
      filename
      full_path
      image
      image_v432x230
      diff_refs
      event
      notes_count
    ] + extra_design_fields

    expect(described_class).to have_graphql_fields(*expected_fields).only
  end

  describe '#image' do
    let_it_be(:current_user) { create(:user) }

    let(:schema) { GitlabSchema }
    let(:query) { GraphQL::Query.new(schema) }
    let(:context) { query.context }
    let(:field) { described_class.fields['image'] }
    let(:args) { { parent: nil } }
    let(:instance) { instantiate(object_id) }
    let(:instance_b) { instantiate(object_id_b) }

    def instantiate(object_id)
      object = GitlabSchema.sync_lazy(GitlabSchema.object_from_id(object_id))
      object_type.authorized_new(object, query.context)
    end

    def resolve_image(instance)
      field.resolve(instance, args, context)
    end

    before do
      context[:current_user] = current_user
      allow(Ability).to receive(:allowed?).with(current_user, :read_design, anything).and_return(true)
    end

    it 'resolves to the design image URL' do
      sha = design.versions.first.sha
      url = ::Gitlab::Routing.url_helpers.project_design_management_designs_raw_image_url(design.project, design, sha)

      expect(resolve_image(instance)).to eq(url)
    end

    it 'has better than O(N) peformance', :request_store do
      # Assuming designs have been loaded (as they must be), the following
      # queries are required:
      # For each distinct version:
      #  - design_management_versions
      #    (Request store is needed so that each version is fetched only once.)
      # For each distinct issue
      #  - issues
      # For each distinct project
      #  - projects
      #  - routes
      #  - namespaces
      # Here that total is:
      #   - 2 x issues
      #   - 2 x versions
      #   - 2 x (projects + routes + namespaces)
      #   = 10
      expect(instance).not_to eq(instance_b) # preload designs themselves.
      expect do
        image_a = resolve_image(instance)
        image_b = resolve_image(instance)
        image_c = resolve_image(instance_b)
        image_d = resolve_image(instance_b)
        expect(image_a).to eq(image_b)
        expect(image_c).not_to eq(image_b)
        expect(image_c).to eq(image_d)
      end.not_to exceed_query_limit(10)
    end
  end
end
