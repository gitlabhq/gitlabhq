require 'bundler/setup'
require 'minitest/autorun'
require 'minitest/rg'
require 'webmock/minitest'
require 'mocha/minitest'
require 'json'
require 'kubeclient'

MiniTest::Test.class_eval do
  # Assumes test files will be in a subdirectory with the same name as the
  # file suffix.  e.g. a file named foo.json would be a "json" subdirectory.
  def open_test_file(name)
    File.new(File.join(File.dirname(__FILE__), name.split('.').last, name))
  end

  # kubeconfig files deviate from above convention.
  # They link to relaved certs etc. with various extensions, all in same dir.
  def config_file(name)
    File.join(File.dirname(__FILE__), 'config', name)
  end

  def stub_core_api_list
    stub_request(:get, %r{/api/v1$})
      .to_return(body: open_test_file('core_api_resource_list.json'), status: 200)
  end
end

WebMock.disable_net_connect!
