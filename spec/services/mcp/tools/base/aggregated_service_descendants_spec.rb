# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Mcp::Tools::Base::AggregatedService descendants', feature_category: :mcp_server do
  let(:dispatch_arguments) do
    {
      'search' => { scope: 'merge_requests', search: 'fix', project_id: '1' },
      'manage_pipeline' => { id: '1', pipeline_id: 1 },
      'save_merge_request' => { project_id: '1', merge_request_iid: 1 },
      'semantic_search' => { scope: 'code', q: 'auth', project_id: '1' },
      'start_duo_session' => { project_id: '1', goal: 'Fix the bug' },
      'send_duo_session_input' => { workflow_id: 1, human_approval: true }
    }
  end

  let(:sub_tool_response) do
    Mcp::Tools::Base::Response.success([{ type: 'text', text: '{"id":1}' }], { 'id' => 1 })
  end

  let(:manager_tools) { Mcp::Tools::Manager.new.tools }

  let(:aggregators) do
    dirs = [Rails.root.join('app/services/mcp/tools')]
    dirs << Rails.root.join('ee/app/services/mcp/tools') if Gitlab.ee?
    dirs.each { |dir| Rails.autoloaders.main.eager_load_dir(dir) }

    # Anonymous subclasses come from other specs' Class.new(AggregatedService) fixtures.
    Mcp::Tools::Base::AggregatedService.descendants.select(&:name)
  end

  it 'finds the aggregators' do
    expect(aggregators.map(&:tool_name)).to include('search', 'manage_pipeline', 'save_merge_request')
  end

  it 'records the dispatched sub-tool for every aggregator', :aggregate_failures do
    aggregators.each do |aggregator|
      tool_name = aggregator.tool_name
      arguments = dispatch_arguments[tool_name]
      service = manager_tools[tool_name]

      expect(arguments).to be_present, "add dispatch arguments for #{tool_name} to this spec"
      expect(service).to be_a(aggregator), "#{tool_name} is not registered with Mcp::Tools::Manager"
      next unless arguments && service.is_a?(aggregator)

      sub_tools = service.send(:tools)
      sub_tools.each { |sub_tool| allow(sub_tool).to receive(:execute).and_return(sub_tool_response.deep_dup) }

      result = service.execute(request: nil, params: { arguments: arguments.deep_dup })

      expect(result[:isError]).to be(false), "#{tool_name} returned an error: #{result[:content]}"
      expect(sub_tools.map { |sub_tool| sub_tool.name.to_s })
        .to include(result.dig(:dispatch, :tool_name)), "#{tool_name} did not record the dispatched sub-tool"
    end
  end
end
