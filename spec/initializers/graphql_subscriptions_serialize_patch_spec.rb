# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'GraphQL subscriptions serialize patch', feature_category: :api do
  let(:serialize) { GraphQL::Subscriptions::Serialize }

  def round_trip(object)
    serialize.load(serialize.dump(object))
  end

  describe 'graphql version guard' do
    it 'raises if a version other than 2.6.10 is detected' do
      stub_const('GraphQL::VERSION', '2.6.11')

      expect do
        load Rails.root.join('config/initializers/graphql_subscriptions_serialize_patch.rb')
      end.to raise_error(RuntimeError, /pinned to graphql 2\.6\.10/)
    end
  end

  # Behaviour of the gem itself since graphql 2.6.8 (upstream commit 44dfd056), not of
  # this patch. Kept as regression coverage because the allowlist is load bearing here.
  describe 'timestamp deserialization' do
    it 'refuses to resolve a class name outside the allowlist' do
      payload = Gitlab::Json.generate({ '__timestamp__' => %w[Kernel 2020-01-01] })

      expect { serialize.load(payload) }
        .to raise_error(ArgumentError, /Unsupported timestamp class/)
    end

    it 'does not resolve the disallowed class name as a constant', :aggregate_failures do
      payload = Gitlab::Json.generate({ '__timestamp__' => %w[Kernel 2020-01-01] })

      expect(Object).not_to receive(:const_get).with('Kernel', any_args)

      expect { serialize.load(payload) }.to raise_error(ArgumentError)
    end

    it 'still round trips supported timestamp classes', :aggregate_failures do
      date = Date.new(2020, 1, 3)
      time = Time.current

      expect(round_trip(date)).to eq(date)
      expect(round_trip(time)).to be_within(1.second).of(time)
    end
  end

  # https://github.com/rmosolgo/graphql-ruby/commit/a55c33b58c88d798b62f1096dbbb50d1791a194e
  describe 'reserved serializer keys in user data' do
    it 'does not treat a user-supplied __gid__ key as a global id', :aggregate_failures do
      input = { '__gid__' => 'gid://gitlab/User/1' }

      expect(GlobalID::Locator).not_to receive(:locate)
      expect(round_trip(input)).to eq(input)
    end

    it 'round trips every reserved key nested in user data', :aggregate_failures do
      {
        '__gid__' => 'gid://gitlab/User/1',
        '__sym__' => 'user-value',
        '__sym_keys__' => ['user-value'],
        '__timestamp__' => %w[UserClass user-value],
        '__ostruct__' => { 'user-value' => true },
        '__graphql_hash__' => [['user-value']]
      }.each do |key, value|
        input = { 'nested' => [{ key => value }] }

        expect(round_trip(input)).to eq(input), "expected #{key} to round trip"
      end
    end

    it 'round trips a reserved key alongside other keys' do
      input = { '__sym_keys__' => ['user-value'], 'user-value' => true }

      expect(round_trip(input)).to eq(input)
    end

    it 'round trips a symbol reserved key' do
      input = { __gid__: 'gid://gitlab/User/1' }

      expect(round_trip(input)).to eq(input)
    end
  end

  # https://github.com/rmosolgo/graphql-ruby/commit/369383a19953c6d99aa502225df402743b9f3ffc
  describe 'round trip preservation' do
    it 'preserves symbol and string keys with the same name' do
      input = { a: 1, 'a' => 2 }

      expect(round_trip(input)).to eq(input)
    end

    it 'deserializes arrays mixing global ids with other values' do
      user = create(:user)

      expect(round_trip([user, 1, 'two'])).to eq([user, 1, 'two'])
    end

    it 'still deserializes arrays of only global ids' do
      users = create_list(:user, 2)

      expect(round_trip(users)).to eq(users)
    end
  end

  describe 'ordinary payloads' do
    it 'round trips symbols and nested structures', :aggregate_failures do
      expect(round_trip(:foo)).to eq(:foo)
      expect(round_trip({ a: 1, b: { c: :d } })).to eq({ a: 1, b: { c: :d } })
      expect(round_trip({ 'x' => [1, 'two', nil, true] })).to eq({ 'x' => [1, 'two', nil, true] })
      expect(round_trip({ 'k' => 'v' })).to eq({ 'k' => 'v' })
    end

    it 'round trips an open struct' do
      expect(round_trip(OpenStruct.new(a: 1))).to eq(OpenStruct.new(a: 1)) # rubocop:disable Style/OpenStructUse -- Exercises the gem's OpenStruct branch
    end

    it 'round trips an open struct holding a reserved key', :aggregate_failures do
      # Reaches the gem's OpenStruct branch through `super`, which recurses back
      # into the patched hash escaping.
      input = OpenStruct.new('__gid__' => 'gid://gitlab/User/1') # rubocop:disable Style/OpenStructUse -- Exercises the gem's OpenStruct branch

      expect(GlobalID::Locator).not_to receive(:locate)
      expect(round_trip(input)).to eq(input)
    end
  end

  # These guard the patch mechanism itself: dropping `private`, or prepending onto
  # the module instead of its singleton class, would otherwise fail silently.
  describe 'patch wiring' do
    it 'is prepended onto the singleton class' do
      expect(serialize.singleton_class.ancestors)
        .to include(Gitlab::Patch::GraphqlSubscriptionsSerialize)
    end

    it 'keeps the patched methods private', :aggregate_failures do
      expect { serialize.dump_value(1) }.to raise_error(NoMethodError)
      expect { serialize.load_value(1) }.to raise_error(NoMethodError)
    end
  end
end
