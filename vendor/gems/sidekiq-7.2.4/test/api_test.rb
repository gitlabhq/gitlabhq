# frozen_string_literal: true

require_relative "helper"
require "sidekiq/api"
require "active_job"
require "action_mailer"

class ApiMailer < ActionMailer::Base
  def test_email(*)
  end
end

class ApiAjJob < ActiveJob::Base
  def perform(*)
  end
end

class ApiJob
  include Sidekiq::Job
end

class JobWithTags
  include Sidekiq::Job
  sidekiq_options tags: ["foo"]
end

SERIALIZED_JOBS = {
  "5.x" => [
    '{"class":"ActiveJob::QueueAdapters::SidekiqAdapter::JobWrapper","wrapped":"ApiAjJob","queue":"default","args":[{"job_class":"ApiAjJob","job_id":"f1bde53f-3852-4ae4-a879-c12eacebbbb0","provider_job_id":null,"queue_name":"default","priority":null,"arguments":[1,2,3],"executions":0,"locale":"en"}],"retry":true,"jid":"099eee72911085a511d0e312","created_at":1568305542.339916,"enqueued_at":1568305542.339947}',
    '{"class":"ActiveJob::QueueAdapters::SidekiqAdapter::JobWrapper","wrapped":"ActionMailer::DeliveryJob","queue":"mailers","args":[{"job_class":"ActionMailer::DeliveryJob","job_id":"19cc0115-3d1c-4bbe-a51e-bfa1385895d1","provider_job_id":null,"queue_name":"mailers","priority":null,"arguments":["ApiMailer","test_email","deliver_now",1,2,3],"executions":0,"locale":"en"}],"retry":true,"jid":"37436e5504936400e8cf98db","created_at":1568305542.370133,"enqueued_at":1568305542.370241}'
  ],
  "6.x" => [
    '{"class":"ActiveJob::QueueAdapters::SidekiqAdapter::JobWrapper","wrapped":"ApiAjJob","queue":"default","args":[{"job_class":"ApiAjJob","job_id":"ff2b48d4-bdce-4825-af6b-ef8c11ab651e","provider_job_id":null,"queue_name":"default","priority":null,"arguments":[1,2,3],"executions":0,"exception_executions":{},"locale":"en","timezone":"UTC","enqueued_at":"2019-09-12T16:28:37Z"}],"retry":true,"jid":"ce121bf77b37ae81fe61b6dc","created_at":1568305717.9469702,"enqueued_at":1568305717.947005}',
    '{"class":"ActiveJob::QueueAdapters::SidekiqAdapter::JobWrapper","wrapped":"ActionMailer::MailDeliveryJob","queue":"mailers","args":[{"job_class":"ActionMailer::MailDeliveryJob","job_id":"2f967da1-a389-479c-9a4e-5cc059e6d65c","provider_job_id":null,"queue_name":"mailers","priority":null,"arguments":["ApiMailer","test_email","deliver_now",{"params":{"user":{"_aj_globalid":"gid://app/User/1"}, "_aj_symbol_keys":["user"]},"args":[1,2,3],"_aj_symbol_keys":["params", "args"]}],"executions":0,"exception_executions":{},"locale":"en","timezone":"UTC","enqueued_at":"2019-09-12T16:28:37Z"}],"retry":true,"jid":"469979df52bb9ef9f48b49e1","created_at":1568305717.9457421,"enqueued_at":1568305717.9457731}'
  ]
}

