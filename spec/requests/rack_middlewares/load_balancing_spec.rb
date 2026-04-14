# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Load Balancer Rack middleware',
  :clean_gitlab_redis_db_load_balancing, lsn_tagging: User,
  feature_category: :database do
  let(:user) { create(:user, :with_namespace) }

  it 'loads the user after the sticking check' do
    Warden.on_next_request do |proxy|
      # Can't just be sign_in(user) - that fakes the user object into the session rather than storing their id
      proxy.session_serializer.store(user, :user)
    end
    desired_lsn = 'FFFFFFFF/FFFFFFFF'
    ApplicationRecord.sticking.send(:set_write_location_for, :user, user.id, desired_lsn)

    expect_next_instance_of(UsersController) do |controller|
      expect(controller).to receive(:show).and_wrap_original do |m, *args|
        expect(controller.current_user).to guarantee_lsn(desired_lsn)
        m.call(*args)
      end
    end
    get user_path(user)
    expect(response).to be_successful
  end
end
