# frozen_string_literal: true

require 'spec_helper'

RSpec.describe DeleteUserWorker do
  let!(:user)         { create(:user) }
  let!(:current_user) { create(:user) }

  it "calls the DeleteUserWorker with the params it was given" do
    expect_next_instance_of(Users::DestroyService) do |service|
      expect(service).to receive(:execute).with(user, {})
    end

    described_class.new.perform(current_user.id, user.id)
  end

  it "uses symbolized keys" do
    expect_next_instance_of(Users::DestroyService) do |service|
      expect(service).to receive(:execute).with(user, test: "test")
    end

    described_class.new.perform(current_user.id, user.id, "test" => "test")
  end
end
