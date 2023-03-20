# frozen_string_literal: true

require 'spec_helper'

RSpec.describe FeatureFlags::HookService, feature_category: :feature_flags do
  describe '#execute_hooks' do
    let_it_be(:namespace) { create(:namespace) }
    let_it_be(:project) { create(:project, :repository, namespace: namespace) }
    let_it_be(:feature_flag) { create(:operations_feature_flag, project: project) }
    let_it_be(:user) { namespace.first_owner }

    let!(:hook) { create(:project_hook, project: project) }
    let(:hook_data) { double }

    subject(:service) { described_class.new(feature_flag, user) }

    before do
      allow(Gitlab::DataBuilder::FeatureFlag).to receive(:build).with(feature_flag, user).once.and_return(hook_data)
    end

    describe 'HOOK_NAME' do
      specify { expect(described_class::HOOK_NAME).to eq(:feature_flag_hooks) }
    end

    it 'calls feature_flag.project.execute_hooks' do
      expect(feature_flag.project).to receive(:execute_hooks).with(hook_data, described_class::HOOK_NAME)

      service.execute
    end
  end
end
