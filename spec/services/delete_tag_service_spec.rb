require 'spec_helper'

describe DeleteTagService, services: true do
  let(:project) { create(:project) }
  let(:repository) { project.repository }
  let(:user) { create(:user) }
  let(:service) { described_class.new(project, user) }

  let(:tag) { double(:tag, name: '8.5', target: 'abc123') }

  describe '#execute' do
    before do
      allow(repository).to receive(:find_tag).and_return(tag)
    end

    it 'removes the tag' do
      expect_any_instance_of(Gitlab::Shell).to receive(:rm_tag).
        and_return(true)

      expect(repository).to receive(:before_remove_tag)
      expect(service).to receive(:success)

      service.execute('8.5')
    end
  end
end
