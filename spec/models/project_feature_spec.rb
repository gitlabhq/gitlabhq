# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ProjectFeature, feature_category: :groups_and_projects do
  using RSpec::Parameterized::TableSyntax

  let_it_be_with_reload(:project) { create(:project) }
  let_it_be(:user) { create(:user) }

  it { is_expected.to belong_to(:project) }

  describe 'default values' do
    subject { Project.new.project_feature }

    specify { expect(subject.builds_access_level).to eq(ProjectFeature::ENABLED) }
    specify { expect(subject.issues_access_level).to eq(ProjectFeature::ENABLED) }
    specify { expect(subject.forking_access_level).to eq(ProjectFeature::ENABLED) }
    specify { expect(subject.merge_requests_access_level).to eq(ProjectFeature::ENABLED) }
    specify { expect(subject.snippets_access_level).to eq(ProjectFeature::ENABLED) }
    specify { expect(subject.wiki_access_level).to eq(ProjectFeature::ENABLED) }
    specify { expect(subject.repository_access_level).to eq(ProjectFeature::ENABLED) }
    specify { expect(subject.metrics_dashboard_access_level).to eq(ProjectFeature::PRIVATE) }
    specify { expect(subject.operations_access_level).to eq(ProjectFeature::ENABLED) }
    specify { expect(subject.security_and_compliance_access_level).to eq(ProjectFeature::PRIVATE) }
    specify { expect(subject.monitor_access_level).to eq(ProjectFeature::ENABLED) }
    specify { expect(subject.infrastructure_access_level).to eq(ProjectFeature::ENABLED) }
    specify { expect(subject.feature_flags_access_level).to eq(ProjectFeature::ENABLED) }
    specify { expect(subject.environments_access_level).to eq(ProjectFeature::ENABLED) }
    specify { expect(subject.releases_access_level).to eq(ProjectFeature::ENABLED) }
    specify { expect(subject.package_registry_access_level).to eq(ProjectFeature::ENABLED) }
    specify { expect(subject.container_registry_access_level).to eq(ProjectFeature::ENABLED) }
    specify { expect(subject.model_experiments_access_level).to eq(ProjectFeature::ENABLED) }
    specify { expect(subject.model_registry_access_level).to eq(ProjectFeature::ENABLED) }
  end

  describe 'PRIVATE_FEATURES_MIN_ACCESS_LEVEL_FOR_PRIVATE_PROJECT' do
    it 'has higher level than that of PRIVATE_FEATURES_MIN_ACCESS_LEVEL' do
      described_class::PRIVATE_FEATURES_MIN_ACCESS_LEVEL_FOR_PRIVATE_PROJECT.each do |feature, level|
        if generic_level = described_class::PRIVATE_FEATURES_MIN_ACCESS_LEVEL[feature]
          expect(level).to be >= generic_level
        end
      end
    end
  end

  context 'repository related features' do
    before do
      project.project_feature.update!(
        merge_requests_access_level: ProjectFeature::DISABLED,
        builds_access_level: ProjectFeature::DISABLED,
        repository_access_level: ProjectFeature::PRIVATE
      )
    end

    it "does not allow repository related features have higher level" do
      features = %w[builds merge_requests]
      project_feature = project.project_feature

      features.each do |feature|
        field = "#{feature}_access_level".to_sym
        project_feature.update_attribute(field, ProjectFeature::ENABLED)
        expect(project_feature.valid?).to be_falsy, "#{field} failed"
      end
    end
  end

  it_behaves_like 'access level validation', ProjectFeature::FEATURES - %i[pages package_registry] do
    let(:container_features) { project.project_feature }
  end

  it 'allows public access level for :pages feature' do
    project_feature = project.project_feature
    project_feature.pages_access_level = ProjectFeature::PUBLIC

    expect(project_feature.valid?).to be_truthy
  end

  describe 'default pages access level' do
    subject { project_feature.pages_access_level }

    let(:project_feature) do
      # project factory overrides all values in project_feature after creation
      project.project_feature.destroy!
      project.build_project_feature.save!
      project.project_feature
    end

    context 'when new project is private' do
      let(:project) { create(:project, :private) }

      it { is_expected.to eq(ProjectFeature::PRIVATE) }
    end

    context 'when new project is internal' do
      let(:project) { create(:project, :internal) }

      it { is_expected.to eq(ProjectFeature::PRIVATE) }
    end

    context 'when new project is public' do
      let(:project) { create(:project, :public) }

      it { is_expected.to eq(ProjectFeature::ENABLED) }

      context 'when access control is forced on the admin level' do
        before do
          allow(::Gitlab::Pages).to receive(:access_control_is_forced?).and_return(true)
        end

        it { is_expected.to eq(ProjectFeature::PRIVATE) }
      end
    end
  end

  describe '#public_pages?' do
    it 'returns true if Pages access control is not enabled' do
      stub_config(pages: { access_control: false })

      project_feature = described_class.new(pages_access_level: described_class::PRIVATE)

      expect(project_feature.public_pages?).to eq(true)
    end

    context 'when Pages access control is enabled' do
      before do
        stub_config(pages: { access_control: true })
      end

      where(:project_visibility, :pages_access_level, :result) do
        :private  | ProjectFeature::PUBLIC  | true
        :internal | ProjectFeature::PUBLIC  | true
        :internal | ProjectFeature::ENABLED | false
        :public   | ProjectFeature::ENABLED | true
        :private  | ProjectFeature::PRIVATE | false
        :public   | ProjectFeature::PRIVATE | false
      end

      with_them do
        let(:project_feature) do
          project = build(:project, project_visibility)
          project_feature = project.project_feature
          project_feature.update!(pages_access_level: pages_access_level)
          project_feature
        end

        it 'properly handles project and Pages visibility settings' do
          expect(project_feature.public_pages?).to eq(result)
        end

        it 'returns false if access_control is forced on the admin level' do
          stub_application_setting(force_pages_access_control: true)

          expect(project_feature.public_pages?).to eq(false)
        end
      end
    end
  end

  describe '#private_pages?' do
    subject(:project_feature) { described_class.new }

    it 'returns false if public_pages? is true' do
      expect(project_feature).to receive(:public_pages?).and_return(true)

      expect(project_feature.private_pages?).to eq(false)
    end

    it 'returns true if public_pages? is false' do
      expect(project_feature).to receive(:public_pages?).and_return(false)

      expect(project_feature.private_pages?).to eq(true)
    end
  end

  describe '.required_minimum_access_level' do
    it 'handles reporter level' do
      expect(described_class.required_minimum_access_level(:merge_requests)).to eq(Gitlab::Access::REPORTER)
    end

    it 'handles guest level' do
      expect(described_class.required_minimum_access_level(:issues)).to eq(Gitlab::Access::GUEST)
    end

    it 'accepts ActiveModel' do
      expect(described_class.required_minimum_access_level(MergeRequest)).to eq(Gitlab::Access::REPORTER)
    end

    it 'accepts string' do
      expect(described_class.required_minimum_access_level('merge_requests')).to eq(Gitlab::Access::REPORTER)
    end

    it 'handles repository' do
      expect(described_class.required_minimum_access_level(:repository)).to eq(Gitlab::Access::GUEST)
    end

    it 'handles package registry' do
      expect(described_class.required_minimum_access_level(:package_registry)).to eq(Gitlab::Access::REPORTER)
    end

    it 'raises error if feature is invalid' do
      expect do
        described_class.required_minimum_access_level(:foos)
      end.to raise_error(ArgumentError)
    end
  end

  describe '.required_minimum_access_level_for_private_project' do
    it 'returns higher permission for repository' do
      expect(described_class.required_minimum_access_level_for_private_project(:repository)).to eq(Gitlab::Access::REPORTER)
    end

    it 'returns normal permission for issues' do
      expect(described_class.required_minimum_access_level_for_private_project(:issues)).to eq(Gitlab::Access::GUEST)
    end
  end

  describe 'container_registry_access_level' do
    context 'with default value' do
      let(:project) { Project.new }

      context 'when the default is false' do
        it 'creates project_feature with `disabled` container_registry_access_level' do
          stub_config_setting(default_projects_features: { container_registry: false })

          expect(project.project_feature.container_registry_access_level).to eq(described_class::DISABLED)
        end
      end

      context 'when the default is true' do
        before do
          stub_config_setting(default_projects_features: { container_registry: true })
        end

        it 'creates project_feature with `enabled` container_registry_access_level' do
          expect(project.project_feature.container_registry_access_level).to eq(described_class::ENABLED)
        end
      end

      context 'when the default is nil' do
        it 'creates project_feature with `disabled` container_registry_access_level' do
          stub_config_setting(default_projects_features: { container_registry: nil })

          expect(project.project_feature.container_registry_access_level).to eq(described_class::DISABLED)
        end
      end
    end

    context 'test build factory' do
      let(:project) { build(:project, container_registry_access_level: level) }

      subject { project.container_registry_access_level }

      context 'private' do
        let(:level) { ProjectFeature::PRIVATE }

        it { is_expected.to eq(level) }
      end

      context 'enabled' do
        let(:level) { ProjectFeature::ENABLED }

        it { is_expected.to eq(level) }
      end

      context 'disabled' do
        let(:level) { ProjectFeature::DISABLED }

        it { is_expected.to eq(level) }
      end
    end
  end

  describe 'package_registry_access_level' do
    context 'with default value' do
      where(:config_packages_enabled, :expected_result) do
        false | ProjectFeature::DISABLED
        true  | ProjectFeature::ENABLED
        nil   | ProjectFeature::DISABLED
      end

      with_them do
        it 'creates project_feature with correct package_registry_access_level' do
          stub_packages_setting(enabled: config_packages_enabled)
          project = Project.new

          expect(project.project_feature.package_registry_access_level).to eq(expected_result)
        end
      end
    end

    context 'sync packages_enabled' do
      where(:initial_value, :new_value, :expected_result) do
        ProjectFeature::DISABLED | ProjectFeature::DISABLED | false
        ProjectFeature::DISABLED | ProjectFeature::ENABLED  | true
        ProjectFeature::DISABLED | ProjectFeature::PUBLIC   | true
        ProjectFeature::ENABLED  | ProjectFeature::DISABLED | false
        ProjectFeature::ENABLED  | ProjectFeature::ENABLED  | true
        ProjectFeature::ENABLED  | ProjectFeature::PUBLIC   | true
        ProjectFeature::PUBLIC   | ProjectFeature::DISABLED | false
        ProjectFeature::PUBLIC   | ProjectFeature::ENABLED  | true
        ProjectFeature::PUBLIC   | ProjectFeature::PUBLIC   | true
      end

      with_them do
        it 'set correct value' do
          project = create(:project, package_registry_access_level: initial_value)

          project.project_feature.update!(package_registry_access_level: new_value)

          expect(project.packages_enabled).to eq(expected_result)
        end
      end
    end
  end

  describe '#public_packages?' do
    let_it_be(:public_project) { create(:project, :public) }

    context 'with packages config enabled' do
      context 'when project is private' do
        it 'returns false' do
          expect(project.project_feature.public_packages?).to eq(false)
        end

        context 'with package_registry_access_level set to public' do
          before do
            project.project_feature.update!(package_registry_access_level: ProjectFeature::PUBLIC)
          end

          it 'returns true' do
            expect(project.project_feature.public_packages?).to eq(true)
          end
        end
      end

      context 'when project is public' do
        it 'returns true' do
          expect(public_project.project_feature.public_packages?).to eq(true)
        end
      end
    end

    it 'returns false if packages config is not enabled' do
      stub_config(packages: { enabled: false })

      expect(public_project.project_feature.public_packages?).to eq(false)
    end
  end

  # rubocop:disable Gitlab/FeatureAvailableUsage
  describe '#feature_available?' do
    let(:features) { ProjectFeature::FEATURES }

    context 'when features are disabled' do
      it 'returns false' do
        update_all_project_features(project, features, ProjectFeature::DISABLED)

        features.each do |feature|
          expect(project.feature_available?(feature.to_sym, user)).to eq(false), "#{feature} failed"
        end
      end
    end

    context 'when features are enabled only for team members' do
      it 'returns false when user is not a team member' do
        update_all_project_features(project, features, ProjectFeature::PRIVATE)

        features.each do |feature|
          expect(project.feature_available?(feature.to_sym, user)).to eq(false), "#{feature} failed"
        end
      end

      it 'returns true when user is a team member' do
        project.add_developer(user)

        update_all_project_features(project, features, ProjectFeature::PRIVATE)

        features.each do |feature|
          expect(project.feature_available?(feature.to_sym, user)).to eq(true)
        end
      end

      it 'returns true when user is a member of project group' do
        group = create(:group)
        project = create(:project, namespace: group)
        group.add_developer(user)

        update_all_project_features(project, features, ProjectFeature::PRIVATE)

        features.each do |feature|
          expect(project.feature_available?(feature.to_sym, user)).to eq(true)
        end
      end

      context 'when admin mode is enabled', :enable_admin_mode do
        it 'returns true if user is an admin' do
          user.update_attribute(:admin, true)

          update_all_project_features(project, features, ProjectFeature::PRIVATE)

          features.each do |feature|
            expect(project.feature_available?(feature.to_sym, user)).to eq(true)
          end
        end
      end

      context 'when admin mode is disabled' do
        it 'returns false when user is an admin' do
          user.update_attribute(:admin, true)

          update_all_project_features(project, features, ProjectFeature::PRIVATE)

          features.each do |feature|
            expect(project.feature_available?(feature.to_sym, user)).to eq(false), "#{feature} failed"
          end
        end
      end
    end

    context 'when feature is enabled for everyone' do
      it 'returns true' do
        expect(project.feature_available?(:issues, user)).to eq(true)
      end
    end

    context 'when feature has any other value' do
      it 'returns true' do
        project.project_feature.update_attribute(:issues_access_level, 200)

        expect(project.feature_available?(:issues)).to eq(true)
      end
    end

    def update_all_project_features(project, features, value)
      project_feature_attributes = features.to_h { |f| ["#{f}_access_level", value] }
      project.project_feature.update!(project_feature_attributes)
    end
  end
  # rubocop:enable Gitlab/FeatureAvailableUsage

  describe '#private?' do
    where(:merge_requests_access_level, :expected_value) do
      ProjectFeature::PUBLIC  | false
      ProjectFeature::ENABLED | false
      ProjectFeature::PRIVATE | true
    end

    with_them do
      let(:project) { build_stubbed(:project) }

      subject { project.project_feature.private?(:merge_requests) }

      before do
        project.project_feature.merge_requests_access_level = merge_requests_access_level
      end

      it { is_expected.to be(expected_value) }
    end
  end
end
