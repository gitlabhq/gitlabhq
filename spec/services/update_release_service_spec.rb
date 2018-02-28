require 'spec_helper'

describe UpdateReleaseService do
  let(:project) { create(:project, :repository) }
  let(:user) { create(:user) }
  let(:tag_name) { project.repository.tag_names.first }
  let(:description) { 'Awesome release!' }
  let(:new_description) { 'The best release!' }
  let(:service) { described_class.new(project, user) }

  context 'with an existing release' do
    let(:create_service) { CreateReleaseService.new(project, user) }

    before do
      create_service.execute(tag_name, description)
    end

    it 'successfully updates an existing release' do
      result = service.execute(tag_name, new_description)
      expect(result[:status]).to eq(:success)
      expect(project.releases.find_by(tag: tag_name).description).to eq(new_description)
    end
  end

  it 'raises an error if the tag does not exist' do
    result = service.execute("foobar", description)
    expect(result[:status]).to eq(:error)
  end

  it 'raises an error if the release does not exist' do
    result = service.execute(tag_name, description)
    expect(result[:status]).to eq(:error)
  end
end
