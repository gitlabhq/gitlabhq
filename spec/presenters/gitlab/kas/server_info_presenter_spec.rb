# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Kas::ServerInfoPresenter, feature_category: :deployment_management do
  let(:git_ref) { '6a0281c68969d9ce8f36fdaf242b4f6e0503d940' }
  let(:server_info) do
    instance_double(Gitlab::Kas::ServerInfo,
      retrieved_server_info?: true,
      version: '17.4.0-rc1',
      git_ref: git_ref)
  end

  let(:presenter) { described_class.new(server_info) }

  describe '#git_ref_for_display' do
    subject { presenter.git_ref_for_display }

    context 'when git ref is a commit' do
      let(:git_ref) { '6a0281c68969d9ce8f36fdaf242b4f6e0503d940' }

      it { is_expected.to eq('6a0281c6896') }
    end

    context 'with git ref is a tag' do
      let(:git_ref) { 'v17.4.0-rc1' }

      it { is_expected.to eq(git_ref) }
    end

    context 'when git ref is empty' do
      let(:git_ref) { '' }

      it { is_expected.to be_nil }
    end

    context 'when server_info is not retrieved' do
      let(:server_info) { instance_double(Gitlab::Kas::ServerInfo, retrieved_server_info?: false) }

      it { is_expected.to be_nil }
    end
  end

  describe '#git_ref_url' do
    subject { presenter.git_ref_url }

    context 'when git ref is a commit' do
      let(:git_ref) { '6a0281c68969d9ce8f36fdaf242b4f6e0503d940' }

      it 'returns a commit url' do
        is_expected.to eq(
          "#{Gitlab::Saas.com_url}/gitlab-org/cluster-integration/gitlab-agent/-/commits/#{git_ref}"
        )
      end
    end

    context 'when git ref is a tag' do
      let(:git_ref) { 'v17.4.0-rc1' }

      it 'returns a tag url' do
        is_expected.to eq(
          "#{Gitlab::Saas.com_url}/gitlab-org/cluster-integration/gitlab-agent/-/tags/#{git_ref}"
        )
      end
    end

    context 'when git ref is empty' do
      let(:git_ref) { '' }

      it { is_expected.to be_nil }
    end

    context 'when server_info is not retrieved' do
      let(:server_info) { instance_double(Gitlab::Kas::ServerInfo, retrieved_server_info?: false) }

      it { is_expected.to be_nil }
    end
  end
end
