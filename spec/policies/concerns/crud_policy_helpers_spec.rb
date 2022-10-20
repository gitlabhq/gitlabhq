# frozen_string_literal: true

require 'spec_helper'

RSpec.describe CrudPolicyHelpers do
  let(:policy_test_class) do
    Class.new do
      include CrudPolicyHelpers
    end
  end

  let(:feature_name) { :foo }

  before do
    stub_const('PolicyTestClass', policy_test_class)
  end

  describe '.create_read_update_admin_destroy' do
    it 'returns an array of the appropriate abilites given a feature name' do
      expect(PolicyTestClass.create_read_update_admin_destroy(feature_name)).to eq(
        [
          :read_foo,
          :create_foo,
          :update_foo,
          :admin_foo,
          :destroy_foo
        ])
    end
  end

  describe '.create_update_admin_destroy' do
    it 'returns an array of the appropriate abilites given a feature name' do
      expect(PolicyTestClass.create_update_admin_destroy(feature_name)).to eq(
        [
          :create_foo,
          :update_foo,
          :admin_foo,
          :destroy_foo
        ])
    end
  end

  describe '.create_update_admin' do
    it 'returns an array of the appropriate abilites given a feature name' do
      expect(PolicyTestClass.create_update_admin(feature_name)).to eq(
        [
          :create_foo,
          :update_foo,
          :admin_foo
        ])
    end
  end
end
