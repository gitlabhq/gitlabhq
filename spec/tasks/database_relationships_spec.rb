# frozen_string_literal: true

require 'spec_helper'
require 'rake'

RSpec.describe 'rails db:relationships:all task', feature_category: :database do
  before(:all) do
    Rake.application.rake_require 'tasks/database_relationships'
  end

  let(:task) { Rake::Task['db:relationships:all'] }

  before do
    task.reenable
  end

  it 'outputs valid JSON data' do
    expect { task.invoke }.to output(
      satisfy { |output| !output.strip.empty? && Gitlab::Json.parse(output) }
    ).to_stdout
  end
end
