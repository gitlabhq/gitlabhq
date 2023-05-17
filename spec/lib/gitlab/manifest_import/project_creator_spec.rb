# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::ManifestImport::ProjectCreator, feature_category: :importers do
  let(:group) { create(:group) }
  let(:user) { create(:user) }
  let(:repository) do
    {
      path: 'device/common',
      url: 'https://android-review.googlesource.com/device/common'
    }
  end

  before do
    group.add_owner(user)

    stub_application_setting(import_sources: ['manifest'])
  end

  subject { described_class.new(repository, group, user) }

  describe '#execute' do
    it { expect(subject.execute).to be_a(Project) }
    it { expect { subject.execute }.to change { Project.count }.by(1) }
    it { expect { subject.execute }.to change { Group.count }.by(1) }

    it 'creates project with valid full path, import url and import source' do
      subject.execute

      project = Project.last

      expect(project.full_path).to eq(File.join(group.path, 'device/common'))
      expect(project.import_url).to eq('https://android-review.googlesource.com/device/common')
      expect(project.import_source).to eq('https://android-review.googlesource.com/device/common')
    end
  end
end
