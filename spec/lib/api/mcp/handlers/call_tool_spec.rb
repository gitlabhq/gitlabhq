# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Mcp::Handlers::CallTool, feature_category: :mcp_server do
  let(:manager) { instance_double(Mcp::Tools::Manager) }
  let(:request) { instance_double(Rack::Request) }
  let_it_be(:current_user) { create(:user) }

  subject(:handler) { described_class.new(manager) }

  describe '#invoke' do
    let(:tool_name) { 'test_tool' }
    let(:params) { { name: tool_name, arguments: { param: 'value' } } }
    let(:tool) { instance_double(Mcp::Tools::Base::BaseService) }
    let(:logger) { instance_double(Gitlab::Mcp::Logger) }

    before do
      allow(request).to receive(:[]).with(:id).and_return('1')
      allow(Gitlab::Mcp::Logger).to receive(:build).and_return(logger)
      allow(logger).to receive(:conditional_info)
    end

    context 'when tool is found and version matches' do
      before do
        allow(manager).to receive(:get_tool).with(name: tool_name).and_return(tool)
        allow(tool).to receive(:is_a?).with(Mcp::Tools::Base::CustomService).and_return(false)
        allow(tool).to receive(:is_a?).with(Mcp::Tools::Base::GraphqlService).and_return(false)
        allow(tool).to receive(:execute).and_return({ content: [{ type: 'text', text: 'Success' }] })
      end

      it 'executes the tool successfully' do
        result = handler.invoke(request, params, current_user)

        expect(manager).to have_received(:get_tool).with(name: tool_name)
        expect(tool).to have_received(:execute).with(request: request, params: params)
        expect(result).to eq({ content: [{ type: 'text', text: 'Success' }] })
      end

      it 'logs the successful tool call with indexable fields and gated argument values', :aggregate_failures do
        handler.invoke(request, params, current_user)

        expect(logger).to have_received(:conditional_info).with(
          current_user,
          hash_including(
            ::Labkit::Fields::DURATION_S,
            message: 'MCP tool call',
            event_name: 'tool_call',
            ai_component: 'mcp_server',
            tool_name: tool_name,
            session_id: '1',
            tool_status: 'done',
            argument_keys: ['param'],
            expanded: { arguments: { 'param' => 'value' } }
          )
        )
        expect(logger).to have_received(:conditional_info).with(
          current_user, hash_excluding(::Labkit::Fields::ERROR_TYPE)
        )
      end
    end

    context 'when the tool raises during execution' do
      before do
        allow(manager).to receive(:get_tool).with(name: tool_name).and_return(tool)
        allow(tool).to receive(:is_a?).with(Mcp::Tools::Base::CustomService).and_return(false)
        allow(tool).to receive(:is_a?).with(Mcp::Tools::Base::GraphqlService).and_return(false)
        allow(tool).to receive(:execute).and_raise(StandardError, 'boom')
      end

      it 'logs the failure and re-raises' do
        expect { handler.invoke(request, params, current_user) }.to raise_error(StandardError, 'boom')

        expect(logger).to have_received(:conditional_info).with(
          current_user,
          hash_including(
            tool_name: tool_name,
            tool_status: 'fail',
            ::Labkit::Fields::ERROR_TYPE => 'StandardError',
            expanded: hash_including(::Labkit::Fields::ERROR_MESSAGE => 'boom')
          )
        )
      end
    end

    context 'when tool is a custom service' do
      let(:custom_tool) { instance_double(Mcp::Tools::Base::CustomService) }

      before do
        allow(manager).to receive(:get_tool).with(name: tool_name).and_return(custom_tool)
        allow(custom_tool).to receive(:is_a?).with(Mcp::Tools::Base::CustomService).and_return(true)
        allow(custom_tool).to receive(:is_a?).with(Mcp::Tools::Base::GraphqlService).and_return(false)
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

    context 'when tool is a graphql service' do
      let(:graphql_tool) { instance_double(Mcp::Tools::Base::GraphqlService) }

      before do
        allow(manager).to receive(:get_tool).with(name: tool_name).and_return(graphql_tool)
        allow(graphql_tool).to receive(:is_a?).with(Mcp::Tools::Base::CustomService).and_return(false)
        allow(graphql_tool).to receive(:is_a?).with(Mcp::Tools::Base::GraphqlService).and_return(true)
        allow(graphql_tool).to receive(:set_cred)
        allow(graphql_tool).to receive(:execute).and_return({ content: [{ type: 'text', text: 'Success' }] })
      end

      it 'sets credentials before executing' do
        result = handler.invoke(request, params, current_user)

        expect(graphql_tool).to have_received(:set_cred).with(current_user: current_user)
        expect(graphql_tool).to have_received(:execute).with(request: request, params: params)
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

      it 'logs the failed tool call' do
        expect { handler.invoke(request, params, current_user) }.to raise_error(ArgumentError)

        expect(logger).to have_received(:conditional_info).with(
          current_user,
          hash_including(
            tool_name: tool_name,
            tool_status: 'fail',
            ::Labkit::Fields::ERROR_TYPE => 'Mcp::Tools::Manager::ToolNotFoundError'
          )
        )
      end
    end
  end
end
