# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Mcp::Handlers::CallTool, feature_category: :mcp_server do
  let(:manager) { instance_double(Mcp::Tools::Manager) }
  let(:request) { instance_double(Rack::Request) }
  let(:current_user) { instance_double(User) }

  subject(:handler) { described_class.new(manager) }

  describe '#invoke' do
    let(:tool_name) { 'test_tool' }
    let(:params) { { name: tool_name, arguments: { param: 'value' } } }
    let(:tool) { instance_double(Mcp::Tools::BaseService) }

    context 'when tool is found and version matches' do
      before do
        allow(manager).to receive(:get_tool).with(name: tool_name).and_return(tool)
        allow(tool).to receive(:is_a?).with(Mcp::Tools::CustomService).and_return(false)
        allow(tool).to receive(:execute).and_return({ content: [{ type: 'text', text: 'Success' }] })
      end

      it 'executes the tool successfully' do
        result = handler.invoke(request, params, current_user)

        expect(manager).to have_received(:get_tool).with(name: tool_name)
        expect(tool).to have_received(:execute).with(request: request, params: params)
        expect(result).to eq({ content: [{ type: 'text', text: 'Success' }] })
      end
    end

    context 'when tool is a CustomService' do
      let(:custom_tool) { instance_double(Mcp::Tools::CustomService) }

      before do
        allow(manager).to receive(:get_tool).with(name: tool_name).and_return(custom_tool)
        allow(custom_tool).to receive(:is_a?).with(Mcp::Tools::CustomService).and_return(true)
        allow(custom_tool).to receive(:set_cred)
        allow(custom_tool).to receive(:execute).and_return({ content: [{ type: 'text', text: 'Success' }] })
      end

      it 'sets credentials before executing' do
        result = handler.invoke(request, params, current_user)

        expect(custom_tool).to have_received(:set_cred).with(current_user: current_user)
        expect(custom_tool).to have_received(:execute).with(request: request, params: params)
        expect(result).to eq({ content: [{ type: 'text', text: 'Success' }] })
      end
    end

    context 'when tool is not found' do
      before do
        allow(manager).to receive(:get_tool).with(name: tool_name)
          .and_raise(Mcp::Tools::Manager::ToolNotFoundError.new(tool_name))
      end

      it 'raises ArgumentError' do
        expect { handler.invoke(request, params, current_user) }
          .to raise_error(ArgumentError, "Tool '#{tool_name}' not found.")
      end
    end
  end
end
