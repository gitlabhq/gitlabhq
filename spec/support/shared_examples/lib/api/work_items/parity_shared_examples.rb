# frozen_string_literal: true

RSpec.shared_examples 'work item API field parity' do
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
        development
        email_participants
        linked_items
        linked_resources
        notes
        notifications
        participants
      ]).merge(extra_graphql_feature_exceptions)
    end

    # REST currently reuses generic entities for the assignee and milestone widgets, so their
    # field sets don't match the dedicated GraphQL widget types. Skip them until REST exposes
    # feature-specific entities and the payloads can be aligned.
    # error_tracking exposes only identifier, stack_trace and status require external API calls.
    # hierarchy exposes only parent / has_parent. children, ancestors, and rolled-up counts
    # require separate paginated endpoints.
    let(:skipped_feature_comparison) do
      Set.new(%w[assignees milestone error_tracking hierarchy]).merge(extra_skipped_feature_comparison)
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

        expect(rest_fields).to match_array(graphql_fields - %w[type widget_definition])
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

RSpec.shared_examples 'work item API create parity' do
  let(:widget_exceptions) { Set.new }

  # GraphQL mutation args not yet implemented in the REST API
  let(:create_parity_wip) { %w[discussions_to_resolve] }

  let(:graphql_arg_exceptions) do
    Set.new(%w[
      client_mutation_id
      create_source
      description
      namespace_path
      project_path
      vulnerability_id
    ])
  end

  let(:rest_param_exceptions) do
    Set.new(%w[work_item_type_name])
  end

  let(:widget_field_exceptions) do
    { 'start_and_due_date_widget' => %w[is_fixed] }
  end

  # Widgets whose REST/GraphQL input fields are structurally incompatible (e.g. REST uses
  # separate integer IDs where GraphQL uses a single GlobalID) and therefore cannot be
  # aligned via `widget_field_exceptions`. Add the widget name (e.g. 'status_widget') to
  # skip the field-name comparison for that widget entirely.
  let(:widget_field_skipped) { Set.new }

  let(:create_route) do
    API::API.routes.find do |r|
      r.request_method == 'POST' && r.path == '/api/:version/namespaces/:id/-/work_items(.:format)'
    end
  end

  let(:graphql_widget_args) do
    Mutations::WorkItems::Create.arguments
      .select { |k, _| k.to_s.end_with?('Widget') }
      .transform_keys { |k| k.to_s.underscore }
  end

  # Matches feature sub-keys under `features[...]` (e.g. `features[assignees]`) and maps
  # them to widget names (e.g. `assignees_widget`) for comparison against GraphQL.
  let(:rest_widget_params) do
    create_route.params.keys
      .select { |k| k.start_with?('features[') && k.end_with?(']') && k.count('[') == 1 }
      .map { |k| "#{k.delete_prefix('features[').delete_suffix(']')}_widget" }
      .to_set
  end

  let(:graphql_non_widget_args) do
    Mutations::WorkItems::Create.arguments
      .reject { |k, _| k.to_s.end_with?('Widget') }
      .keys
      .map { |k| k.to_s.underscore }
      .to_set - graphql_arg_exceptions - create_parity_wip
  end

  let(:rest_non_widget_params) do
    non_param_keys = %w[id format features fields]
    create_route.params.keys
      .reject { |k| k.include?('[') || non_param_keys.include?(k) }
      .to_set - rest_param_exceptions
  end

  describe 'REST create params vs GraphQL create mutation' do
    it 'keeps top-level non-widget params in sync with known exceptions' do
      expect(rest_non_widget_params).to match_array(graphql_non_widget_args)
    end

    it 'keeps widget params in sync with known exceptions' do
      expect(rest_widget_params).to match_array(graphql_widget_args.keys.to_set - widget_exceptions)
    end

    it 'keeps widget field names in sync with known exceptions', :aggregate_failures do
      shared_widgets = rest_widget_params & graphql_widget_args.keys.to_set

      (shared_widgets - widget_field_skipped).each do |widget_key|
        graphql_fields = graphql_widget_args[widget_key].type.unwrap.arguments.keys
          .map { |k| k.to_s.underscore }.to_set
        feature_key = widget_key.delete_suffix('_widget')
        rest_fields = create_route.params.keys
          .select { |k| k.start_with?("features[#{feature_key}][") }
          .map { |k| k.split('[').last.delete(']') }
          .to_set
        exceptions = widget_field_exceptions.fetch(widget_key, []).to_set

        expect(rest_fields).to match_array(graphql_fields - exceptions),
          "Widget #{widget_key}: REST #{rest_fields.to_a.sort} vs GraphQL #{(graphql_fields - exceptions).to_a.sort}"
      end
    end
  end
end

RSpec.shared_examples 'work item API filter parity' do
  # These are filters that we have not yet migrated to the REST API. See EE parity_spec where we override them.
  let(:filter_parity_wip) do
    %w[exclude_group_work_items exclude_projects]
  end

  let(:not_filter_parity_wip) { [] }
  let(:or_filter_parity_wip) { [] }
  let(:parity_wip) { filter_parity_wip }

  let(:graphql_filter_params) do
    # instad of `iid` we have `iids`
    # `or`, `not` is just a key in GraphQL
    # `hierarchy_filters` is deprecated
    # TODO: work_item_type_ids will be added
    # See https://gitlab.com/gitlab-org/gitlab/-/work_items/593365
    known_exceptions = %w[iid not or hierarchy_filters work_item_type_ids]

    ::Resolvers::Namespaces::WorkItemsResolver.arguments.keys.map(&:underscore) - known_exceptions - parity_wip
  end

  let(:graphql_not_filter_params) do
    # TODO: work_item_type_ids will be added
    # See https://gitlab.com/gitlab-org/gitlab/-/work_items/593365
    known_exceptions = %w[work_item_type_ids]

    ::Types::WorkItems::NegatedWorkItemFilterInputType.arguments.keys.map(&:underscore) -
      known_exceptions - not_filter_parity_wip
  end

  let(:graphql_or_filter_params) do
    ::Types::WorkItems::UnionedWorkItemFilterInputType.arguments.keys.map(&:underscore) - or_filter_parity_wip
  end

  let(:rest_params) do
    non_filter_params = %w[id page per_page cursor fields features]

    route = API::API.routes.find do |r|
      r.request_method == 'GET' && r.path == '/api/:version/namespaces/:id/-/work_items(.:format)'
    end

    route.params.keys - non_filter_params
  end

  let(:rest_filter_params) do
    # Normalize nested bracket params (e.g. `timeframe[start]` -> `timeframe`) so that
    # Hash-typed filter params compare correctly against single GraphQL argument names.
    rest_params
      .reject { |key| key.starts_with?("or") || key.starts_with?("not") }
      .map { |key| key.split('[').first }
      .uniq
  end

  let(:rest_not_filter_params) do
    rest_params.select { |key| key.starts_with?("not[") }.map { |s| s.delete_prefix('not[').delete_suffix(']') }
  end

  let(:rest_or_filter_params) do
    rest_params.select { |key| key.starts_with?("or[") }.map { |s| s.delete_prefix('or[').delete_suffix(']') }
  end

  describe 'REST filter params vs GraphQL filter arguments' do
    it 'keeps filter parameters in sync with known exceptions', :aggregate_failures do
      expect(graphql_filter_params).to match_array(rest_filter_params)
      expect(graphql_or_filter_params).to match_array(rest_or_filter_params)
      expect(graphql_not_filter_params).to match_array(rest_not_filter_params)
    end
  end
end
