# frozen_string_literal: true
module StarWars
  # Adapted from graphql-relay-js
  # https://github.com/graphql/graphql-relay-js/blob/master/src/__tests__/starWarsSchema.js

  class Ship < GraphQL::Schema::Object
    implements GraphQL::Types::Relay::Node
    global_id_field :id
    field :name, String
    # Test cyclical connection types:
    field :ships, Ship.connection_type, null: false
  end

  class BaseType < GraphQL::Schema::Object
    graphql_name "Base"
    implements GraphQL::Types::Relay::Node
    global_id_field :id
    field :name, String, null: false
    def name
      LazyWrapper.new {
        if object.id.nil?
          raise GraphQL::ExecutionError, "Boom!"
        else
          object.name
        end
      }
    end
    field :planet, String
  end

  class BaseEdge < GraphQL::Types::Relay::BaseEdge
    node_type(BaseType)
  end

  class BaseConnection < GraphQL::Types::Relay::BaseConnection
    edge_type(BaseEdge)
  end

  class BaseConnectionWithoutNodes < GraphQL::Types::Relay::BaseConnection
    edge_type(BaseEdge, nodes_field: false)
  end

  class BasesConnectionWithTotalCountType < GraphQL::Types::Relay::BaseConnection
    edge_type(BaseEdge, nodes_field: false)
    nodes_field

    field :total_count, Integer

    def total_count
      object.items.count
    end
  end

  class NewCustomBaseEdge < GraphQL::Pagination::Connection::Edge
    def upcased_name
      node.name.upcase
    end

    def upcased_parent_name
      parent.name.upcase
    end
  end

  class CustomBaseEdgeType < GraphQL::Types::Relay::BaseEdge
    node_type(BaseType)
    field :upcased_name, String
    field :upcased_parent_name, String
    field :edge_class_name, String

    def edge_class_name
      object.class.name
    end
  end

  class CustomEdgeBaseConnectionType < GraphQL::Types::Relay::BaseConnection
    edge_type(CustomBaseEdgeType, edge_class: NewCustomBaseEdge, nodes_field: true)
    field :total_count_times_100, Integer
    def total_count_times_100
      object.items.count * 100
    end

    field :field_name, String
    def field_name
      object.field.name
    end
  end

  class ShipsWithMaxPageSize < GraphQL::Schema::Resolver
    argument :name_includes, String, required: false
    type Ship.connection_type, null: true

    def resolve(name_includes: nil)
      all_ships = object.ships.map { |ship_id| StarWars::DATA["Ship"][ship_id] }
      if name_includes
        all_ships = all_ships.select { |ship| ship.name.include?(name_includes)}
      end
      all_ships
    end
  end

  class ShipConnectionWithParentType < GraphQL::Types::Relay::BaseConnection
    edge_type(Ship.edge_type)
    field :parent_class_name, String, null: false

    def parent_class_name
      object.parent.class.name
    end
  end

  class ShipsByResolver < GraphQL::Schema::Resolver
    type ShipConnectionWithParentType, null: false

    def resolve
      object.ships.map { |ship_id| StarWars::DATA["Ship"][ship_id] }
    end
  end

  class Faction < GraphQL::Schema::Object
    implements GraphQL::Types::Relay::Node

    field :id, ID, null: false
    def id
      GraphQL::Relay::GlobalIdResolve.new(type: Faction).call(object, {}, context)
    end

    field :name, String
    field :ships, ShipConnectionWithParentType, connection: true, max_page_size: 1000, null: true do
      argument :name_includes, String, required: false
    end

    field :ships_with_default_page_size, ShipConnectionWithParentType, method: :ships, connection: true, default_page_size: 500, null: true do
      argument :name_includes, String, required: false
    end

    field :shipsByResolver, resolver: ShipsByResolver, connection: true

    def ships(name_includes: nil)
      all_ships = object.ships.map {|ship_id| StarWars::DATA["Ship"][ship_id] }
      if name_includes
        case name_includes
        when "error"
          all_ships = GraphQL::ExecutionError.new("error from within connection")
        when "raisedError"
          raise GraphQL::ExecutionError.new("error raised from within connection")
        when "lazyError"
          all_ships = LazyWrapper.new { GraphQL::ExecutionError.new("lazy error from within connection") }
        when "lazyRaisedError"
          all_ships = LazyWrapper.new { raise GraphQL::ExecutionError.new("lazy raised error from within connection") }
        when "null"
          all_ships = nil
        when "lazyObject"
          prev_all_ships = all_ships
          all_ships = LazyWrapper.new { prev_all_ships }
        else
          all_ships = all_ships.select { |ship| ship.name.include?(name_includes)}
        end
      end
      all_ships
    end

    field :shipsWithMaxPageSize, "Ships with max page size", max_page_size: 2, resolver: ShipsWithMaxPageSize

    field :bases, BasesConnectionWithTotalCountType, connection: true do
      argument :name_includes, String, required: false
      argument :complex_order, Boolean, required: false
    end

    def bases(name_includes: nil, complex_order: nil)
      all_bases = Base.where(id: object.bases)
      if name_includes
        all_bases = all_bases.where("name LIKE ?", "%#{name_includes}%")
      end
      if complex_order
        all_bases = all_bases.order("bases.name DESC")
      end

      # Emulates ActiveRecord::Base.connected_to(role: :reading) do
      # https://github.com/rails/rails/blob/d18fc329993df5a583ef721330cffb248ef9a213/activerecord/lib/active_record/connection_handling.rb#L355
      all_bases.load
    end

    field :bases_clone, BaseConnection
    field :bases_by_name, BaseConnection do
      argument :order, String, default_value: "name", required: false
    end
    def bases_by_name(order: nil)
      if order.present?
        @object.bases.order(order)
      else
        @object.bases
      end
    end

    def all_bases
      Base.all
    end

    def all_bases_array
      all_bases.to_a
    end

    field :basesWithMaxLimitRelation, BaseConnection, max_page_size: 2, resolver_method: :all_bases
    field :basesWithMaxLimitArray, BaseConnection, max_page_size: 2, resolver_method: :all_bases_array
    field :basesWithDefaultMaxLimitRelation, BaseConnection, resolver_method: :all_bases
    field :basesWithDefaultMaxLimitArray, BaseConnection, resolver_method: :all_bases_array
    field :basesWithLargeMaxLimitRelation, BaseConnection, max_page_size: 1000, resolver_method: :all_bases
    field :basesWithoutNodes, BaseConnectionWithoutNodes, resolver_method: :all_bases_array

    field :bases_as_sequel_dataset, BasesConnectionWithTotalCountType, connection: true, max_page_size: 1000 do
      argument :name_includes, String, required: false
    end

    def bases_as_sequel_dataset(name_includes: nil)
      all_bases = SequelBase.where(faction_id: @object.id)
      if name_includes
        all_bases = all_bases.where(Sequel.like(:name, "%#{name_includes}%"))
      end
      all_bases
    end

    field :basesWithCustomEdge, CustomEdgeBaseConnectionType, connection: true, resolver_method: :lazy_bases

    def lazy_bases
      LazyNodesWrapper.new(object.bases)
    end
  end

  class IntroduceShipMutation < GraphQL::Schema::RelayClassicMutation
    description "Add a ship to this faction"

    # Nested under `input` in the query:
    argument :ship_name, String, required: false
    argument :faction_id, ID

    # Result may have access to these fields:
    field :ship_edge, Ship.edge_type
    field :faction, Faction
    field :aliased_faction, Faction, hash_key: :aliased_faction, null: true

    def resolve(ship_name: nil, faction_id:)
      if ship_name == 'Millennium Falcon'
        GraphQL::ExecutionError.new("Sorry, Millennium Falcon ship is reserved")
      elsif ship_name == 'Leviathan'
        raise GraphQL::ExecutionError.new("🔥")
      elsif ship_name == "Ebon Hawk"
        LazyWrapper.new { raise GraphQL::ExecutionError.new("💥")}
      else
        ship = DATA.create_ship(ship_name, faction_id)
        faction = DATA["Faction"][faction_id]
        range_add = GraphQL::Relay::RangeAdd.new(
          collection: faction.ships,
          item: ship,
          parent: faction,
          context: context,
        )
        result = {
          ship_edge: range_add.edge,
          faction: range_add.parent,
          aliased_faction: range_add.parent,
        }
        if ship_name == "Slave II"
          LazyWrapper.new(result)
        else
          result
        end
      end
    end
  end

  # GraphQL-Batch knockoff
  class LazyLoader
    def self.defer(ctx, model, id)
      ids = ctx.namespace(:loading)[model] ||= []
      ids << id
      self.new(model: model, id: id, context: ctx)
    end

    def initialize(model:, id:, context:)
      @model = model
      @id = id
      @context = context
    end

    def value
      loaded = @context.namespace(:loaded)[@model] ||= {}
      if loaded.empty?
        ids = @context.namespace(:loading)[@model]
        # Example custom tracing
        @context.trace("lazy_loader", { ids: ids, model: @model}) do
          records = @model.where(id: ids)
          records.each do |record|
            loaded[record.id.to_s] = record
          end
        end
      end

      loaded[@id]
    end
  end

  class LazyWrapper
    def initialize(value = nil, &block)
      if block_given?
        @lazy_value = block
      else
        @value = value
      end
    end

    def value
      @resolved_value = @value || @lazy_value.call
    end
  end

  LazyNodesWrapper = Struct.new(:relation)

  class NewLazyNodesRelationConnection < GraphQL::Pagination::ActiveRecordRelationConnection
    def initialize(wrapper, **kwargs)
      super(wrapper.relation, **kwargs)
    end

    def edge_nodes
      LazyWrapper.new { super }
    end
  end

  class QueryType < GraphQL::Schema::Object
    graphql_name "Query"

    field :rebels, Faction
    def rebels
      StarWars::DATA["Faction"]["1"]
    end

    field :empire, Faction
    def empire
      StarWars::DATA["Faction"]["2"]
    end

    field :largest_base, BaseType

    def largest_base
      Base.find(3)
    end

    field :newest_bases_grouped_by_faction, BaseConnection

    def newest_bases_grouped_by_faction
      Base
        .having('id in (select max(id) from bases group by faction_id)')
        .group(:id)
        .order('faction_id desc')
    end

    field :bases_with_null_name, BaseConnection, null: false

    def bases_with_null_name
      [OpenStruct.new(id: nil)]
    end

    include GraphQL::Types::Relay::HasNodeField

    field :node_with_custom_resolver, GraphQL::Types::Relay::Node do
      argument :id, ID
    end
    def node_with_custom_resolver(id:)
      StarWars::DATA["Faction"]["1"]
    end


    include GraphQL::Types::Relay::HasNodesField

    field :nodes_with_custom_resolver, [GraphQL::Types::Relay::Node, null: true] do
      argument :ids, [ID]
    end
    def nodes_with_custom_resolver(ids:)
      [StarWars::DATA["Faction"]["1"], StarWars::DATA["Faction"]["2"]]
    end

    field :batched_base, BaseType do
      argument :id, ID
    end

    def batched_base(id:)
      LazyLoader.defer(@context, Base, id)
    end
  end

  class MutationType < GraphQL::Schema::Object
    graphql_name "Mutation"
    field :introduceShip, mutation: IntroduceShipMutation
  end

  class Schema < GraphQL::Schema
    query(QueryType)
    mutation(MutationType)
    default_max_page_size 3

    connections.add(LazyNodesWrapper, NewLazyNodesRelationConnection)

    def self.resolve_type(type, object, ctx)
      if object == :test_error
        :not_a_type
      elsif object.is_a?(Base)
        BaseType
      elsif DATA["Faction"].values.include?(object)
        Faction
      elsif DATA["Ship"].values.include?(object)
        Ship
      else
        nil
      end
    end

    def self.object_from_id(node_id, ctx)
      type_name, id = GraphQL::Schema::UniqueWithinType.decode(node_id)
      StarWars::DATA[type_name][id]
    end

    def self.id_from_object(object, type, ctx)
      GraphQL::Schema::UniqueWithinType.encode(type.graphql_name, object.id)
    end

    lazy_resolve(LazyWrapper, :value)
    lazy_resolve(LazyLoader, :value)
  end

  # Create a secondary schema with a default_page_size set. This prevents us
  # from breaking the existing default_max_page_size tests, while still
  # allowing us to test the logic involved with default_page_size.
  class SchemaWithDefaultPageSize < Schema
    default_page_size 2
  end
end
