# frozen_string_literal: true

require 'spec_helper'

describe ProjectHookPresenter do
  let(:web_hook_log) { create(:web_hook_log) }
  let(:project) { web_hook_log.web_hook.project }
  let(:web_hook) { web_hook_log.web_hook }

  describe '#logs_details_path' do
    subject { web_hook.present.logs_details_path(web_hook_log) }

    let(:expected_path) do
      "/#{project.namespace.path}/#{project.name}/hooks/#{web_hook.id}/hook_logs/#{web_hook_log.id}"
    end

    it { is_expected.to eq(expected_path) }
  end

  describe '#logs_retry_path' do
    subject { web_hook.present.logs_details_path(web_hook_log) }

    let(:expected_path) do
      "/#{project.namespace.path}/#{project.name}/hooks/#{web_hook.id}/hook_logs/#{web_hook_log.id}"
    end

    it { is_expected.to eq(expected_path) }
  end
end
