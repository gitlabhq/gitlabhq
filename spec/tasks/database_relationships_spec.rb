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
    output = capture_task_output { task.invoke }

    expect { Gitlab::Json.parse(output) }.not_to raise_error
    expect(output.strip).not_to be_empty
  end

  private

  def capture_task_output
    original_stdout = $stdout
    $stdout = StringIO.new
    yield
    $stdout.string
  ensure
    $stdout = original_stdout
  end
end
