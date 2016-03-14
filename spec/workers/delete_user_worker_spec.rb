require 'spec_helper'

describe DeleteUserWorker do
  let!(:user)         { create(:user) }
  let!(:current_user) { create(:user) }

  it "calls the DeleteUserWorker with the params it was given" do
    expect_any_instance_of(DeleteUserService).to receive(:execute).
                                                      with(user, {})

    DeleteUserWorker.new.perform(current_user.id, user.id)
  end

  it "uses symbolized keys" do
    expect_any_instance_of(DeleteUserService).to receive(:execute).
                                                      with(user, test: "test")

    DeleteUserWorker.new.perform(current_user.id, user.id, "test" => "test")
  end
end
