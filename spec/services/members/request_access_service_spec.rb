require 'spec_helper'

describe Members::RequestAccessService, services: true do
  let(:user) { create(:user) }
  let(:project) { create(:project, :private) }
  let(:group) { create(:group, :private) }

  shared_examples 'a service raising Gitlab::Access::AccessDeniedError' do
    it 'raises Gitlab::Access::AccessDeniedError' do
      expect { described_class.new(source, user).execute }.to raise_error(Gitlab::Access::AccessDeniedError)
    end
  end

  shared_examples 'a service creating a access request' do
    it 'succeeds' do
      expect { described_class.new(source, user).execute }.to change { source.requesters.count }.by(1)
    end

    it 'returns a <Source>Member' do
      member = described_class.new(source, user).execute

      expect(member).to be_a "#{source.class.to_s}Member".constantize
      expect(member.requested_at).to be_present
    end
  end

  context 'when source is nil' do
    it_behaves_like 'a service raising Gitlab::Access::AccessDeniedError' do
      let(:source) { nil }
    end
  end

  context 'when current user cannot request access to the project' do
    it_behaves_like 'a service raising Gitlab::Access::AccessDeniedError' do
      let(:source) { project }
    end

    it_behaves_like 'a service raising Gitlab::Access::AccessDeniedError' do
      let(:source) { group }
    end
  end

  context 'when current user can request access to the project' do
    before do
      project.update(visibility_level: Gitlab::VisibilityLevel::PUBLIC)
      group.update(visibility_level: Gitlab::VisibilityLevel::PUBLIC)
    end

    it_behaves_like 'a service creating a access request' do
      let(:source) { project }
    end

    it_behaves_like 'a service creating a access request' do
      let(:source) { group }
    end
  end
end
