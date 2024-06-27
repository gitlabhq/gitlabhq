# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Import::SourceUserPolicy, feature_category: :importers do
  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group) }
  let_it_be(:user_namespace) { create(:namespace, owner: user) }

  subject { described_class.new(user, import_source_user) }

  describe 'admin_import_source_user' do
    context 'when import source user is associated with a user namespace' do
      let(:import_source_user) { create(:import_source_user, namespace: user_namespace) }

      context 'when user owns the namespace' do
        it { is_expected.to be_allowed(:admin_import_source_user) }
      end

      context 'when user does not own the namespace' do
        let(:user) { create(:user) }

        it { is_expected.to be_disallowed(:admin_import_source_user) }
      end
    end

    context 'when import source user is associated with a group' do
      let(:import_source_user) { create(:import_source_user, namespace: group) }

      context 'when user is an owner of the group' do
        before_all do
          group.add_owner(user)
        end

        it { is_expected.to be_allowed(:admin_import_source_user) }
      end

      context 'when user is not an owner of the group' do
        before_all do
          group.add_maintainer(user)
        end

        it { is_expected.to be_disallowed(:admin_import_source_user) }
      end
    end
  end
end
