require 'spec_helper'
require 'fetch_shared_examples'
require 'sidekiq/base_reliable_fetch'
require 'sidekiq/reliable_fetch'
require 'sidekiq/capsule'

describe Sidekiq::ReliableFetch do
  include_examples 'a Sidekiq fetcher'
end
