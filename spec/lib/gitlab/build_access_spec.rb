require 'spec_helper'

describe Gitlab::BuildAccess do
  let(:user) { create(:user) }
  let(:project) { create(:project) }

  describe '#can_do_action' do
    subject { described_class.new(user, project: project).can_do_action?(:download_code) }

    context 'when the user can do an action on the project but cannot access git' do
      before do
        user.block!
        project.add_developer(user)
      end

      it { is_expected.to be(true) }
    end

    context 'when the user cannot do an action on the project' do
      it { is_expected.to be(false) }
    end
  end
end
