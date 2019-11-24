# frozen_string_literal: true

require 'spec_helper'
require_relative './simple_check_shared'

describe Gitlab::HealthChecks::DbCheck do
  include_examples 'simple_check', 'db_ping', 'Db', '1'
end
