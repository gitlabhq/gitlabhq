# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Git::TagPolicy, feature_category: :source_code_management do
  let_it_be(:project) { create(:project, :public, :repository) }
  let_it_be(:guest) { create(:user, guest_of: project) }
  let_it_be(:developer) { create(:user, developer_of: project) }
  let_it_be(:maintainer) { create(:user, maintainer_of: project) }
  let_it_be(:owner) { create(:user, owner_of: project) }
  let_it_be(:tag) { project.repository.tags.first }

  subject { described_class.new(user, tag) }

  context 'when user is a project guest' do
    let(:user) { guest }

    it { is_expected.to be_disallowed(:delete_tag) }
  end

  context 'when user is a project developer' do
    let(:user) { developer }

    it { is_expected.to be_allowed(:delete_tag) }

    context 'when the tag is protected' do
      let_it_be(:protected_tag) { create(:protected_tag, project: project, name: tag.name) }

      it { is_expected.to be_disallowed(:delete_tag) }
    end
  end

  context 'when user is a project maintainer' do
    let(:user) { maintainer }

    it { is_expected.to be_allowed(:delete_tag) }

    context 'when the tag is protected' do
      let_it_be(:protected_tag) { create(:protected_tag, project: project, name: tag.name) }

      it { is_expected.to be_allowed(:delete_tag) }
    end
  end

  context 'when user is a project owner' do
    let(:user) { owner }

    it { is_expected.to be_allowed(:delete_tag) }

    context 'when the tag is protected' do
      let_it_be(:protected_tag) { create(:protected_tag, project: project, name: tag.name) }

      it { is_expected.to be_allowed(:delete_tag) }
    end
  end
end
