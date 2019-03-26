require 'spec_helper'

describe Tags::DestroyService do
  let(:project) { create(:project, :repository) }
  let(:repository) { project.repository }
  let(:user) { create(:user) }
  let(:service) { described_class.new(project, user) }

  describe '#execute' do
    subject { service.execute(tag_name) }

    it 'removes the tag' do
      expect(repository).to receive(:before_remove_tag)
      expect(service).to receive(:success)

      service.execute('v1.1.0')
    end

    context 'when there is an associated release on the tag' do
      let(:tag) { repository.tags.first }
      let(:tag_name) { tag.name }

      before do
        project.add_maintainer(user)
        create(:release, tag: tag_name, project: project)
      end

      it 'destroys the release' do
        expect { subject }.to change { project.releases.count }.by(-1)
      end
    end
  end
end
