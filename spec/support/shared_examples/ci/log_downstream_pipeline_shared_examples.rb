# frozen_string_literal: true

RSpec.shared_examples 'logs downstream pipeline creation' do
  def record_downstream_pipeline_logs
    logs = []
    allow(::Gitlab::AppLogger).to receive(:info) do |args|
      logs << args
    end

    yield

    logs.find { |log| log[:message] == "downstream pipeline created" }
  end

  it 'logs details' do
    log_entry = record_downstream_pipeline_logs do
      downstream_pipeline
    end

    expect(log_entry).to be_present
    expect(log_entry).to eq(
      message: "downstream pipeline created",
      class: described_class.name,
      root_pipeline_id: expected_root_pipeline.id,
      downstream_pipeline_id: downstream_pipeline.id,
      downstream_pipeline_relationship: expected_downstream_relationship,
      hierarchy_size: expected_hierarchy_size,
      root_pipeline_plan: expected_root_pipeline.project.actual_plan_name,
      root_pipeline_namespace_path: expected_root_pipeline.project.namespace.full_path,
      root_pipeline_project_path: expected_root_pipeline.project.full_path)
  end
end
