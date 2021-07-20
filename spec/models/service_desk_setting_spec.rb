# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ServiceDeskSetting do
  describe 'validations' do
    subject(:service_desk_setting) { create(:service_desk_setting) }

    it { is_expected.to validate_presence_of(:project_id) }
    it { is_expected.to validate_length_of(:outgoing_name).is_at_most(255) }
    it { is_expected.to validate_length_of(:project_key).is_at_most(255) }
    it { is_expected.to allow_value('abc123_').for(:project_key) }
    it { is_expected.not_to allow_value('abc 12').for(:project_key).with_message("can contain only lowercase letters, digits, and '_'.") }
    it { is_expected.not_to allow_value('Big val').for(:project_key) }

    describe '.valid_issue_template' do
      let_it_be(:project) { create(:project, :custom_repo, files: { '.gitlab/issue_templates/service_desk.md' => 'template' }) }

      it 'is not valid if template does not exist' do
        settings = build(:service_desk_setting, project: project, issue_template_key: 'invalid key')

        expect(settings).not_to be_valid
        expect(settings.errors[:issue_template_key].first).to eq('is empty or does not exist')
      end

      it 'is valid if template exists' do
        settings = build(:service_desk_setting, project: project, issue_template_key: 'service_desk')

        expect(settings).to be_valid
      end
    end
  end

  describe '.valid_project_key' do
    # Creates two projects with same full path slug
    # group1/test/one and group1/test-one will both have 'group-test-one' slug
    let_it_be(:group) { create(:group) }
    let_it_be(:subgroup) { create(:group, parent: group, name: 'test') }
    let_it_be(:project1) { create(:project, name: 'test-one', group: group) }
    let_it_be(:project2) { create(:project, name: 'one', group: subgroup) }
    let_it_be(:project_key) { 'key' }

    before_all do
      create(:service_desk_setting, project: project1, project_key: project_key)
    end

    context 'when project_key is unique for every project slug' do
      it 'does not add error' do
        settings = build(:service_desk_setting, project: project2, project_key: 'otherkey')

        expect(settings).to be_valid
      end
    end

    context 'when project with same slug and settings project_key exists' do
      it 'adds error' do
        settings = build(:service_desk_setting, project: project2, project_key: project_key)

        expect(settings).to be_invalid
        expect(settings.errors[:project_key].first).to eq('already in use for another service desk address.')
      end
    end
  end

  describe 'associations' do
    it { is_expected.to belong_to(:project) }
  end
end
