# frozen_string_literal: true

RSpec.shared_examples 'checks self and root ancestor feature flag' do
  let_it_be(:root_group) { create(:group) }
  let_it_be(:group) { create(:group, parent: root_group) }

  subject { group.public_send(feature_flag_method) }

  context 'when FF is enabled for the root group' do
    before do
      stub_feature_flags(feature_flag => root_group)
    end

    it { is_expected.to be_truthy }
  end

  context 'when FF is enabled for the group' do
    before do
      stub_feature_flags(feature_flag => group)
    end

    it { is_expected.to be_truthy }

    context 'when root_group is the actor' do
      it 'is not enabled if the FF is enabled for a child' do
        expect(root_group.public_send(feature_flag_method)).to be_falsey
      end
    end
  end

  context 'when FF is disabled globally' do
    before do
      stub_feature_flags(feature_flag => false)
    end

    it { is_expected.to be_falsey }
  end

  context 'when FF is enabled globally' do
    it { is_expected.to be_truthy }
  end
end

RSpec.shared_examples 'checks self (project) and root ancestor feature flag' do
  let_it_be(:root_group) { create(:group) }
  let_it_be(:group) { create(:group, parent: root_group) }
  let_it_be(:project) { create(:project, group: group) }

  subject { project.public_send(feature_flag_method) }

  context 'when FF is enabled for the root group' do
    before do
      stub_feature_flags(feature_flag => root_group)
    end

    it { is_expected.to be_truthy }
  end

  context 'when FF is enabled for the group' do
    before do
      stub_feature_flags(feature_flag => group)
    end

    it { is_expected.to be_truthy }
  end

  context 'when FF is enabled for the project' do
    before do
      stub_feature_flags(feature_flag => project)
    end

    it { is_expected.to be_truthy }
  end

  context 'when FF is disabled globally' do
    before do
      stub_feature_flags(feature_flag => false)
    end

    it { is_expected.to be_falsey }
  end

  context 'when FF is enabled globally' do
    it { is_expected.to be_truthy }
  end
end
