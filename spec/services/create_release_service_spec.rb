require 'spec_helper'

describe CreateReleaseService do
  let(:project) { create(:project, :repository) }
  let(:user) { create(:user) }
  let(:tag_name) { project.repository.tag_names.first }
  let(:description) { 'Awesome release!' }
  let(:service) { described_class.new(project, user) }

  it 'creates a new release' do
    result = service.execute(tag_name, description)
    expect(result[:status]).to eq(:success)
    release = project.releases.find_by(tag: tag_name)
    expect(release).not_to be_nil
    expect(release.description).to eq(description)
  end

  it 'raises an error if the tag does not exist' do
    result = service.execute("foobar", description)
    expect(result[:status]).to eq(:error)
  end

  context 'there already exists a release on a tag' do
    before do
      service.execute(tag_name, description)
    end

    it 'raises an error and does not update the release' do
      result = service.execute(tag_name, 'The best release!')
      expect(result[:status]).to eq(:error)
      expect(project.releases.find_by(tag: tag_name).description).to eq(description)
    end
  end
end
