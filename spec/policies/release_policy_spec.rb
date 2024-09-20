# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ReleasePolicy, :request_store do
  let_it_be(:developer) { create(:user) }
  let_it_be(:maintainer) { create(:user) }
  let_it_be(:project) { create(:project, :repository, developers: developer, maintainers: maintainer) }
  let_it_be(:release, reload: true) { create(:release, project: project) }

  let(:user) { developer }

  subject { described_class.new(user, release) }

  context 'when the user has access to the protected tag' do
    let_it_be(:protected_tag) { create(:protected_tag, :developers_can_create, name: release.tag, project: project) }

    it 'allows the user to create, update and destroy a release' do
      is_expected.to be_allowed(:create_release)
      is_expected.to be_allowed(:update_release)
      is_expected.to be_allowed(:destroy_release)
      is_expected.to be_allowed(:publish_catalog_version)
    end
  end

  context 'when the user does not have access to the protected tag' do
    let_it_be(:protected_tag) { create(:protected_tag, :maintainers_can_create, name: release.tag, project: project) }

    it 'prevents the user from creating, updating and destroying a release' do
      is_expected.to be_disallowed(:create_release)
      is_expected.to be_disallowed(:update_release)
      is_expected.to be_disallowed(:destroy_release)
      is_expected.to be_disallowed(:publish_catalog_version)
    end
  end
end
