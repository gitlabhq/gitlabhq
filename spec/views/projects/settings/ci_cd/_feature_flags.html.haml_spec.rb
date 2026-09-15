# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'projects/settings/ci_cd/_feature_flags', feature_category: :feature_flags do
  # rubocop:disable RSpec/FactoryBot/AvoidCreate -- the partial runs real ProjectPolicy checks against persisted membership
  let_it_be_with_reload(:project) { create(:project) }
  let_it_be(:maintainer) { create(:user, maintainer_of: project) }
  let_it_be(:owner) { project.first_owner }
  # rubocop:enable RSpec/FactoryBot/AvoidCreate

  let(:user) { maintainer }
  let(:feature_flag_enabled) { true }
  let(:minimum_role) { :developer }
  let(:feature_flags_access_level) { ProjectFeature::ENABLED }

  subject(:mount_point) { Nokogiri::HTML(rendered).at_css('#js-feature-flags-minimum-role-app') }

  before do
    stub_feature_flags(feature_flag_management_permissions: feature_flag_enabled)
    project.project_setting.update!(feature_flags_minimum_role: minimum_role)
    project.project_feature.update!(feature_flags_access_level: feature_flags_access_level)

    assign :project, project
    allow(view).to receive(:current_user).and_return(user)

    render partial: 'projects/settings/ci_cd/feature_flags', locals: { expanded: true }
  end

  context 'when the feature flag is disabled' do
    let(:feature_flag_enabled) { false }

    it 'renders nothing' do
      expect(rendered).to be_blank
    end
  end

  context 'when the user cannot read feature flags' do
    let(:feature_flags_access_level) { ProjectFeature::DISABLED }

    it 'renders nothing' do
      expect(rendered).to be_blank
    end
  end

  it 'renders the mount point with the project path and the current role' do
    expect(rendered).to have_text('Control who can manage feature flags')
    expect(mount_point['data-project-full-path']).to eq(project.full_path)
    expect(mount_point['data-minimum-role']).to eq('developer')
  end

  it 'lets a maintainer update the setting' do
    expect(mount_point['data-can-update']).to eq('true')
  end

  context 'when the minimum role is already privileged' do
    let(:minimum_role) { :owner }

    it 'does not let a maintainer update the setting' do
      expect(mount_point['data-can-update']).to eq('false')
    end

    context 'for an owner' do
      let(:user) { owner }

      it 'lets an owner update the setting' do
        expect(mount_point['data-can-update']).to eq('true')
      end
    end
  end

  context 'when the minimum role is no one allowed' do
    let(:minimum_role) { :no_one_allowed }

    it 'does not let a maintainer update the setting' do
      expect(mount_point['data-can-update']).to eq('false')
    end
  end
end
