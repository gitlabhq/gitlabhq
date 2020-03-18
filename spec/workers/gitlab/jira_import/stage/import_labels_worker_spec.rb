# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::JiraImport::Stage::ImportLabelsWorker do
  let(:project) { create(:project) }
  let(:worker) { described_class.new }

  describe 'modules' do
    it_behaves_like 'include import workers modules'
  end

  describe '#perform' do
    context 'when feature flag enabled' do
      before do
        stub_feature_flags(jira_issue_import: false)
      end

      it_behaves_like 'exit import not started'
    end

    context 'when feature flag enabled' do
      before do
        stub_feature_flags(jira_issue_import: true)
      end

      context 'when import did not start' do
        let!(:import_state) { create(:import_state, project: project) }

        it_behaves_like 'exit import not started'
      end

      context 'when import started' do
        let!(:import_state) { create(:import_state, status: :started, project: project) }

        it_behaves_like 'advance to next stage', :issues
      end
    end
  end
end
