# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Constraints::JiraEncodedUrlConstrainer do
  let(:namespace_id) { 'group' }
  let(:project_id) { 'project' }
  let(:path) { "/#{namespace_id}/#{project_id}" }
  let(:request) { double(:request, path: path, params: { namespace_id: namespace_id, project_id: project_id }) }

  describe '#matches?' do
    subject { described_class.new.matches?(request) }

    context 'when there is no /-/jira prefix and no encoded slash' do
      it { is_expected.to eq(false) }
    end

    context 'when tree path contains encoded slash' do
      let(:path) { "/#{namespace_id}/#{project_id}/tree/folder-with-#{Gitlab::Jira::Dvcs::ENCODED_SLASH}" }

      it { is_expected.to eq(false) }
    end

    context 'when path has /-/jira prefix' do
      let(:path) { "/-/jira/#{namespace_id}/#{project_id}" }

      it { is_expected.to eq(true) }
    end

    context 'when project_id has encoded slash' do
      let(:project_id) { "sub_group#{Gitlab::Jira::Dvcs::ENCODED_SLASH}sub_project" }

      it { is_expected.to eq(true) }
    end
  end
end
