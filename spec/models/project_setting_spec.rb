# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ProjectSetting, type: :model, feature_category: :groups_and_projects do
  using RSpec::Parameterized::TableSyntax
  it { is_expected.to belong_to(:project) }

  describe 'default values' do
    it { expect(subject.legacy_open_source_license_available).to be_truthy }
  end

  describe 'scopes' do
    let_it_be(:project_1) { create(:project) }
    let_it_be(:project_2) { create(:project) }
    let_it_be(:project_setting_1) { create(:project_setting, project: project_1) }
    let_it_be(:project_setting_2) { create(:project_setting, project: project_2) }

    it 'returns project setting for the given projects' do
      expect(described_class.for_projects(project_1)).to contain_exactly(project_setting_1)
    end
  end

  describe 'validations' do
    it { is_expected.not_to allow_value(nil).for(:target_platforms) }
    it { is_expected.to allow_value([]).for(:target_platforms) }
    it { is_expected.to validate_length_of(:issue_branch_template).is_at_most(255) }

    it 'allows any combination of the allowed target platforms' do
      valid_target_platform_combinations.each do |target_platforms|
        expect(subject).to allow_value(target_platforms).for(:target_platforms)
      end
    end

    [nil, 'not_allowed', :invalid].each do |invalid_value|
      it { is_expected.not_to allow_value([invalid_value]).for(:target_platforms) }
    end

    context "when pages_unique_domain is required", feature_category: :pages do
      it "is not required if pages_unique_domain_enabled is false" do
        project_setting = build(:project_setting, pages_unique_domain_enabled: false)

        expect(project_setting).to be_valid
        expect(project_setting.errors.full_messages).not_to include("Pages unique domain can't be blank")
      end

      it "is required when pages_unique_domain_enabled is true" do
        project_setting = build(:project_setting, pages_unique_domain_enabled: true)

        expect(project_setting).not_to be_valid
        expect(project_setting.errors.full_messages).to include("Pages unique domain can't be blank")
      end

      it "is required if it is already saved in the database" do
        project_setting = create(
          :project_setting,
          pages_unique_domain: "random-unique-domain-here",
          pages_unique_domain_enabled: true
        )

        project_setting.pages_unique_domain = nil

        expect(project_setting).not_to be_valid
        expect(project_setting.errors.full_messages).to include("Pages unique domain can't be blank")
      end
    end

    it "validates uniqueness of pages_unique_domain", feature_category: :pages do
      create(:project_setting, pages_unique_domain: "random-unique-domain-here")

      project_setting = build(:project_setting, pages_unique_domain: "random-unique-domain-here")

      expect(project_setting).not_to be_valid
      expect(project_setting.errors.full_messages).to include("Pages unique domain has already been taken")
    end

    it "validates if the pages_unique_domain already exist as a project path" do
      stub_pages_setting(host: 'example.com')

      create(:project, path: "random-unique-domain.example.com")
      project_setting = build(:project_setting, pages_unique_domain: "random-unique-domain")

      expect(project_setting).not_to be_valid
      expect(project_setting.errors.full_messages_for(:pages_unique_domain))
        .to match(["Pages unique domain already in use"])
    end

    context "when updating" do
      it "validates if the pages_unique_domain already exist as a project path" do
        stub_pages_setting(host: 'example.com')
        project_setting = create(:project_setting)

        create(:project, path: "random-unique-domain.example.com")

        expect(project_setting.update(pages_unique_domain: "random-unique-domain")).to eq(false)
        expect(project_setting.errors.full_messages_for(:pages_unique_domain))
          .to match(["Pages unique domain already in use"])
      end
    end
  end

  describe 'target_platforms=' do
    it 'stringifies and sorts' do
      project_setting = build(:project_setting, target_platforms: [:watchos, :ios])
      expect(project_setting.target_platforms).to eq %w[ios watchos]
    end
  end

  it_behaves_like 'projects squash option'

  def valid_target_platform_combinations
    target_platforms = described_class::ALLOWED_TARGET_PLATFORMS

    0.upto(target_platforms.size).flat_map do |n|
      target_platforms.permutation(n).to_a
    end
  end

  describe '#show_diff_preview_in_email?' do
    context 'when a project has no parent group' do
      let(:project_settings) { create(:project_setting, show_diff_preview_in_email: false) }
      let(:project) { create(:project, project_setting: project_settings) }

      context 'when show_diff_preview_in_email is disabled' do
        it 'returns false' do
          expect(project).not_to be_show_diff_preview_in_email
        end
      end

      context 'when show_diff_preview_in_email is enabled' do
        let(:project_settings) { create(:project_setting, show_diff_preview_in_email: true) }

        it 'returns true' do
          settings = create(:project_setting, show_diff_preview_in_email: true)
          project = create(:project, project_setting: settings)

          expect(project).to be_show_diff_preview_in_email
        end
      end
    end

    context 'when a parent group overrides project settings' do
      let(:namespace_settings) { create(:namespace_settings, show_diff_preview_in_email: false) }
      let(:project_settings) { create(:project_setting, show_diff_preview_in_email: true) }
      let(:group) { create(:group, namespace_settings: namespace_settings) }
      let(:project) { create(:project, namespace_id: group.id, project_setting: project_settings) }

      context 'when show_diff_preview_in_email is disabled for the parent group' do
        it 'returns false' do
          expect(project).not_to be_show_diff_preview_in_email
        end
      end

      context 'when all ancestors have enabled diff previews' do
        let(:namespace_settings) { create(:namespace_settings, show_diff_preview_in_email: true) }

        it 'returns true' do
          expect(project).to be_show_diff_preview_in_email
        end
      end
    end
  end

  describe '#emails_enabled?' do
    context "when a project does not have a parent group" do
      let_it_be(:project_settings) { create(:project_setting, emails_enabled: true) }
      let_it_be(:project) { create(:project, project_setting: project_settings) }

      it "returns true" do
        expect(project.emails_enabled?).to be_truthy
      end

      it "returns false when project_settings are set to false" do
        project.project_setting.clear_memoization(:emails_enabled?)
        project.update_attribute(:emails_enabled, false)

        expect(project.emails_enabled?).to be_falsey
      end
    end

    context "when a project has a parent group" do
      let(:namespace_settings) { create(:namespace_settings, emails_enabled: true) }
      let(:project_settings) { create(:project_setting, emails_enabled: true) }
      let(:group) { create(:group, namespace_settings: namespace_settings) }
      let(:project) do
        create(:project, namespace_id: group.id,
          project_setting: project_settings)
      end

      context 'when emails have been disabled in parent group' do
        it 'returns false' do
          group.update_attribute(:emails_enabled, false)

          expect(project.emails_enabled?).to be_falsey
        end
      end

      context 'when emails are enabled in parent group' do
        before do
          allow(project.namespace).to receive(:emails_enabled?).and_return(true)
        end

        it 'returns true' do
          expect(project.emails_enabled?).to be_truthy
        end

        it 'returns false when disabled at the project' do
          project.update_attribute(:emails_enabled, false)

          expect(project.emails_enabled?).to be_falsey
        end
      end
    end
  end

  describe '#runner_registration_enabled' do
    let_it_be(:settings) { create(:project_setting) }
    let_it_be(:group) { create(:group) }
    let_it_be(:project) { create(:project, project_setting: settings, group: group) }

    it 'returns true' do
      expect(project.runner_registration_enabled).to eq true
    end

    context 'when project has runner registration disabled' do
      before do
        project.update!(runner_registration_enabled: false)
      end

      it 'returns false' do
        expect(project.runner_registration_enabled).to eq false
      end
    end

    context 'when all projects have runner registration disabled' do
      before do
        stub_application_setting(valid_runner_registrars: ['group'])
      end

      it 'returns false' do
        expect(project.runner_registration_enabled).to eq false
      end
    end
  end
end
