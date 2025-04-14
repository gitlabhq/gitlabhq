# frozen_string_literal: true

require_relative "helper"
require "sidekiq/api"
require "sidekiq/transaction_aware_client"

require_relative "dummy/config/environment"

class PostJob
  include Sidekiq::Job
  def perform
  end
end

class AlwaysDeferredJob
  include Sidekiq::Job
  sidekiq_options client_class: Sidekiq::TransactionAwareClient

  def perform
  end
end

class AlwaysPushedJob
  include Sidekiq::Job
  sidekiq_options client_class: Sidekiq::Client

  def perform
  end
end

class Post < ActiveRecord::Base
  after_create :do_thing

  def do_thing
    PostJob.perform_async
  end
end

describe Sidekiq::TransactionAwareClient do
  before(:all) do
    Post.connection.create_table(:posts, force: true) do |t|
      t.string :title
      t.date :published_date
    end
  end

  before do
    @config = reset!
    @app = Dummy::Application.new
    Post.delete_all
  end

  after do
    Sidekiq.default_job_options.delete("client_class")
  end

  describe ActiveRecord do
    it "pushes immediately by default" do
      q = Sidekiq::Queue.new
      assert_equal 0, q.size

      @app.executor.wrap do
        ActiveRecord::Base.transaction do
          Post.create!(title: "Hello", published_date: Date.today)
        end
      end
      assert_equal 1, q.size
      assert_equal 1, Post.count

      @app.executor.wrap do
        ActiveRecord::Base.transaction do
          Post.create!(title: "Hello", published_date: Date.today)
          raise ActiveRecord::Rollback
        end
      end
      assert_equal 2, q.size
      assert_equal 1, Post.count
    end

    it "can defer push within active transactions" do
      Sidekiq.transactional_push!
      q = Sidekiq::Queue.new
      assert_equal 0, q.size

      @app.executor.wrap do
        ActiveRecord::Base.transaction do
          Post.create!(title: "Hello", published_date: Date.today)
        end
      end
      assert_equal 1, q.size
      assert_equal 1, Post.count

      @app.executor.wrap do
        ActiveRecord::Base.transaction do
          Post.create!(title: "Hello", published_date: Date.today)
          raise ActiveRecord::Rollback
        end
      end
      assert_equal 1, q.size
      assert_equal 1, Post.count
    end

    it "defers push when enabled on a per job basis" do
      Sidekiq.transactional_push!
      q = Sidekiq::Queue.new
      assert_equal 0, q.size

      @app.executor.wrap do
        ActiveRecord::Base.transaction do
          AlwaysDeferredJob.perform_async
          raise ActiveRecord::Rollback
        end
      end
      assert_equal 0, q.size
    end

    it "pushes immediately when disabled on a per job basis" do
      Sidekiq.transactional_push!
      q = Sidekiq::Queue.new
      assert_equal 0, q.size

      @app.executor.wrap do
        ActiveRecord::Base.transaction do
          AlwaysPushedJob.perform_async
          raise ActiveRecord::Rollback
        end
      end
      assert_equal 1, q.size
    end
  end
end
