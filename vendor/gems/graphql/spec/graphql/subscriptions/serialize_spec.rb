# frozen_string_literal: true
require "spec_helper"

describe GraphQL::Subscriptions::Serialize do
  def serialize_dump(v)
    GraphQL::Subscriptions::Serialize.dump(v)
  end

  def serialize_load(v)
    GraphQL::Subscriptions::Serialize.load(v)
  end

  if defined?(GlobalID)
    it "should serialize GlobalID::Identification in Array/Hash" do
      user_a = GlobalIDUser.new("a")
      user_b = GlobalIDUser.new("b")

      str_a = serialize_dump(["first", 2, user_a])
      str_b = serialize_dump({"first" => 'first', "second" => 2, "user" => user_b})

      assert_equal str_a, '["first",2,{"__gid__":"Z2lkOi8vZ3JhcGhxbC1ydWJ5LXRlc3QvR2xvYmFsSURVc2VyL2E"}]'
      assert_equal str_b, '{"first":"first","second":2,"user":{"__gid__":"Z2lkOi8vZ3JhcGhxbC1ydWJ5LXRlc3QvR2xvYmFsSURVc2VyL2I"}}'
    end

    it "should deserialize GlobalID::Identification in Array/Hash" do
      user_a = GlobalIDUser.new("a")
      user_b = GlobalIDUser.new("b")

      str_a = '["first",2,{"__gid__":"Z2lkOi8vZ3JhcGhxbC1ydWJ5LXRlc3QvR2xvYmFsSURVc2VyL2E"}]'
      str_b = '{"first":"first","second":2,"user":{"__gid__":"Z2lkOi8vZ3JhcGhxbC1ydWJ5LXRlc3QvR2xvYmFsSURVc2VyL2I"}}'

      parsed_obj_a = serialize_load(str_a)
      parsed_obj_b = serialize_load(str_b)

      assert_equal parsed_obj_a, ["first", 2, user_a]
      assert_equal parsed_obj_b, {'first' => 'first', 'second' => 2, 'user' => user_b}
    end

    it "uses locate_many for arrays of global ids" do
      user_a = GlobalIDUser.new("a")
      user_b = GlobalIDUser.new("b")
      str = serialize_dump({ "users" => [user_a, user_b] })

      loaded = serialize_load(str)
      assert_equal [user_a, user_b], loaded["users"]
      # It went through the plural load codepath:
      assert_equal false, user_a.located_many?
      assert_equal [true, true], loaded["users"].map(&:located_many?)
    end
  end

  it "can deserialize symbols" do
    value = { a: :a, "b" => 2 }

    dumped = serialize_dump(value)
    expected_dumped = '{"a":{"__sym__":"a"},"b":2,"__sym_keys__":["a"]}'
    assert_equal expected_dumped, dumped
    loaded = serialize_load(dumped)
    assert_equal value, loaded
  end

  it "can deserialize date/times" do
    datetime = DateTime.parse("2020-01-03 10:11:12")
    time = Time.new
    date = Date.today
    [datetime, time, date].each do |timestamp|
      serialized = serialize_dump(timestamp)
      reloaded = serialize_load(serialized)
      assert_equal timestamp, reloaded, "#{timestamp.inspect} is serialized to #{serialized.inspect} and reloaded"
    end
  end

  if defined?(ActiveSupport::TimeWithZone) && defined?(Rails) && Rails.version.split(".").first.to_i >= 7
    it "can deserialize ActiveSupport::TimeWithZone into the right zone" do
      klass = Class.new(ActiveSupport::TimeWithZone) do
        # Forcing the name here for simulating the case where
        # config.active_support.remove_deprecated_time_with_zone_name = true
        # in a Rails 7+ installation
        def self.name
          "ActiveSupport::TimeWithZone"
        end
      end

      time_utc = klass.new(Time.at(1), ActiveSupport::TimeZone["UTC"])
      time_est = klass.new(Time.at(1), ActiveSupport::TimeZone["EST"])

      serialized_utc = serialize_dump(time_utc)
      reloaded_utc = serialize_load(serialized_utc)

      serialized_est = serialize_dump(time_est)
      reloaded_est = serialize_load(serialized_est)

      assert_equal time_utc, reloaded_utc, "#{time_utc.inspect} is serialized to #{serialized_utc.inspect} and reloaded"
      assert_equal time_est, reloaded_est, "#{time_est.inspect} is serialized to #{serialized_est.inspect} and reloaded"

      assert_equal "UTC", time_utc.time_zone.name, "#{time_utc.inspect} is parsed within the UTC time zone"
      assert_equal "EST", time_est.time_zone.name, "#{time_est.inspect} is parsed within the EST time zone"
    end
  end

  if testing_rails?
    describe "ActiveRecord::Relations" do
      before do
        Food.destroy_all
        Food.create!(name: "Peanut Butter")
        Food.create!(name: "Jelly")
      end

      after do
        Food.destroy_all
      end

      it "turns them into Arrays and can reload them with GlobalID" do
        assert_equal 2, Food.count
        serialized = serialize_dump(Food.all)
        reloaded = serialize_load(serialized)
        assert_equal reloaded, Food.all.to_a
      end
    end
  end

  it "can deserialize openstructs" do
    os = OpenStruct.new(a: 1.2, b: :c, d: Time.new, e: OpenStruct.new(f: [1, 2, 3]))
    serialized = serialize_dump(os)
    reloaded = serialize_load(serialized)
    assert_equal os, reloaded, "It reloads #{os.inspect} from #{serialized.inspect}"
  end

  it "can deserialize single key hash" do
    os = { 'a' => 1 }
    serialized = os.to_json
    reloaded = serialize_load(serialized)
    assert_equal os, reloaded
  end
end
