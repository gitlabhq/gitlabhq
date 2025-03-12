# frozen_string_literal: true
require "spec_helper"

describe GraphQL::Schema::Subscription do
  class SubscriptionFieldSchema < GraphQL::Schema
    use GraphQL::Schema::Warden if ADD_WARDEN
    TOOTS = []
    ALL_USERS = {
      "dhh" => {handle: "dhh", private: false},
      "matz" => {handle: "matz", private: false},
      "_why" => {handle: "_why", private: true},
    }

    USERS = {}

    class User < GraphQL::Schema::Object
      field :handle, String, null: false
      field :private, Boolean, null: false
    end

    class Toot < GraphQL::Schema::Object
      field :handle, String, null: false
      field :body, String, null: false

      def self.visible?(context)
        !context[:legacy_schema]
      end
    end

    class LegacyToot < Toot
      field :likes_count, Int, null: false

      def self.visible?(context)
        !!context[:legacy_schema]
      end
    end

    class Query < GraphQL::Schema::Object
      field :toots, [Toot], null: false
      field :toots, [LegacyToot], null: false

      def toots
        TOOTS
      end
    end

    class BaseSubscription < GraphQL::Schema::Subscription
    end

    class TootWasTooted < BaseSubscription
      argument :handle, String, loads: User, as: :user, camelize: false

      field :toot, Toot, null: false
      field :user, User, null: false

      def self.visible?(context)
        !context[:legacy_schema]
      end

      # Can't subscribe to private users
      def authorized?(user:, path:, query:)
        if user[:private]
          context[:last_path] = path
          false
        else
          true
        end
      end

      def subscribe(user:, **args)
        if context[:prohibit_subscriptions]
          raise GraphQL::ExecutionError, "You don't have permission to subscribe"
        else
          # Default is to return :no_response
          super
        end
      end

      def update(user:, **args)
        if context[:viewer] == user
          # don't update for one's own toots.
          # (IRL it would make more sense to implement this in `#subscribe`)
          NO_UPDATE
        elsif context[:update_and_unsubscribe]
          unsubscribe(super)
        elsif context[:update_error_and_unsubscribe]
          unsubscribe(GraphQL::ExecutionError.new("Boom!"))
        else
          # This assumes that trigger object can fulfill `{toot:, user:}`,
          # for testing that the default implementation is `return object`
          super
        end
      end
    end

    class LegacyTootWasTooted < TootWasTooted
      field :toot, LegacyToot

      def self.visible?(context)
        !!context[:legacy_schema]
      end
    end

    class DirectTootWasTooted < BaseSubscription
      subscription_scope :viewer
      field :toot, Toot, null: false
      field :user, User, null: false
    end

    class DirectTootWasTootedWithOptionalScope < DirectTootWasTooted
      subscription_scope :viewer, optional: true
    end

    # Test initial response, which returns all users
    class UsersJoined < BaseSubscription
      class UsersJoinedManualPayload < GraphQL::Schema::Object
        field :users, [User],
          description: "Includes newly-created users, or all users on the initial load"
      end

      payload_type UsersJoinedManualPayload

      def subscribe
        { users: USERS.values }
      end

      # Test returning a custom object from #update
      def update
        { users: object[:new_users] }
      end
    end

    # Like above, but doesn't override #subscription,
    # to make sure it works without arguments
    class NewUsersJoined < BaseSubscription
      field :users, [User],
        description: "Includes newly-created users, or all users on the initial load"
    end

    class Subscription < GraphQL::Schema::Object
      field :toot_was_tooted, subscription: TootWasTooted, extras: [:path, :query]
      field :toot_was_tooted, subscription: LegacyTootWasTooted, extras: [:path, :query]
      field :direct_toot_was_tooted, subscription: DirectTootWasTooted
      field :direct_toot_was_tooted_with_optional_scope, subscription: DirectTootWasTootedWithOptionalScope
      field :users_joined, subscription: UsersJoined
      field :new_users_joined, subscription: NewUsersJoined
    end

    class Mutation < GraphQL::Schema::Object
      field :toot, Toot, null: false do
        argument :body, String
      end

      def toot(body:)
        handle = context[:viewer][:handle]
        toot = { handle: handle, body: body }
        TOOTS << toot
        SubscriptionFieldSchema.trigger(:toot_was_tooted, {handle: handle}, toot)
      end
    end

    query(Query)
    mutation(Mutation)
    subscription(Subscription)

    rescue_from(StandardError) { |err, *rest|
      if err.is_a?(GraphQL::Subscriptions::SubscriptionScopeMissingError)
        raise err
      else
        err2 = RuntimeError.new("This should never happen: #{err.class}: #{err.message}")
        err2.set_backtrace(err.backtrace)
        raise err2
      end
    }

    def self.object_from_id(id, ctx)
      USERS[id]
    end

    def self.resolve_type(type, obj, ctx)
      User
    end

    def self.unauthorized_field(err)
      path = err.context[:last_path]
      raise GraphQL::ExecutionError, "Can't subscribe to private user (#{path})"
    end

    class InMemorySubscriptions < GraphQL::Subscriptions
      SUBSCRIPTION_REGISTRY = {}

      EVENT_REGISTRY = Hash.new { |h, k| h[k] = [] }

      def write_subscription(query, events)
        query.context[:subscription_mailbox] = []
        subscription_id = build_id
        events.each do |ev|
          EVENT_REGISTRY[ev.topic] << subscription_id
        end
        SUBSCRIPTION_REGISTRY[subscription_id] = [query, events]
      end

      def execute_all(event, object)
        EVENT_REGISTRY[event.topic].each do |sub_id|
          execute(sub_id, event, object)
        end
      end

      def read_subscription(subscription_id)
        query, _events = SUBSCRIPTION_REGISTRY[subscription_id]
        {
          query_string: query.query_string,
          context: query.context.to_h,
          variables: query.provided_variables,
          operation_name: query.selected_operation_name,
        }
      end

      def deliver(subscription_id, result)
        query, _events = SUBSCRIPTION_REGISTRY[subscription_id]
        query.context[:subscription_mailbox] << result
      end

      def delete_subscription(subscription_id)
        _query, events = SUBSCRIPTION_REGISTRY.delete(subscription_id)
        events.each do |ev|
          EVENT_REGISTRY[ev.topic].delete(subscription_id)
        end
      end
    end

    use InMemorySubscriptions
  end

  def exec_query(*args, **kwargs)
    SubscriptionFieldSchema.execute(*args, **kwargs)
  end

  def in_memory_subscription_count
    SubscriptionFieldSchema::InMemorySubscriptions::SUBSCRIPTION_REGISTRY.size
  end

  before do
    # Reset databases
    SubscriptionFieldSchema::TOOTS.clear
    # Reset in order:
    SubscriptionFieldSchema::USERS.clear
    SubscriptionFieldSchema::ALL_USERS.map do |k, v|
      SubscriptionFieldSchema::USERS[k] = v.dup
    end

    SubscriptionFieldSchema::InMemorySubscriptions::SUBSCRIPTION_REGISTRY.clear
    SubscriptionFieldSchema::InMemorySubscriptions::EVENT_REGISTRY.clear
  end

  it "generates a return type" do
    return_type = SubscriptionFieldSchema::TootWasTooted.payload_type
    assert_equal "TootWasTootedPayload", return_type.graphql_name
    assert_equal ["toot", "user"], return_type.fields.keys
  end

  it "can use a premade `payload_type`" do
    return_type = SubscriptionFieldSchema::UsersJoined.payload_type
    assert_equal "UsersJoinedManualPayload", return_type.graphql_name
    assert_equal ["users"], return_type.fields.keys
    assert_equal SubscriptionFieldSchema::UsersJoined::UsersJoinedManualPayload, return_type
  end

  describe "initial subscription" do
    it "calls #subscribe for the initial subscription and returns the result" do
      res = exec_query <<-GRAPHQL
      subscription {
        usersJoined {
          users {
            handle
          }
        }
      }
      GRAPHQL
      assert_equal ["dhh", "matz", "_why"], res["data"]["usersJoined"]["users"].map { |u| u["handle"] }
      assert_equal 1, in_memory_subscription_count

      # It works a second time
      res = exec_query <<-GRAPHQL
      subscription {
        usersJoined {
          users {
            handle
          }
        }
      }
      GRAPHQL
      assert_equal ["dhh", "matz", "_why"], res["data"]["usersJoined"]["users"].map { |u| u["handle"] }
      assert_equal 2, in_memory_subscription_count
    end

    it "rejects the subscription if #subscribe raises an error" do
      res = exec_query <<-GRAPHQL, context: { prohibit_subscriptions: true }
      subscription {
        tootWasTooted(handle: "matz") {
          toot { body }
        }
      }
      GRAPHQL

      expected_response = {
        "data"=>nil,
        "errors"=>[
          {
            "message"=>"You don't have permission to subscribe",
            "locations"=>[{"line"=>2, "column"=>9}],
            "path"=>["tootWasTooted"]
          }
        ]
      }

      assert_equal(expected_response, res)
      assert_equal 0, in_memory_subscription_count
    end

    it "doesn't subscribe if `loads:` fails" do
      res = exec_query <<-GRAPHQL
      subscription {
        tootWasTooted(handle: "jack") {
          toot { body }
        }
      }
      GRAPHQL

      expected_response = {
        "data" => nil,
        "errors" => [
          {
            "message"=>"No object found for `handle: \"jack\"`",
            "locations"=>[{"line"=>2, "column"=>9}],
            "path"=>["tootWasTooted"]
          }
        ]
      }
      assert_equal(expected_response, res)
      assert_equal 0, in_memory_subscription_count
    end

    it "rejects if #authorized? fails" do
      res = exec_query <<-GRAPHQL
      subscription {
        tootWasTooted(handle: "_why") {
          toot { body }
        }
      }
      GRAPHQL
      expected_response = {
        "data"=>nil,
        "errors"=>[
          {
            "message"=>"Can't subscribe to private user ([\"tootWasTooted\"])",
            "locations"=>[{"line"=>2, "column"=>9}],
            "path"=>["tootWasTooted"]
          },
        ],
      }
      assert_equal(expected_response, res)
    end

    it "sends no initial response if :no_response is returned, which is the default" do
      assert_equal 0, in_memory_subscription_count

      res = exec_query <<-GRAPHQL
      subscription {
        tootWasTooted(handle: "matz") {
          toot { body }
        }
      }
      GRAPHQL
      assert_equal({"data" => {}}, res)
      assert_equal 1, in_memory_subscription_count
    end

    it "works when there are no arguments" do
      assert_equal 0, in_memory_subscription_count

      res = exec_query <<-GRAPHQL
      subscription {
        newUsersJoined {
          users {
            handle
          }
        }
      }
      GRAPHQL
      assert_equal({"data" => {}}, res)
      assert_equal 1, in_memory_subscription_count
    end
  end

  describe "updates" do
    it "updates with `object` by default" do
      res = exec_query <<-GRAPHQL
      subscription {
        tootWasTooted(handle: "matz") {
          toot { body }
        }
      }
      GRAPHQL
      assert_equal 1, in_memory_subscription_count
      obj = OpenStruct.new(toot: { body: "I am a C programmer" }, user: SubscriptionFieldSchema::USERS["matz"])
      SubscriptionFieldSchema.subscriptions.trigger(:toot_was_tooted, {handle: "matz"}, obj)

      mailbox = res.context[:subscription_mailbox]
      update_payload = mailbox.first
      assert_equal "I am a C programmer", update_payload["data"]["tootWasTooted"]["toot"]["body"]
    end

    it "updates with the returned value" do
      res = exec_query <<-GRAPHQL
      subscription {
        usersJoined {
          users {
            handle
          }
        }
      }
      GRAPHQL

      assert_equal 1, in_memory_subscription_count
      SubscriptionFieldSchema.subscriptions.trigger(:users_joined, {}, {new_users: [{handle: "eileencodes"}, {handle: "tenderlove"}]})

      update = res.context[:subscription_mailbox].first
      assert_equal [{"handle" => "eileencodes"}, {"handle" => "tenderlove"}], update["data"]["usersJoined"]["users"]
    end

    it "skips the update if `NO_UPDATE` is returned, but updates other subscribers" do
      query_str = <<-GRAPHQL
      subscription {
        tootWasTooted(handle: "matz") {
          toot { body }
        }
      }
      GRAPHQL

      res1 = exec_query(query_str)
      res2 = exec_query(query_str, context: { viewer: SubscriptionFieldSchema::USERS["matz"] })
      assert_equal 2, in_memory_subscription_count

      obj = OpenStruct.new(toot: { body: "Merry Christmas, here's a new Ruby version" }, user: SubscriptionFieldSchema::USERS["matz"])
      SubscriptionFieldSchema.subscriptions.trigger(:toot_was_tooted, {handle: "matz"}, obj)

      mailbox1 = res1.context[:subscription_mailbox]
      mailbox2 = res2.context[:subscription_mailbox]
      # The anonymous viewer got an update:
      assert_equal "Merry Christmas, here's a new Ruby version", mailbox1.first["data"]["tootWasTooted"]["toot"]["body"]
      # But not matz:
      assert_equal [], mailbox2
      # `NO_UPDATE` doesn't cause an unsubscribe
      assert_equal 2, in_memory_subscription_count
    end

    it "can unsubscribe with a final update" do
      res = exec_query(<<-GRAPHQL, context: { update_and_unsubscribe: true })
      subscription {
        tootWasTooted(handle: "matz") {
          toot { body }
        }
      }
      GRAPHQL
      assert_equal 1, in_memory_subscription_count
      toot = OpenStruct.new(toot: { body: "Merry Christmas, here's a new Ruby version" }, user: SubscriptionFieldSchema::USERS["matz"])
      SubscriptionFieldSchema.subscriptions.trigger(:toot_was_tooted, {handle: "matz"}, toot)

      mailbox = res.context[:subscription_mailbox]
      assert_equal ["Merry Christmas, here's a new Ruby version"], mailbox.map { |m| m["data"]["tootWasTooted"]["toot"]["body"] }
      assert_equal 0, in_memory_subscription_count
    end

    it "can unsubscribe with an error" do
      res = exec_query(<<-GRAPHQL, context: { update_error_and_unsubscribe: true })
      subscription {
        tootWasTooted(handle: "matz") {
          toot { body }
        }
      }
      GRAPHQL
      assert_equal 1, in_memory_subscription_count
      toot = OpenStruct.new(toot: { body: "Merry Christmas, here's a new Ruby version" }, user: SubscriptionFieldSchema::USERS["matz"])
      SubscriptionFieldSchema.subscriptions.trigger(:toot_was_tooted, {handle: "matz"}, toot)

      mailbox = res.context[:subscription_mailbox]
      assert_equal ["Boom!"], mailbox.map { |m| m["errors"][0]["message"] }
      assert_equal 0, in_memory_subscription_count
    end

    it "unsubscribes if a `loads:` argument is not found" do
      res = exec_query <<-GRAPHQL
      subscription {
        tootWasTooted(handle: "matz") {
          toot { body }
        }
      }
      GRAPHQL
      assert_equal 1, in_memory_subscription_count
      obj = OpenStruct.new(toot: { body: "I am a C programmer" }, user: SubscriptionFieldSchema::USERS["matz"])
      SubscriptionFieldSchema.subscriptions.trigger(:toot_was_tooted, {handle: "matz"}, obj)

      # Get 1 successful update
      mailbox = res.context[:subscription_mailbox]
      assert_equal 1, mailbox.size
      update_payload = mailbox.first
      assert_equal "I am a C programmer", update_payload["data"]["tootWasTooted"]["toot"]["body"]

      # Then cause a not-found and update again
      matz = SubscriptionFieldSchema::USERS.delete("matz")
      obj = OpenStruct.new(toot: { body: "Merry Christmas, here's a new Ruby version" }, user: matz)
      SubscriptionFieldSchema.subscriptions.trigger(:toot_was_tooted, {handle: "matz"}, obj)
      # there was no subsequent update
      assert_equal 1, mailbox.size
      # The database was cleaned up
      assert_equal 0, in_memory_subscription_count
    end

    it "sends an error if `#authorized?` fails" do
      res = exec_query <<-GRAPHQL
      subscription {
        tootWasTooted(handle: "matz") {
          toot { body }
        }
      }
      GRAPHQL
      assert_equal 1, in_memory_subscription_count
      matz = SubscriptionFieldSchema::USERS["matz"]
      obj = OpenStruct.new(toot: { body: "I am a C programmer" }, user: matz)
      SubscriptionFieldSchema.subscriptions.trigger(:toot_was_tooted, {handle: "matz"}, obj)

      # Get 1 successful update
      mailbox = res.context[:subscription_mailbox]
      assert_equal 1, mailbox.size
      update_payload = mailbox.first
      assert_equal "I am a C programmer", update_payload["data"]["tootWasTooted"]["toot"]["body"]

      # Cause an authorized failure
      matz[:private] = true
      obj = OpenStruct.new(toot: { body: "Merry Christmas, here's a new Ruby version" }, user: matz)
      SubscriptionFieldSchema.subscriptions.trigger(:toot_was_tooted, {handle: "matz"}, obj)
      assert_equal 2, mailbox.size
      assert_equal ["Can't subscribe to private user ([\"tootWasTooted\"])"], mailbox.last["errors"].map { |e| e["message"] }
      # The subscription remains in place
      assert_equal 1, in_memory_subscription_count
    end

    it "support dynamic schema with custom context" do
      res = exec_query <<-GRAPHQL, context: { legacy_schema: true }
      subscription {
        tootWasTooted(handle: "matz") {
          toot {
            likesCount
          }
        }
      }
      GRAPHQL
      assert_equal 1, in_memory_subscription_count
      matz = SubscriptionFieldSchema::USERS["matz"]
      obj = OpenStruct.new(toot: { likes_count: 42 }, user: matz)
      SubscriptionFieldSchema.subscriptions.trigger(:toot_was_tooted, {handle: "matz"}, obj)

      # Get 1 successful update
      mailbox = res.context[:subscription_mailbox]
      assert_equal 1, mailbox.size
      update_payload = mailbox.first
      assert_equal 42, update_payload["data"]["tootWasTooted"]["toot"]["likesCount"]
    end
  end

  describe "applying `loads:`" do
    it "uses the original argument name in the event topic" do
      assert_equal [], SubscriptionFieldSchema::InMemorySubscriptions::EVENT_REGISTRY.keys
      matz = SubscriptionFieldSchema::USERS["matz"]
      obj = OpenStruct.new(toot: { body: "I am a C programmer" }, user: matz)
      SubscriptionFieldSchema.subscriptions.trigger(:toot_was_tooted, {handle: "matz"}, obj)
      assert_equal [":tootWasTooted:handle:matz"], SubscriptionFieldSchema::InMemorySubscriptions::EVENT_REGISTRY.keys
    end
  end

  describe "`subscription_scope` method" do
    it "provides a subscription scope that is recognized in the schema" do
      scoped_subscription = SubscriptionFieldSchema::get_field("Subscription", "directTootWasTooted")

      assert_equal :viewer, scoped_subscription.subscription_scope
    end

    it "requires subscription scope for subscribe and update by default" do
      err = assert_raises GraphQL::Subscriptions::SubscriptionScopeMissingError do
        exec_query <<-GRAPHQL
          subscription {
            directTootWasTooted {
              toot { body }
            }
          }
        GRAPHQL
      end
      expected_message = "Subscription.directTootWasTooted (SubscriptionFieldSchema::DirectTootWasTooted) requires a `scope:` value to trigger updates (Set `subscription_scope ..., optional: true` to disable this requirement)"
      assert_equal expected_message, err.message
      assert_equal 0, in_memory_subscription_count

      exec_query <<-GRAPHQL, context: { viewer: :me }
        subscription {
          directTootWasTooted {
            toot { body }
          }
        }
      GRAPHQL
      assert_equal 1, in_memory_subscription_count

      obj = OpenStruct.new(toot: { body: "Hello from matz!" }, user: SubscriptionFieldSchema::USERS["matz"])
      err = assert_raises GraphQL::Subscriptions::SubscriptionScopeMissingError do
        SubscriptionFieldSchema.subscriptions.trigger(:direct_toot_was_tooted, {}, obj)
      end
      assert_equal expected_message, err.message
    end

    it "doesn't require subscription scope if `optional: true`" do
      res = exec_query <<-GRAPHQL, context: { viewer: :me }
        subscription {
          directTootWasTootedWithOptionalScope {
            toot { body }
          }
        }
      GRAPHQL

      res2 = exec_query <<-GRAPHQL
        subscription {
          directTootWasTootedWithOptionalScope {
            toot { body }
          }
        }
      GRAPHQL

      assert_equal 2, in_memory_subscription_count

      obj = OpenStruct.new(toot: { body: "Hello from matz!" }, user: SubscriptionFieldSchema::USERS["matz"])

      SubscriptionFieldSchema.subscriptions.trigger(:direct_toot_was_tooted_with_optional_scope, {}, obj)
      assert_equal 0, res.context[:subscription_mailbox].length
      assert_equal 1, res2.context[:subscription_mailbox].length

      SubscriptionFieldSchema.subscriptions.trigger(:direct_toot_was_tooted_with_optional_scope, {}, obj, scope: :me)
      assert_equal 1, res.context[:subscription_mailbox].length
      assert_equal 1, res2.context[:subscription_mailbox].length
    end

    it "provides a subscription scope that is used in execution" do
      res = exec_query <<-GRAPHQL, context: { viewer: :me }
        subscription {
          directTootWasTooted {
            toot { body }
          }
        }
      GRAPHQL
      assert_equal 1, in_memory_subscription_count

      # Only the subscription with scope :me should be in the mailbox
      obj = OpenStruct.new(toot: { body: "Hello from matz!" }, user: SubscriptionFieldSchema::USERS["matz"])
      SubscriptionFieldSchema.subscriptions.trigger(:direct_toot_was_tooted, {}, obj, scope: :me)
      SubscriptionFieldSchema.subscriptions.trigger(:direct_toot_was_tooted, {}, obj, scope: :not_me)
      mailbox = res.context[:subscription_mailbox]

      assert_equal 1, mailbox.length

      expected_response = {
        "data" => {
          "directTootWasTooted" => {
            "toot" => {
              "body" => "Hello from matz!"
            }
          }
        }
      }

      assert_equal expected_response, mailbox.first
    end

    it "allows for proper inheritance of the class's configuration in subclasses" do
      # Make a subclass without an explicit configuration
      class DirectTootSubclass < SubscriptionFieldSchema::DirectTootWasTooted
      end
      # Then check if the field options got the inherited value
      field = GraphQL::Schema::Field.new(name: "blah", resolver_class: DirectTootSubclass)
      assert_equal :viewer, field.subscription_scope
    end

    it "allows for setting the subscription scope value to nil" do
      class PrivateSubscription < SubscriptionFieldSchema::BaseSubscription
        subscription_scope :private
      end

      PrivateSubscription.subscription_scope nil

      assert_nil PrivateSubscription.subscription_scope
    end
  end

  describe "writing during resolution" do
    class DirectWriteSchema < GraphQL::Schema
      class WriteCheckSubscriptions
        def use(schema)
          schema.subscriptions = self
        end

        def write_subscription(query, events)
          query.context[:write_subscription_count] ||= 0
          query.context[:write_subscription_count] += 1
          evs = query.context[:written_events] ||= []
          evs << events
          nil
        end
      end
      class ImplicitWrite < GraphQL::Schema::Subscription
        type String

        def subscribe
          "#{context[:written_events]&.size.inspect} / #{context[:write_subscription_count].inspect} / #{subscription_written?}"
        end
      end

      class DirectWrite < ImplicitWrite
        type String
        def subscribe
          write_subscription
          super
        end
      end

      class DirectWriteTwice < DirectWrite
        type String
        def subscribe
          write_subscription
          super
        end
      end

      class Subscription < GraphQL::Schema::Object
        field :direct, subscription: DirectWrite
        field :implicit, subscription: ImplicitWrite
        field :direct_twice, subscription: DirectWriteTwice
      end

      use WriteCheckSubscriptions.new
      subscription(Subscription)
    end

    it "only calls write_subscription once" do
      res = DirectWriteSchema.execute("subscription { direct }")
      assert_equal "1 / 1 / true", res["data"]["direct"]
      assert_equal 1, res.context[:write_subscription_count]
      assert_equal [1], res.context[:written_events].map(&:size)
      assert_equal true, res.context.namespace(:subscriptions)[:subscriptions].values.first.subscription_written?

      res = DirectWriteSchema.execute("subscription { implicit }")
      assert_equal "nil / nil / false", res["data"]["implicit"]
      assert_equal 1, res.context[:write_subscription_count]
      assert_equal [1], res.context[:written_events].map(&:size)
      assert_equal false, res.context.namespace(:subscriptions)[:subscriptions].values.first.subscription_written?
    end

    it "raises if write_subscription is called twice" do
      err = assert_raises GraphQL::Error do
        DirectWriteSchema.execute("subscription { directTwice }")
      end
      assert_equal "`write_subscription` was called but `DirectWriteSchema::DirectWriteTwice#subscription_written?` is already true. Remove a call to `write subscription`.", err.message
    end
  end
end
