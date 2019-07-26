require 'spec_helper'

describe Gitlab::ManifestImport::ProjectCreator do
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
  end

  subject { described_class.new(repository, group, user) }

  describe '#execute' do
    it { expect(subject.execute).to be_a(Project) }
    it { expect { subject.execute }.to change { Project.count }.by(1) }
    it { expect { subject.execute }.to change { Group.count }.by(1) }

    it 'creates project with valid full path and import url' do
      subject.execute

      project = Project.last

      expect(project.full_path).to eq(File.join(group.path, 'device/common'))
      expect(project.import_url).to eq('https://android-review.googlesource.com/device/common')
    end
  end
end
