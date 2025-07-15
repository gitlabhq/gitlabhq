# frozen_string_literal: true

require 'spec_helper'
require 'generators/gitlab/click_house/migration_generator'
require 'fileutils'
require 'rails/generators/testing/behavior'

RSpec.describe Gitlab::ClickHouse::MigrationGenerator, feature_category: :database do
  let(:migration_path) { 'db/click_house/migrate' }

  it_behaves_like 'ClickHouse migration generator'
end
