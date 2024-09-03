# frozen_string_literal: true

require_relative "helper"
require "sidekiq/web"

class Helpers
  include Sidekiq::WebHelpers

  def initialize(params = {})
    @thehash = default.merge(params)
  end

  def request
    self
  end

  def settings
    self
  end

  def locales
    ["web/locales"]
  end

  def env
    @thehash
  end

  def default
    {}
  end

  def path_info
    @thehash[:path_info]
  end
end

describe "Web helpers" do
  before do
    Sidekiq.redis { |c| c.flushdb }
  end

  it "tests locale determination" do
    obj = Helpers.new
    assert_equal "en", obj.locale

    obj = Helpers.new("HTTP_ACCEPT_LANGUAGE" => "fr-FR,fr;q=0.8,en-US;q=0.6,en;q=0.4,ru;q=0.2")
    assert_equal "fr", obj.locale

    obj = Helpers.new("HTTP_ACCEPT_LANGUAGE" => "zh-CN,zh;q=0.8,en-US;q=0.6,en;q=0.4,ru;q=0.2")
    assert_equal "zh-cn", obj.locale

    obj = Helpers.new("HTTP_ACCEPT_LANGUAGE" => "en-US,sv-SE;q=0.8,sv;q=0.6,en;q=0.4")
    assert_equal "en", obj.locale

    obj = Helpers.new("HTTP_ACCEPT_LANGUAGE" => "nb-NO,nb;q=0.2")
    assert_equal "nb", obj.locale

    obj = Helpers.new("HTTP_ACCEPT_LANGUAGE" => "en-us")
    assert_equal "en", obj.locale

    obj = Helpers.new("HTTP_ACCEPT_LANGUAGE" => "sv-se")
    assert_equal "sv", obj.locale

    obj = Helpers.new("HTTP_ACCEPT_LANGUAGE" => "pt-BR,pt;q=0.8,en-US;q=0.6,en;q=0.4")
    assert_equal "pt-br", obj.locale

    obj = Helpers.new("HTTP_ACCEPT_LANGUAGE" => "pt-PT,pt;q=0.8,en-US;q=0.6,en;q=0.4")
    assert_equal "pt", obj.locale

    obj = Helpers.new("HTTP_ACCEPT_LANGUAGE" => "pt-br")
    assert_equal "pt-br", obj.locale

    obj = Helpers.new("HTTP_ACCEPT_LANGUAGE" => "pt-pt")
    assert_equal "pt", obj.locale

    obj = Helpers.new("HTTP_ACCEPT_LANGUAGE" => "pt")
    assert_equal "pt", obj.locale

    obj = Helpers.new("HTTP_ACCEPT_LANGUAGE" => "en-us; *")
    assert_equal "en", obj.locale

    obj = Helpers.new("HTTP_ACCEPT_LANGUAGE" => "en-US,en;q=0.8")
    assert_equal "en", obj.locale

    obj = Helpers.new("HTTP_ACCEPT_LANGUAGE" => "en-GB,en-US;q=0.8,en;q=0.6")
    assert_equal "en", obj.locale

    obj = Helpers.new("HTTP_ACCEPT_LANGUAGE" => "ru,en")
    assert_equal "ru", obj.locale

    obj = Helpers.new("HTTP_ACCEPT_LANGUAGE" => "lt")
    assert_equal "lt", obj.locale

    obj = Helpers.new("HTTP_ACCEPT_LANGUAGE" => "*")
    assert_equal "en", obj.locale
  end

  it "tests user selected locale" do
    obj = Helpers.new("HTTP_ACCEPT_LANGUAGE" => "*")

    obj.instance_eval do
      def session
        {locale: "es"}
      end
    end

    assert_equal "es", obj.locale
  end

  it "tests available locales" do
    obj = Helpers.new
    expected = %w[
      ar cs da de el en es fa fr gd he hi it ja
      ko lt nb nl pl pt pt-br ru sv ta uk ur
      vi zh-cn zh-tw
    ]
    assert_equal expected, obj.available_locales.sort
  end

  it "tests displaying of illegal args" do
    obj = Helpers.new
    s = obj.display_args([1, 2, 3])
    assert_equal "1, 2, 3", s
    s = obj.display_args(["<html>", 12])
    assert_equal "&quot;&lt;html&gt;&quot;, 12", s
    s = obj.display_args("<html>")
    assert_equal "Invalid job payload, args must be an Array, not String", s
    s = obj.display_args(nil)
    assert_equal "Invalid job payload, args is nil", s
  end

  it "query string escapes bad query input" do
    obj = Helpers.new
    assert_equal "page=B%3CH", obj.to_query_string("page" => "B<H")
  end

  it "qparams string escapes bad query input" do
    obj = Helpers.new
    obj.instance_eval do
      def params
        {"direction" => "H>B"}
      end
    end
    assert_equal "direction=H%3EB&page=B%3CH", obj.qparams("page" => "B<H")
  end

  describe "#format_memory" do
    it "returns in KB" do
      obj = Helpers.new
      assert_equal "<span data-nwp=\"0\">1</span> KB", obj.format_memory(1)
    end

    it "returns in MB" do
      obj = Helpers.new
      assert_equal "<span data-nwp=\"0\">97</span> MB", obj.format_memory(100_002)
    end

    it "returns in GB" do
      obj = Helpers.new
      assert_equal "<span data-nwp=\"1\">9.5</span> GB", obj.format_memory(10_000_001)
    end
  end

  it "sorts processes using the natural sort order" do
    ["a.10.2", "a.2", "busybee--10_1", "a.23", "a.10.1", "a.1", "192.168.0.10", "192.168.0.2", "2.1.1.1", "busybee-2__34"].each do |hostname|
      pdata = {"hostname" => hostname, "pid" => "123", "started_at" => Time.now.to_i}
      key = "#{hostname}:123"

      Sidekiq.redis do |conn|
        conn.sadd("processes", [key])
        conn.hset(key, "info", Sidekiq.dump_json(pdata), "busy", 0, "beat", Time.now.to_f)
      end
    end

    obj = Helpers.new

    assert obj.sorted_processes.all? { |process| assert_instance_of Sidekiq::Process, process }
    assert_equal ["2.1.1.1", "192.168.0.2", "192.168.0.10", "a.1", "a.2", "a.10.1", "a.10.2", "a.23", "busybee-2__34", "busybee--10_1"], obj.sorted_processes.map { |process| process["hostname"] }
  end

  it "sorts processes with multiple dividers correctly" do
    ["worker_critical.2", "worker_default.1", "worker_critical.1", "worker_default.2", "worker_critical.10"].each do |hostname|
      pdata = {"hostname" => hostname, "pid" => "123", "started_at" => Time.now.to_i}
      key = "#{hostname}:123"

      Sidekiq.redis do |conn|
        conn.sadd("processes", [key])
        conn.hset(key, "info", Sidekiq.dump_json(pdata), "busy", 0, "beat", Time.now.to_f)
      end
    end

    obj = Helpers.new

    assert obj.sorted_processes.all? { |process| assert_instance_of Sidekiq::Process, process }
    assert_equal ["worker_critical.1", "worker_critical.2", "worker_critical.10", "worker_default.1", "worker_default.2"], obj.sorted_processes.map { |process| process["hostname"] }
  end

  it "displays queue weights properly" do
    capsule_weights = [{"high" => 0, "default" => 0, "low" => 0}]
    obj = Helpers.new
    assert_equal "high, default, low", obj.busy_weights(capsule_weights)
    capsule_weights = [{"high" => 3, "default" => 2, "low" => 1}, {"single" => 0}]
    assert_equal "high: 3, default: 2, low: 1; single", obj.busy_weights(capsule_weights)
    capsule_weights = [{"high" => 1, "default" => 1, "low" => 1}, {"single" => 0}]
    assert_equal "high: 1, default: 1, low: 1; single", obj.busy_weights(capsule_weights)

    # old data
    capsule_weights = {"high" => 1, "default" => 1, "low" => 1}
    assert_equal "high: 1, default: 1, low: 1", obj.busy_weights(capsule_weights)
  end

  describe "#pollable?" do
    it "returns true if not the root or metrics path" do
      obj = Helpers.new({path_info: "/retries"})

      assert obj.pollable?
    end

    it "returns false if the root or metrics path" do
      obj = Helpers.new({path_info: "/metrics"})

      assert_equal false, obj.pollable?

      obj = Helpers.new({path_info: "/"})

      assert_equal false, obj.pollable?
    end
  end
end
