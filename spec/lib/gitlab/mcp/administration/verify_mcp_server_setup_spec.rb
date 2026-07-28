# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Mcp::Administration::VerifyMcpServerSetup, :silence_stdout, feature_category: :mcp_server do
  let_it_be(:user, freeze: false) { create(:user, :admin, username: 'mcp_test_user') }

  let(:username) { user.username }
  let(:task) { described_class.new(username) }

  subject(:verify_setup) { task.execute }

  before do
    allow(::Gitlab::CurrentSettings).to receive(:mcp_server_enabled?).and_return(true)
  end

  describe '#execute' do
    context 'when everything is configured correctly' do
      it 'completes without error' do
        expect { verify_setup }.not_to raise_error
      end

      it 'collects system information' do
        verify_setup

        expect(task.diagnostics[:system]).to include(
          gitlab_version: Gitlab::VERSION,
          gitlab_edition: ::Gitlab.ee? ? 'EE' : 'CE',
          user: user.username
        )
      end

      context 'when running CE' do
        before do
          allow(::Gitlab).to receive(:ee?).and_return(false)
        end

        it 'reports CE edition' do
          verify_setup

          expect(task.diagnostics[:system]).to include(gitlab_edition: 'CE')
        end
      end

      it 'reports no failures' do
        verify_setup

        expect(task.diagnostics.values).not_to include(hash_including(status: 'FAIL'))
      end
    end

    context 'when no username is provided' do
      let(:username) { nil }

      it 'skips user-specific checks' do
        verify_setup

        expect(task.diagnostics).not_to include(:user_active)
      end
    end

    context 'when username does not exist' do
      let(:username) { 'nonexistent_user' }

      it 'records failure for user lookup' do
        verify_setup

        expect(task.diagnostics[:user_lookup]).to include(status: 'FAIL')
        expect(task.diagnostics[:user_lookup][:message]).to include('nonexistent_user')
      end
    end
  end

  describe '#check_mcp_server_enabled' do
    context 'when mcp_server_enabled is true' do
      it 'records pass' do
        verify_setup

        expect(task.diagnostics[:mcp_server_enabled]).to include(status: 'PASS')
      end
    end

    context 'when mcp_server_enabled is false' do
      before do
        allow(::Gitlab::CurrentSettings).to receive(:mcp_server_enabled?).and_return(false)
      end

      it 'records failure' do
        verify_setup

        expect(task.diagnostics[:mcp_server_enabled]).to include(status: 'FAIL')
      end
    end
  end

  describe '#check_oauth_discovery' do
    context 'when API::Mcp::Base is loaded with routes' do
      it 'records pass' do
        verify_setup

        expect(task.diagnostics[:oauth_discovery]).to include(status: 'PASS')
        expect(task.diagnostics[:oauth_discovery][:message]).to include('API::Mcp::Base')
      end
    end

    context 'when API::Mcp::Base is not defined' do
      before do
        hide_const('API::Mcp::Base')
      end

      it 'records failure' do
        verify_setup

        expect(task.diagnostics[:oauth_discovery]).to include(status: 'FAIL')
        expect(task.diagnostics[:oauth_discovery][:message]).to include('NOT loaded')
      end
    end
  end

  describe 'user checks' do
    context 'when user is active' do
      it 'records pass' do
        verify_setup

        expect(task.diagnostics[:user_active]).to include(status: 'PASS')
      end
    end

    context 'when user is blocked' do
      before do
        user.block!
      end

      after do
        user.activate!
      end

      it 'records failure' do
        verify_setup

        expect(task.diagnostics[:user_active]).to include(status: 'FAIL')
      end
    end
  end

  describe '#output_diagnostics' do
    it 'outputs JSON formatted diagnostics' do
      verify_setup

      expect(task.diagnostics).to include(:system, :oauth_discovery)
    end
  end
end
