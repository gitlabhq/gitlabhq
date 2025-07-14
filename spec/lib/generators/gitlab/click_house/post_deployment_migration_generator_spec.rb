# frozen_string_literal: true

require 'spec_helper'
require 'generators/gitlab/click_house/migration_generator'
require 'fileutils'
require 'rails/generators/testing/behavior'

RSpec.describe Gitlab::ClickHouse::PostDeploymentMigrationGenerator, feature_category: :database do
  let(:migration_path) { 'db/click_house/post_migrate' }

  it_behaves_like 'ClickHouse migration generator'
end
