# frozen_string_literal: true

require_relative "helper"
require "sidekiq/api"

describe "DeadSet" do
  def dead_set
    Sidekiq::DeadSet.new
  end

  it 'should put passed serialized job to the "dead" sorted set' do
    serialized_job = Sidekiq.dump_json(jid: "123123", class: "SomeJob", args: [])
    dead_set.kill(serialized_job)

    assert_equal dead_set.find_job("123123").value, serialized_job
  end

  it "should remove dead jobs older than Sidekiq::DeadSet.timeout" do
    old, Sidekiq::Config::DEFAULTS[:dead_timeout_in_seconds] = Sidekiq::Config::DEFAULTS[:dead_timeout_in_seconds], 10
    Time.stub(:now, Time.now - 11) do
      dead_set.kill(Sidekiq.dump_json(jid: "000103", class: "MyJob3", args: [])) # the oldest
    end
    Time.stub(:now, Time.now - 9) do
      dead_set.kill(Sidekiq.dump_json(jid: "000102", class: "MyJob2", args: []))
    end
    dead_set.kill(Sidekiq.dump_json(jid: "000101", class: "MyJob1", args: []))

    assert_nil dead_set.find_job("000103")
    assert dead_set.find_job("000102")
    assert dead_set.find_job("000101")
  ensure
    Sidekiq::Config::DEFAULTS[:dead_timeout_in_seconds] = old
  end

  it "should remove all but last Sidekiq::DeadSet.max_jobs-1 jobs" do
    old, Sidekiq::Config::DEFAULTS[:dead_max_jobs] = Sidekiq::Config::DEFAULTS[:dead_max_jobs], 3
    dead_set.kill(Sidekiq.dump_json(jid: "000101", class: "MyJob1", args: []))
    dead_set.kill(Sidekiq.dump_json(jid: "000102", class: "MyJob2", args: []))
    dead_set.kill(Sidekiq.dump_json(jid: "000103", class: "MyJob3", args: []))

    assert_nil dead_set.find_job("000101")
    assert dead_set.find_job("000102")
    assert dead_set.find_job("000103")
  ensure
    Sidekiq::Config::DEFAULTS[:dead_max_jobs] = old
  end
end
