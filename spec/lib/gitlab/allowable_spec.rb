# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Allowable, feature_category: :permissions do
  subject do
    Class.new.include(described_class).new
  end

  describe '#can?' do
    let(:user) { create(:user) }

    context 'when user is allowed to do something' do
      let(:project) { create(:project, :public) }

      it 'reports correct ability to perform action' do
        expect(subject.can?(user, :read_project, project)).to be true
      end
    end

    context 'when user is not allowed to do something' do
      let(:project) { create(:project, :private) }

      it 'reports correct ability to perform action' do
        expect(subject.can?(user, :read_project, project)).to be false
      end
    end
  end

  describe '#can_any?' do
    let(:user) { create(:user) }
    let(:permissions) { [:admin_project, :read_project] }

    context 'when the user is allowed one of the abilities' do
      let_it_be(:project) { create(:project, :public) }

      it { expect(subject.can_any?(user, permissions, project)).to be(true) }
    end

    context 'when the user is allowed none of the abilities' do
      let_it_be(:project) { create(:project, :private) }

      it { expect(subject.can_any?(user, permissions, project)).to be(false) }
    end
  end

  describe '#can_all?' do
    let_it_be(:user) { create(:user) }
    let_it_be(:permissions) { [:admin_project, :read_project] }

    context 'when the user is allowed all of the abilities' do
      let_it_be(:project) { create(:project, :private) }

      before_all do
        project.add_owner(user)
      end

      it { expect(subject.can_all?(user, permissions, project)).to be(true) }
    end

    context 'when the user is allowed one of the abilities' do
      let_it_be(:project) { create(:project, :public) }

      it { expect(subject.can_all?(user, permissions, project)).to be(false) }
    end

    context 'when the user is allowed none of the abilities' do
      let_it_be(:project) { create(:project, :private) }

      it { expect(subject.can_all?(user, permissions, project)).to be(false) }
    end
  end
end
