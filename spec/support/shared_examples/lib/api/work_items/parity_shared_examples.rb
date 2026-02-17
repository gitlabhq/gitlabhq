# frozen_string_literal: true

RSpec.shared_examples 'work item API parity' do
  let(:rest_field_names) do
    API::Entities::WorkItemBasic.root_exposures.map { |exposure| exposure.key.to_s }.to_set
  end

  let(:graphql_field_names) do
    Types::WorkItemType.fields.keys.map(&:underscore).to_set
  end

  let(:rest_feature_names) do
    API::Entities::WorkItems::Features::Entity.root_exposures.map { |exposure| exposure.key.to_s }.to_set
  end

  let(:graphql_feature_fields_map) do
    Types::WorkItems::FeaturesType.fields.transform_keys(&:underscore)
  end

  let(:graphql_feature_names) { graphql_feature_fields_map.keys.to_set }
  let(:shared_feature_names) { rest_feature_names & graphql_feature_names }

  let(:extra_graphql_field_exceptions) { Set.new }
  let(:extra_graphql_feature_exceptions) { Set.new }
  let(:extra_skipped_feature_comparison) { Set.new }

  describe 'REST entity vs GraphQL type' do
    let(:rest_field_exceptions) { Set.new(%w[id]) }

    let(:graphql_field_exceptions) do
      Set.new(%w[
        archived
        comment_templates_paths
        description
        description_html
        external_author
        name
        namespace
        project
        promoted_to_epic_url
        show_plan_upgrade_promotion
        user_discussions_count
        widgets
      ]).merge(extra_graphql_field_exceptions)
    end

    let(:graphql_field_aliases) do
      { 'id' => 'global_id' }
    end

    it 'keeps top-level fields in sync with known exceptions' do
      # REST still exposes the integer primary key `id` for backward compatibility, while
      # GraphQL only exposes the global ID. We normalize GraphQL's `id` to `global_id` and
      # mark the numeric `id` as a REST-only exception so future additions must be
      # intentional on both sides.
      canonical_rest_fields = rest_field_names - rest_field_exceptions
      canonical_graphql_fields = graphql_field_names.map { |name| graphql_field_aliases.fetch(name, name) }.to_set

      expect(canonical_rest_fields)
        .to match_array(canonical_graphql_fields - graphql_field_exceptions)
    end
  end

  describe 'Feature exposure parity' do
    let(:graphql_feature_exceptions) do
      Set.new(%w[
        award_emoji
        crm_contacts
        current_user_todos
        designs
        development
        email_participants
        error_tracking
        hierarchy
        linked_items
        linked_resources
        notes
        notifications
        participants
        time_tracking
      ]).merge(extra_graphql_feature_exceptions)
    end

    # REST currently reuses generic entities for the assignee and milestone widgets, so their
    # field sets don't match the dedicated GraphQL widget types. Skip them until REST exposes
    # feature-specific entities and the payloads can be aligned.
    let(:skipped_feature_comparison) do
      Set.new(%w[assignees milestone]).merge(extra_skipped_feature_comparison)
    end

    it 'keeps feature payloads aligned with known differences' do
      expect(rest_feature_names - graphql_feature_names).to be_empty
      expect(graphql_feature_names - rest_feature_names).to match_array(graphql_feature_exceptions)
    end

    it 'keeps shared feature fields aligned with known differences' do
      (shared_feature_names - skipped_feature_comparison).each do |feature_name|
        rest_fields = rest_feature_field_names(feature_name)
        graphql_fields = graphql_feature_field_names(feature_name)

        expect(rest_fields).not_to be_empty
        expect(graphql_fields).not_to be_empty

        expect(rest_fields)
          .to match_array(graphql_fields - feature_field_exceptions(feature_name))
      end
    end
  end

  describe 'REST documentation metadata' do
    it 'documents types for each top-level field' do
      missing_types = API::Entities::WorkItemBasic.root_exposures.filter_map do |exposure|
        missing_rest_type_documentation(exposure)
      end

      expect(missing_types).to be_empty,
        "Missing documentation :type for REST fields: #{missing_types.sort.join(', ')}"
    end

    it 'documents types for feature exposures' do
      missing_types = API::Entities::WorkItems::Features::Entity.root_exposures.filter_map do |exposure|
        missing_rest_type_documentation(exposure)
      end

      expect(missing_types).to be_empty,
        "Missing documentation :type for REST features: #{missing_types.sort.join(', ')}"
    end
  end

  def missing_rest_type_documentation(exposure)
    documentation = exposure.documentation || {}
    type = documentation[:type]
    type = type.call if type.respond_to?(:call)

    return if type.present?

    exposure.key.to_s
  end

  def rest_feature_field_names(feature_name)
    entity_class = rest_feature_entity_class(feature_name)
    return Set.new unless entity_class.respond_to?(:root_exposures)

    entity_class.root_exposures.map { |exposure| exposure.key.to_s }.to_set
  end

  def graphql_feature_field_names(feature_name)
    field = graphql_feature_fields_map[feature_name]
    return Set.new unless field

    graphql_type = unwrap_type(field.type)
    return Set.new unless graphql_type.respond_to?(:fields)

    graphql_type.fields.keys.map(&:underscore).to_set
  end

  def feature_field_exceptions(feature_name)
    exceptions = Set.new(%w[type])

    if feature_name == 'start_and_due_date'
      exceptions.merge(%w[
        roll_up
        is_fixed
        start_date_sourcing_work_item
        start_date_sourcing_milestone
        due_date_sourcing_work_item
        due_date_sourcing_milestone
      ])
    end

    exceptions
  end

  def rest_feature_entity_class(feature_name)
    custom_mappings = {
      'assignees' => ::API::Entities::UserBasic,
      'milestone' => ::API::Entities::Milestone
    }

    return custom_mappings[feature_name] if custom_mappings.key?(feature_name)

    features_module = API::Entities::WorkItems::Features
    constant_name = feature_name.camelize

    features_module.const_get(constant_name, false)
  rescue NameError
    nil
  end

  def unwrap_type(type)
    type.respond_to?(:unwrap) ? type.unwrap : type
  end
end
