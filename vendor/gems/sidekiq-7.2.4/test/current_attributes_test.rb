# frozen_string_literal: true

require_relative "helper"
require "sidekiq/middleware/current_attributes"
require "sidekiq/fetch"

module Myapp
  class Current < ActiveSupport::CurrentAttributes
    attribute :user_id
  end

  class OtherCurrent < ActiveSupport::CurrentAttributes
    attribute :other_id
  end
end

describe "Current attributes" do
  before do
    @config = reset!
  end

  it "saves" do
    cm = Sidekiq::CurrentAttributes::Save.new({
      "cattr" => "Myapp::Current",
      "cattr_1" => "Myapp::OtherCurrent"
    })
    job = {}
    with_context("Myapp::Current", :user_id, 123) do
      with_context("Myapp::OtherCurrent", :other_id, 789) do
        cm.call(nil, job, nil, nil) do
          assert_equal 123, job["cattr"][:user_id]
          assert_equal 789, job["cattr_1"][:other_id]
        end
      end
    end

    with_context("Myapp::Current", :user_id, 456) do
      with_context("Myapp::OtherCurrent", :other_id, 999) do
        cm.call(nil, job, nil, nil) do
          assert_equal 123, job["cattr"][:user_id]
          assert_equal 789, job["cattr_1"][:other_id]
        end
      end
    end
  end

  it "loads" do
    cm = Sidekiq::CurrentAttributes::Load.new({
      "cattr" => "Myapp::Current",
      "cattr_1" => "Myapp::OtherCurrent"
    })

    job = {"cattr" => {"user_id" => 123}, "cattr_1" => {"other_id" => 456}}
    assert_nil Myapp::Current.user_id
    assert_nil Myapp::OtherCurrent.other_id
    cm.call(nil, job, nil) do
      assert_equal 123, Myapp::Current.user_id
      assert_equal 456, Myapp::OtherCurrent.other_id
    end
    # the Rails reloader is responsible for resetting Current after every unit of work
  end

  it "persists with class argument" do
    Sidekiq::CurrentAttributes.persist("Myapp::Current", @config)
    job_hash = {}
    with_context("Myapp::Current", :user_id, 16) do
      @config.client_middleware.invoke(nil, job_hash, nil, nil) do
        assert_equal 16, job_hash["cattr"][:user_id]
      end
    end

    #   assert_nil Myapp::Current.user_id
    #   Sidekiq.server_middleware.invoke(nil, job_hash, nil) do
    #     assert_equal 16, job_hash["cattr"][:user_id]
    #     assert_equal 16, Myapp::Current.user_id
    #   end
    #   assert_nil Myapp::Current.user_id
    # ensure
    #   Sidekiq.client_middleware.clear
    #   Sidekiq.server_middleware.clear
  end

  it "persists with hash argument" do
    cattrs = [Myapp::Current, "Myapp::OtherCurrent"]
    Sidekiq::CurrentAttributes.persist(cattrs, @config)
    job_hash = {}
    with_context("Myapp::Current", :user_id, 16) do
      with_context("Myapp::OtherCurrent", :other_id, 17) do
        @config.client_middleware.invoke(nil, job_hash, nil, nil) do
          assert_equal 16, job_hash["cattr"][:user_id]
          assert_equal 17, job_hash["cattr_1"][:other_id]
        end
      end
    end
  end

  private

  def with_context(strklass, attr, value)
    constklass = strklass.constantize
    constklass.send(:"#{attr}=", value)
    yield
  ensure
    constklass.reset_all
  end
end
