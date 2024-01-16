# frozen_string_literal: true

RSpec::Matchers.define :have_user do |user|
  match do |resource|
    raise ArgumentError, 'Unknown resource type' unless resource.is_a?(Group) || resource.is_a?(Project)

    expect(resource.has_user?(user)).to be_truthy
  end

  failure_message do |group|
    "Expected #{group} to have the user #{user} among its members"
  end
end
