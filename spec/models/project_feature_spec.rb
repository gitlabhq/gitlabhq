# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ProjectFeature do
  using RSpec::Parameterized::TableSyntax

  let(:project) { create(:project) }
  let(:user) { create(:user) }

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
      features = %w(builds merge_requests)
      project_feature = project.project_feature

      features.each do |feature|
        field = "#{feature}_access_level".to_sym
        project_feature.update_attribute(field, ProjectFeature::ENABLED)
        expect(project_feature.valid?).to be_falsy, "#{field} failed"
      end
    end
  end

  context 'public features' do
    features = ProjectFeature::FEATURES - %i(pages)

    features.each do |feature|
      it "does not allow public access level for #{feature}" do
        project_feature = project.project_feature
        field = "#{feature}_access_level".to_sym
        project_feature.update_attribute(field, ProjectFeature::PUBLIC)

        expect(project_feature.valid?).to be_falsy, "#{field} failed"
      end
    end
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
    context 'when the project is created with container_registry_enabled false' do
      it 'creates project with DISABLED container_registry_access_level' do
        project = create(:project, container_registry_enabled: false)

        expect(project.project_feature.container_registry_access_level).to eq(described_class::DISABLED)
      end
    end

    context 'when the project is created with container_registry_enabled true' do
      it 'creates project with ENABLED container_registry_access_level' do
        project = create(:project, container_registry_enabled: true)

        expect(project.project_feature.container_registry_access_level).to eq(described_class::ENABLED)
      end
    end

    context 'when the project is created with container_registry_enabled nil' do
      it 'creates project with DISABLED container_registry_access_level' do
        project = create(:project, container_registry_enabled: nil)

        expect(project.project_feature.container_registry_access_level).to eq(described_class::DISABLED)
      end
    end
  end
end
