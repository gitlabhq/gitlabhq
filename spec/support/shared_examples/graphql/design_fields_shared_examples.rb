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
    let(:schema) { GitlabSchema }
    let(:query) { GraphQL::Query.new(schema) }
    let(:context) { double('Context', schema: schema, query: query, parent: nil) }
    let(:field) { described_class.fields['image'] }
    let(:args) { GraphQL::Query::Arguments::NO_ARGS }
    let(:instance) do
      object = GitlabSchema.sync_lazy(GitlabSchema.object_from_id(object_id))
      object_type.authorized_new(object, query.context)
    end
    let(:instance_b) do
      object_b = GitlabSchema.sync_lazy(GitlabSchema.object_from_id(object_id_b))
      object_type.authorized_new(object_b, query.context)
    end

    it 'resolves to the design image URL' do
      image = field.resolve_field(instance, args, context)
      sha = design.versions.first.sha
      url = ::Gitlab::Routing.url_helpers.project_design_management_designs_raw_image_url(design.project, design, sha)

      expect(image).to eq(url)
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
        image_a = field.resolve_field(instance, args, context)
        image_b = field.resolve_field(instance, args, context)
        image_c = field.resolve_field(instance_b, args, context)
        image_d = field.resolve_field(instance_b, args, context)
        expect(image_a).to eq(image_b)
        expect(image_c).not_to eq(image_b)
        expect(image_c).to eq(image_d)
      end.not_to exceed_query_limit(10)
    end
  end
end
