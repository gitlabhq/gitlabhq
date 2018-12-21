require 'spec_helper'

describe CreateReleaseService do
  let(:project) { create(:project, :repository) }
  let(:user) { create(:user) }
  let(:tag_name) { project.repository.tag_names.first }
  let(:name) { 'Bionic Beaver'}
  let(:description) { 'Awesome release!' }
  let(:params) { { tag: tag_name, name: name, description: description } }
  let(:service) { described_class.new(project, user, params) }
  let(:ref) { nil }

  before do
    project.add_maintainer(user)
  end

  shared_examples 'a successful release creation' do
    it 'creates a new release' do
      result = service.execute(ref)
      expect(result[:status]).to eq(:success)
      release = project.releases.find_by(tag: tag_name)
      expect(release).not_to be_nil
      expect(release.description).to eq(description)
      expect(release.name).to eq(name)
      expect(release.author).to eq(user)
    end
  end

  it_behaves_like 'a successful release creation'

  it 'raises an error if the tag does not exist' do
    service.params[:tag] = 'foobar'

    result = service.execute
    expect(result[:status]).to eq(:error)
  end

  it 'keeps track of the commit sha' do
    tag = project.repository.find_tag(tag_name)
    sha = tag.dereferenced_target.sha
    result = service.execute

    expect(result[:status]).to eq(:success)
    expect(project.releases.find_by(tag: tag_name).sha).to eq(sha)
  end

  context 'when ref is provided' do
    let(:ref) { 'master' }
    let(:tag_name) { 'foobar' }

    it_behaves_like 'a successful release creation'

    it 'creates a tag if the tag does not exist' do
      expect(project.repository.ref_exists?("refs/tags/#{tag_name}")).to be_falsey

      result = service.execute(ref)
      expect(result[:status]).to eq(:success)
      expect(project.repository.ref_exists?("refs/tags/#{tag_name}")).to be_truthy

      release = project.releases.find_by(tag: tag_name)
      expect(release).not_to be_nil
    end
  end

  context 'there already exists a release on a tag' do
    before do
      service.execute
    end

    it 'raises an error and does not update the release' do
      service.params[:description] = 'The best release!'

      result = service.execute
      expect(result[:status]).to eq(:error)
      expect(project.releases.find_by(tag: tag_name).description).to eq(description)
    end
  end
end
