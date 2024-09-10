# frozen_string_literal: true

RSpec.shared_examples 'project cache control headers' do
  before do
    project.update!(visibility_level: visibility_level)
  end

  context 'when project is public' do
    let(:visibility_level) { Gitlab::VisibilityLevel::PUBLIC }

    it 'returns cache_control public header to true' do
      subject

      expect(response.cache_control[:public]).to be_truthy
    end
  end

  context 'when project is private' do
    let(:visibility_level) { Gitlab::VisibilityLevel::PRIVATE }

    it 'returns cache_control public header to false' do
      subject

      expect(response.cache_control[:public]).to be_falsey
    end
  end

  context 'when project is internal' do
    let(:visibility_level) { Gitlab::VisibilityLevel::INTERNAL }

    it 'returns cache_control public header to false' do
      subject

      expect(response.cache_control[:public]).to be_falsey
    end
  end
end
