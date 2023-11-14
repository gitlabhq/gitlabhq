# frozen_string_literal: true

require 'spec_helper'

RSpec.describe PolicyActor, feature_category: :shared do
  let(:policy_actor_test_class) do
    Class.new do
      include PolicyActor
    end
  end

  before do
    stub_const('PolicyActorTestClass', policy_actor_test_class)
  end

  it 'implements all the methods from user' do
    methods = subject.instance_methods

    # User.instance_methods do not return all methods until an instance is
    # initialized. So here we just use an instance
    expect(build(:user).methods).to include(*methods)
  end
end
