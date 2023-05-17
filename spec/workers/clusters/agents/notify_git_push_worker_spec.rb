# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Clusters::Agents::NotifyGitPushWorker, feature_category: :deployment_management do
  let_it_be(:project) { create(:project) }

  describe '#perform' do
    let(:project_id) { project.id }
    let(:kas_client) { instance_double(Gitlab::Kas::Client) }

    subject { described_class.new.perform(project_id) }

    it 'calls the deletion service' do
      expect(Gitlab::Kas::Client).to receive(:new).and_return(kas_client)
      expect(kas_client).to receive(:send_git_push_event).with(project: project)

      subject
    end

    context 'when the project no longer exists' do
      let(:project_id) { -1 }

      it 'completes without raising an error' do
        expect { subject }.not_to raise_error
      end
    end

    context 'when the :notify_kas_on_git_push feature flag is disabled' do
      before do
        stub_feature_flags(notify_kas_on_git_push: false)
      end

      it 'does not notify KAS' do
        expect(Gitlab::Kas::Client).not_to receive(:new)

        subject
      end
    end
  end
end
