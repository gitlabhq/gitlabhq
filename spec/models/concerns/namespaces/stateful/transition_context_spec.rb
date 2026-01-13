# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Namespaces::Stateful::TransitionContext, feature_category: :groups_and_projects do
  let_it_be(:user) { create(:user) }
  let_it_be_with_reload(:namespace) { create(:namespace) }

  describe '#transition_args' do
    it 'extracts args from transition' do
      transition = Struct.new(:args).new([{ transition_user: user }])

      result = namespace.send(:transition_args, transition)

      expect(result).to eq({ transition_user: user })
    end

    it 'returns empty hash when args is nil' do
      transition = Struct.new(:args).new([nil])

      result = namespace.send(:transition_args, transition)

      expect(result).to eq({})
    end

    it 'returns empty hash when args array is empty' do
      transition = Struct.new(:args).new([])

      result = namespace.send(:transition_args, transition)

      expect(result).to eq({})
    end
  end

  describe '#transition_user' do
    it 'extracts transition_user from transition args' do
      transition = Struct.new(:args).new([{ transition_user: user }])

      result = namespace.send(:transition_user, transition)

      expect(result).to eq(user)
    end

    it 'returns nil when transition_user is not provided' do
      transition = Struct.new(:args).new([{}])

      result = namespace.send(:transition_user, transition)

      expect(result).to be_nil
    end

    it 'returns nil when args is empty' do
      transition = Struct.new(:args).new([])

      result = namespace.send(:transition_user, transition)

      expect(result).to be_nil
    end
  end
end
