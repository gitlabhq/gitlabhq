# frozen_string_literal: true

require 'spec_helper'

RSpec.describe UploadPolicy do
  let_it_be(:group) { create(:group, :private) }
  let_it_be(:project) { create(:project, :private, group: group) }
  let_it_be(:guest) { create(:user, guest_of: group) }
  let_it_be(:developer) { create(:user, developer_of: group) }
  let_it_be(:maintainer) { create(:user, maintainer_of: group) }
  let_it_be(:owner) { create(:user, owner_of: group) }
  let_it_be(:admin) { create(:admin) }
  let_it_be(:non_member_user) { create(:user) }

  let(:guest_permissions) { [:read_upload] }
  let(:admin_permissions) { [:destroy_upload] }

  shared_examples_for 'uploads policy' do
    subject { described_class.new(current_user, upload) }

    context 'when user is guest' do
      let(:current_user) { guest }

      it { is_expected.to be_allowed(*guest_permissions) }
      it { is_expected.to be_disallowed(*admin_permissions) }
    end

    context 'when user is developer' do
      let(:current_user) { developer }

      it { is_expected.to be_allowed(*guest_permissions) }
      it { is_expected.to be_disallowed(*admin_permissions) }
    end

    context 'when user is maintainer' do
      let(:current_user) { maintainer }

      it { is_expected.to be_allowed(*guest_permissions) }
      it { is_expected.to be_allowed(*admin_permissions) }
    end

    context 'when user is owner' do
      let(:current_user) { owner }

      it { is_expected.to be_allowed(*guest_permissions) }
      it { is_expected.to be_allowed(*admin_permissions) }
    end

    context 'when user is admin' do
      let(:current_user) { admin }

      it { is_expected.to be_disallowed(*guest_permissions) }
      it { is_expected.to be_disallowed(*admin_permissions) }

      context 'with admin mode', :enable_admin_mode do
        it { is_expected.to be_allowed(*guest_permissions) }
        it { is_expected.to be_allowed(*admin_permissions) }
      end
    end
  end

  context 'with project upload' do
    let_it_be(:upload) { create(:upload, model: project) }

    it_behaves_like 'uploads policy'
  end

  context 'with group upload' do
    let_it_be(:upload) { create(:upload, model: group) }

    it_behaves_like 'uploads policy'
  end

  context 'with upload associated with other model' do
    let_it_be(:upload) { create(:upload, model: maintainer) }

    subject { described_class.new(maintainer, upload) }

    it { is_expected.to be_disallowed(*guest_permissions) }
    it { is_expected.to be_disallowed(*admin_permissions) }
  end
end