describe "API" do
  before do
    @cfg = reset!
  end

  describe "stats" do
    it "is initially zero" do
      s = Sidekiq::Stats.new
      assert_equal 0, s.processed
      assert_equal 0, s.failed
      assert_equal 0, s.enqueued
      assert_equal 0, s.default_queue_latency
      assert_equal 0, s.workers_size
    end

    describe "processed" do
      it "returns number of processed jobs" do
        @cfg.redis { |conn| conn.set("stat:processed", 5) }
        s = Sidekiq::Stats.new
        assert_equal 5, s.processed
      end
    end

    describe "failed" do
      it "returns number of failed jobs" do
        @cfg.redis { |conn| conn.set("stat:failed", 5) }
        s = Sidekiq::Stats.new
        assert_equal 5, s.failed
      end
    end

    describe "reset" do
      before do
        @cfg.redis do |conn|
          conn.set("stat:processed", 5)
          conn.set("stat:failed", 10)
        end
      end

      it "will reset all stats by default" do
        Sidekiq::Stats.new.reset
        s = Sidekiq::Stats.new
        assert_equal 0, s.failed
        assert_equal 0, s.processed
      end

      it "can reset individual stats" do
        Sidekiq::Stats.new.reset("failed")
        s = Sidekiq::Stats.new
        assert_equal 0, s.failed
        assert_equal 5, s.processed
      end

      it "can accept anything that responds to #to_s" do
        Sidekiq::Stats.new.reset(:failed)
        s = Sidekiq::Stats.new
        assert_equal 0, s.failed
        assert_equal 5, s.processed
      end

      it 'ignores anything other than "failed" or "processed"' do
        Sidekiq::Stats.new.reset((1..10).to_a, ["failed"])
        s = Sidekiq::Stats.new
        assert_equal 0, s.failed
        assert_equal 5, s.processed
      end
    end

    describe "workers_size" do
      it "retrieves the number of busy workers" do
        @cfg.redis do |c|
          c.sadd("processes", ["process_1", "process_2"])
          c.hset("process_1", "busy", 1)
          c.hset("process_2", "busy", 2)
        end
        s = Sidekiq::Stats.new
        assert_equal 3, s.workers_size
      end
    end

    describe "queues" do
      it "is initially empty" do
        s = Sidekiq::Stats.new
        assert_equal 0, s.queues.size
      end

      it "returns a hash of queue and size in order" do
        @cfg.redis do |conn|
          conn.rpush "queue:foo", "{}"
          conn.sadd "queues", ["foo"]

          3.times { conn.rpush "queue:bar", "{}" }
          conn.sadd "queues", ["bar"]
        end

        assert_equal({"foo" => 1, "bar" => 3}, Sidekiq::Stats.new.queues)
      end
    end

    describe "enqueued" do
      it "handles latency for good jobs" do
        @cfg.redis do |conn|
          conn.rpush "queue:default", "{\"enqueued_at\": #{Time.now.to_f}}"
          conn.sadd "queues", ["default"]
        end
        s = Sidekiq::Stats.new
        assert s.default_queue_latency > 0
        q = Sidekiq::Queue.new
        assert q.latency > 0
      end

      it "handles latency for incomplete jobs" do
        @cfg.redis do |conn|
          conn.rpush "queue:default", "{}"
          conn.sadd "queues", ["default"]
        end
        s = Sidekiq::Stats.new
        assert_equal 0, s.default_queue_latency
        q = Sidekiq::Queue.new
        assert_equal 0, q.latency
      end

      it "returns total enqueued jobs" do
        @cfg.redis do |conn|
          conn.rpush "queue:foo", "{}"
          conn.sadd "queues", ["foo"]

          3.times { conn.rpush "queue:bar", "{}" }
          conn.sadd "queues", ["bar"]
        end

        s = Sidekiq::Stats.new
        assert_equal 4, s.enqueued
      end
    end

    describe "over time" do
      before do
        require "active_support/core_ext/time/conversions"
        @before = Time::DATE_FORMATS[:default]
        Time::DATE_FORMATS[:default] = "%d/%m/%Y %H:%M:%S"
      end

      after do
        Time::DATE_FORMATS[:default] = @before
      end

      describe "history" do
        it "does not allow invalid input" do
          assert_raises(ArgumentError) { Sidekiq::Stats::History.new(-1) }
          assert_raises(ArgumentError) { Sidekiq::Stats::History.new(0) }
          assert_raises(ArgumentError) { Sidekiq::Stats::History.new(2000) }
          assert Sidekiq::Stats::History.new(200)
        end
      end

      describe "processed" do
        it "retrieves hash of dates" do
          @cfg.redis do |c|
            c.incrby("stat:processed:2012-12-24", 4)
            c.incrby("stat:processed:2012-12-25", 1)
            c.incrby("stat:processed:2012-12-26", 6)
            c.incrby("stat:processed:2012-12-27", 2)
          end
          Time.stub(:now, Time.parse("2012-12-26 1:00:00 -0500")) do
            s = Sidekiq::Stats::History.new(2)
            assert_equal({"2012-12-26" => 6, "2012-12-25" => 1}, s.processed)

            s = Sidekiq::Stats::History.new(3)
            assert_equal({"2012-12-26" => 6, "2012-12-25" => 1, "2012-12-24" => 4}, s.processed)

            s = Sidekiq::Stats::History.new(2, Date.parse("2012-12-25"))
            assert_equal({"2012-12-25" => 1, "2012-12-24" => 4}, s.processed)
          end
        end
      end

      describe "failed" do
        it "retrieves hash of dates" do
          @cfg.redis do |c|
            c.incrby("stat:failed:2012-12-24", 4)
            c.incrby("stat:failed:2012-12-25", 1)
            c.incrby("stat:failed:2012-12-26", 6)
            c.incrby("stat:failed:2012-12-27", 2)
          end
          Time.stub(:now, Time.parse("2012-12-26 1:00:00 -0500")) do
            s = Sidekiq::Stats::History.new(2)
            assert_equal ({"2012-12-26" => 6, "2012-12-25" => 1}), s.failed

            s = Sidekiq::Stats::History.new(3)
            assert_equal ({"2012-12-26" => 6, "2012-12-25" => 1, "2012-12-24" => 4}), s.failed

            s = Sidekiq::Stats::History.new(2, Date.parse("2012-12-25"))
            assert_equal ({"2012-12-25" => 1, "2012-12-24" => 4}), s.failed
          end
        end
      end
    end
  end

  describe "with an empty database" do
    it "shows queue as empty" do
      q = Sidekiq::Queue.new
      assert_equal 0, q.size
      assert_equal 0, q.latency
    end

    before do
      ActiveJob::Base.queue_adapter = :sidekiq
      ActiveJob::Base.logger = nil
    end

    it "can enumerate jobs" do
      q = Sidekiq::Queue.new
      Time.stub(:now, Time.new(2012, 12, 26)) do
        ApiJob.perform_async(1, "mike")
        assert_equal [ApiJob.name], q.map(&:klass)

        job = q.first
        assert_equal 24, job.jid.size
        assert_equal [1, "mike"], job.args
        assert_equal Time.new(2012, 12, 26), job.enqueued_at
      end
      assert q.latency > 10_000_000

      q = Sidekiq::Queue.new("other")
      assert_equal 0, q.size
    end

    it "enumerates jobs in descending score order" do
      # We need to enqueue more than 50 items, which is the page size when retrieving
      # from Redis to ensure everything is sorted: the pages and the items within them.
      51.times { ApiJob.perform_in(100, 1, "foo") }

      set = Sidekiq::ScheduledSet.new.to_a

      assert_equal set.sort_by { |job| -job.score }, set
    end

    it "has no enqueued_at time for jobs enqueued in the future" do
      job_id = ApiJob.perform_in(100, 1, "foo")
      job = Sidekiq::ScheduledSet.new.find_job(job_id)
      assert_nil job.enqueued_at
    end

    describe "Rails unwrapping" do
      SERIALIZED_JOBS.each_pair do |ver, jobs|
        it "unwraps ActiveJob #{ver} jobs" do
          # ApiAjJob.perform_later(1,2,3)
          # puts Sidekiq::Queue.new.first.value
          x = Sidekiq::JobRecord.new(jobs[0], "default")
          assert_equal ApiAjJob.name, x.display_class
          assert_equal [1, 2, 3], x.display_args
        end

        it "unwraps ActionMailer #{ver} jobs" do
          # ApiMailer.test_email(1,2,3).deliver_later
          # puts Sidekiq::Queue.new("mailers").first.value
          x = Sidekiq::JobRecord.new(jobs[1], "mailers")

          expected_args_by_version = {
            "5.x" => [1, 2, 3],
            "6.x" => [{"user" => "gid://app/User/1"}, [1, 2, 3]]
          }
          assert_equal "#{ApiMailer.name}#test_email", x.display_class
          assert_equal expected_args_by_version[ver], x.display_args
        end
      end
    end

    it "has no enqueued_at time for jobs enqueued in the future" do
      job_id = ApiJob.perform_in(100, 1, "foo")
      job = Sidekiq::ScheduledSet.new.find_job(job_id)
      assert_nil job.enqueued_at
    end

    it "returns tags field for jobs" do
      job_id = ApiJob.perform_async
      assert_equal [], Sidekiq::Queue.new.find_job(job_id).tags

      job_id = JobWithTags.perform_async
      assert_equal ["foo"], Sidekiq::Queue.new.find_job(job_id).tags
    end

    it "can delete jobs" do
      q = Sidekiq::Queue.new
      ApiJob.perform_async(1, "mike")
      assert_equal 1, q.size

      x = q.first
      assert_equal ApiJob.name, x.display_class
      assert_equal [1, "mike"], x.display_args

      assert_equal [true], q.map(&:delete)
      assert_equal 0, q.size
    end

    it "can move scheduled job to queue" do
      remain_id = ApiJob.perform_in(100, 1, "jason")
      job_id = ApiJob.perform_in(100, 1, "jason")
      job = Sidekiq::ScheduledSet.new.find_job(job_id)
      q = Sidekiq::Queue.new
      job.add_to_queue
      queued_job = q.find_job(job_id)
      refute_nil queued_job
      assert_equal queued_job.jid, job_id
      assert_nil Sidekiq::ScheduledSet.new.find_job(job_id)
      refute_nil Sidekiq::ScheduledSet.new.find_job(remain_id)
    end

    it "handles multiple scheduled jobs when moving to queue" do
      jids = Sidekiq::Client.push_bulk("class" => ApiJob,
        "args" => [[1, "jason"], [2, "jason"]],
        "at" => Time.now.to_f)
      assert_equal 2, jids.size
      (remain_id, job_id) = jids
      job = Sidekiq::ScheduledSet.new.find_job(job_id)
      q = Sidekiq::Queue.new
      job.add_to_queue
      queued_job = q.find_job(job_id)
      refute_nil queued_job
      assert_equal queued_job.jid, job_id
      assert_nil Sidekiq::ScheduledSet.new.find_job(job_id)
      refute_nil Sidekiq::ScheduledSet.new.find_job(remain_id)
    end

    it "can kill a scheduled job" do
      job_id = ApiJob.perform_in(100, 1, '{"foo":123}')
      job = Sidekiq::ScheduledSet.new.find_job(job_id)
      ds = Sidekiq::DeadSet.new
      assert_equal 0, ds.size
      job.kill
      assert_equal 1, ds.size
    end

    it "can find a scheduled job by jid" do
      10.times do |idx|
        ApiJob.perform_in(idx, 1)
      end

      job_id = ApiJob.perform_in(5, 1)
      job = Sidekiq::ScheduledSet.new.find_job(job_id)
      assert_equal job_id, job.jid

      ApiJob.perform_in(100, 1, "jid" => "jid_in_args")
      assert_nil Sidekiq::ScheduledSet.new.find_job("jid_in_args")
    end

    it "can remove jobs when iterating over a sorted set" do
      # scheduled jobs must be greater than SortedSet#each underlying page size
      51.times do
        ApiJob.perform_in(100, "aaron")
      end
      set = Sidekiq::ScheduledSet.new
      set.map(&:delete)
      assert_equal set.size, 0
    end

    it "can remove jobs when iterating over a queue" do
      # initial queue size must be greater than Queue#each underlying page size
      51.times do
        ApiJob.perform_async(1, "aaron")
      end
      q = Sidekiq::Queue.new
      q.map(&:delete)
      assert_equal q.size, 0
    end

    it "can find job by id in queues" do
      q = Sidekiq::Queue.new
      job_id = ApiJob.perform_async(1, "jason")
      job = q.find_job(job_id)
      refute_nil job
      assert_equal job_id, job.jid
    end

    it "can clear a queue" do
      q = Sidekiq::Queue.new
      2.times { ApiJob.perform_async(1, "mike") }
      q.clear

      Sidekiq.redis do |conn|
        refute conn.smembers("queues").include?("foo")
        refute(conn.exists("queue:foo") > 0)
      end
    end

    it "can fetch by score" do
      same_time = Time.now.to_f
      add_retry("bob1", same_time)
      add_retry("bob2", same_time)
      r = Sidekiq::RetrySet.new
      assert_equal 2, r.fetch(same_time).size
    end

    it "can fetch by score and jid" do
      same_time = Time.now.to_f
      add_retry("bob1", same_time)
      add_retry("bob2", same_time)
      r = Sidekiq::RetrySet.new
      assert_equal 1, r.fetch(same_time, "bob1").size
    end

    it "can fetch by score range" do
      same_time = Time.now.to_f
      add_retry("bob1", same_time)
      add_retry("bob2", same_time + 1)
      add_retry("bob3", same_time + 2)
      r = Sidekiq::RetrySet.new
      range = (same_time..(same_time + 1))
      assert_equal 2, r.fetch(range).size
    end

    it "can fetch by score range and jid" do
      same_time = Time.now.to_f
      add_retry("bob1", same_time)
      add_retry("bob2", same_time + 1)
      add_retry("bob3", same_time + 2)
      r = Sidekiq::RetrySet.new
      range = (same_time..(same_time + 1))
      jobs = r.fetch(range, "bob2")
      assert_equal 1, jobs.size
      assert_equal jobs[0].jid, "bob2"
    end

    it "shows empty retries" do
      r = Sidekiq::RetrySet.new
      assert_equal 0, r.size
    end

    it "can enumerate retries" do
      time = Time.now.to_f
      add_retry("bob", time)

      r = Sidekiq::RetrySet.new
      assert_equal 1, r.size
      array = r.to_a
      assert_equal 1, array.size

      retri = array.first
      assert_equal "ApiJob", retri.klass
      assert_equal "default", retri.queue
      assert_equal "bob", retri.jid
      assert_equal time, retri.at.to_f
    end

    it "requires a jid to delete an entry" do
      start_time = Time.now.to_f
      add_retry("bob2", Time.now.to_f)
      assert_raises(ArgumentError) do
        Sidekiq::RetrySet.new.delete(start_time)
      end
    end

    it "can delete a single retry from score and jid" do
      same_time = Time.now.to_f
      add_retry("bob1", same_time)
      add_retry("bob2", same_time)
      r = Sidekiq::RetrySet.new
      assert_equal 2, r.size
      Sidekiq::RetrySet.new.delete(same_time, "bob1")
      assert_equal 1, r.size
    end

    it "can retry a retry" do
      add_retry
      r = Sidekiq::RetrySet.new
      assert_equal 1, r.size
      r.first.retry
      assert_equal 0, r.size
      assert_equal 1, Sidekiq::Queue.new("default").size
      job = Sidekiq::Queue.new("default").first
      assert_equal "bob", job.jid
      assert_equal 1, job["retry_count"]
    end

    it "can clear retries" do
      add_retry
      add_retry("test")
      r = Sidekiq::RetrySet.new
      assert_equal 2, r.size
      r.clear
      assert_equal 0, r.size
    end

    it "can scan retries" do
      add_retry
      add_retry("test")
      r = Sidekiq::RetrySet.new
      assert_instance_of Enumerator, r.scan("Job")
      assert_equal 2, r.scan("ApiJob").to_a.size
      assert_equal 1, r.scan("*test*").to_a.size
    end

    it "can enumerate processes" do
      identity_string = "identity_string"
      odata = {
        "pid" => 123,
        "hostname" => Socket.gethostname,
        "key" => identity_string,
        "identity" => identity_string,
        "started_at" => Time.now.to_f - 15,
        "queues" => ["foo", "bar"],
        "weights" => {"foo" => 1, "bar" => 1},
        "version" => Sidekiq::VERSION,
        "embedded" => false
      }

      time = Time.now.to_f
      @cfg.redis do |conn|
        conn.multi do |transaction|
          transaction.sadd("processes", [odata["key"]])
          transaction.hset(odata["key"], "info", Sidekiq.dump_json(odata), "busy", 10, "beat", time)
          transaction.sadd("processes", ["fake:pid"])
        end
      end

      ps = Sidekiq::ProcessSet.new.to_a
      assert_equal 1, ps.size
      data = ps.first
      assert_equal 10, data["busy"]
      assert_equal time, data["beat"]
      assert_equal 123, data["pid"]
      assert_equal ["foo", "bar"], data.queues
      assert_equal({"foo" => 1, "bar" => 1}, data.weights)
      assert_equal Sidekiq::VERSION, data.version
      assert_equal false, data.embedded?
      data.quiet!
      data.stop!
      signals_string = "#{odata["key"]}-signals"
      assert_equal "TERM", @cfg.redis { |c| c.lpop(signals_string) }
      assert_equal "TSTP", @cfg.redis { |c| c.lpop(signals_string) }
    end

    it "can find processes" do
      identity_string = "identity_string"
      odata = {
        "pid" => 123,
        "hostname" => Socket.gethostname,
        "key" => identity_string,
        "identity" => identity_string,
        "started_at" => Time.now.to_f - 15,
        "queues" => ["foo", "bar"],
        "weights" => {"foo" => 1, "bar" => 1},
        "version" => Sidekiq::VERSION,
        "embedded" => true
      }

      time = Time.now.to_f
      @cfg.redis do |conn|
        conn.multi do |transaction|
          transaction.sadd("processes", [odata["key"]])
          transaction.hset(odata["key"], "info", Sidekiq.dump_json(odata), "busy", 10, "beat", time)
        end
      end

      assert_nil Sidekiq::ProcessSet["nope"]

      pro = Sidekiq::ProcessSet["identity_string"]
      assert_equal 10, pro["busy"]
      assert_equal time, pro["beat"]
      assert_equal 123, pro["pid"]
      assert_equal ["foo", "bar"], pro.queues
      assert_equal({"foo" => 1, "bar" => 1}, pro.weights)
      assert_equal Sidekiq::VERSION, pro.version
      assert_equal true, pro.embedded?
    end

    it "can't quiet or stop embedded processes" do
      p = Sidekiq::Process.new("embedded" => true)

      e = assert_raises(RuntimeError) { p.quiet! }
      assert_equal "Can't quiet an embedded process", e.message

      e = assert_raises(RuntimeError) { p.stop! }
      assert_equal "Can't stop an embedded process", e.message
    end

    it "can enumerate workers" do
      w = Sidekiq::Workers.new
      assert_equal 0, w.size
      w.each do
        assert false
      end

      hn = Socket.gethostname
      key = "#{hn}:#{$$}"
      pdata = {"pid" => $$, "hostname" => hn, "started_at" => Time.now.to_i}
      @cfg.redis do |conn|
        conn.sadd("processes", [key])
        conn.hset(key, "info", Sidekiq.dump_json(pdata), "busy", 0, "beat", Time.now.to_f)
      end

      s = "#{key}:work"
      data = Sidekiq.dump_json({"payload" => "{}", "queue" => "default", "run_at" => Time.now.to_i})
      @cfg.redis do |c|
        c.hset(s, "1234", data)
      end

      w.each do |p, x, work|
        assert_equal key, p
        assert_equal "1234", x
        assert_equal "default", work["queue"]
        assert_equal("{}", work["payload"])
        assert_equal Time.now.year, Time.at(work["run_at"]).year

        assert_equal "{}", work.payload
        assert_equal({}, work.job.item)
        assert_equal(Time.now.year, work.run_at.year)
        assert_equal "default", work.queue
        assert_equal "1234", work.thread_id
        assert_equal key, work.process_id
      end

      s = "#{key}:work"
      data = Sidekiq.dump_json({"payload" => {}, "queue" => "default", "run_at" => (Time.now.to_i - 2 * 60 * 60)})
      @cfg.redis do |c|
        c.multi do |transaction|
          transaction.hset(s, "5678", data)
          transaction.hset("b#{s}", "5678", data)
        end
      end

      assert_equal ["5678", "1234"], w.map { |_, tid, _| tid }
    end

    it "can find a work by jid" do
      w = Sidekiq::Workers.new
      hn = Socket.gethostname
      key = "#{hn}:#{$$}"
      @cfg.redis do |conn|
        conn.sadd("processes", [key])
      end

      s = "#{key}:work"
      jid = "abcdef"
      data = Sidekiq.dump_json({"payload" => {"args" => ["foo"], "jid" => jid}, "queue" => "default", "run_at" => Time.now.to_i})
      @cfg.redis do |c|
        c.hset(s, "1234", data)
      end

      assert_nil w.find_work_by_jid("nonexistent")

      work = w.find_work_by_jid(jid)
      assert_equal ["foo"], work.job.args
    end

    it "can reschedule jobs" do
      add_retry("foo1")
      add_retry("foo2")

      retries = Sidekiq::RetrySet.new
      assert_equal 2, retries.size
      refute(retries.map { |r| r.score > (Time.now.to_f + 9) }.any?)

      retries.each do |retri|
        retri.reschedule(Time.now + 15) if retri.jid == "foo1"
        retri.reschedule(Time.now.to_f + 10) if retri.jid == "foo2"
      end

      assert_equal 2, retries.size
      assert(retries.map { |r| r.score > (Time.now.to_f + 9) }.any?)
      assert(retries.map { |r| r.score > (Time.now.to_f + 14) }.any?)
    end

    it "prunes processes which have died" do
      data = {"pid" => rand(10_000), "hostname" => "app#{rand(1_000)}", "started_at" => Time.now.to_f}
      key = "#{data["hostname"]}:#{data["pid"]}"
      @cfg.redis do |conn|
        conn.sadd("processes", [key])
        conn.hset(key, "info", Sidekiq.dump_json(data), "busy", 0, "beat", Time.now.to_f)
      end
      ps = Sidekiq::ProcessSet.new
      assert_equal 1, ps.size

      @cfg.redis do |conn|
        conn.sadd("processes", ["bar:987", "bar:986"])
        conn.del("process_cleanup")
      end

      ps = Sidekiq::ProcessSet.new
      assert_equal 1, ps.size
      assert_equal 1, ps.to_a.size
    end

    def add_retry(jid = "bob", at = Time.now.to_f)
      payload = Sidekiq.dump_json("class" => "ApiJob", "args" => [1, "mike"], "queue" => "default", "jid" => jid, "retry_count" => 2, "failed_at" => Time.now.to_f, "error_backtrace" => ["line1", "line2"])
      @cfg.redis do |conn|
        conn.zadd("retry", at.to_s, payload)
      end
    end
  end
end
