require 'spec_helper'

describe Gitlab::GithubImport::Importer::ReleasesImporter do
  let(:project) { create(:project) }
  let(:client) { double(:client) }
  let(:importer) { described_class.new(project, client) }
  let(:created_at) { Time.new(2017, 1, 1, 12, 00) }
  let(:updated_at) { Time.new(2017, 1, 1, 12, 15) }

  let(:release) do
    double(
      :release,
      tag_name: '1.0',
      body: 'This is my release',
      created_at: created_at,
      updated_at: updated_at
    )
  end

  describe '#execute' do
    it 'imports the releases in bulk' do
      release_hash = {
        tag_name: '1.0',
        description: 'This is my release',
        created_at: created_at,
        updated_at: updated_at
      }

      expect(importer).to receive(:build_releases).and_return([release_hash])
      expect(importer).to receive(:bulk_insert).with(Release, [release_hash])

      importer.execute
    end
  end

  describe '#build_releases' do
    it 'returns an Array containnig release rows' do
      expect(importer).to receive(:each_release).and_return([release])

      rows = importer.build_releases

      expect(rows.length).to eq(1)
      expect(rows[0][:tag]).to eq('1.0')
    end

    it 'does not create releases that already exist' do
      create(:release, project: project, tag: '1.0', description: '1.0')

      expect(importer).to receive(:each_release).and_return([release])
      expect(importer.build_releases).to be_empty
    end

    it 'uses a default release description if none is provided' do
      expect(release).to receive(:body).and_return('')
      expect(importer).to receive(:each_release).and_return([release])

      release = importer.build_releases.first

      expect(release[:description]).to eq('Release for tag 1.0')
    end
  end

  describe '#build' do
    let(:release_hash) { importer.build(release) }

    it 'returns the attributes of the release as a Hash' do
      expect(release_hash).to be_an_instance_of(Hash)
    end

    context 'the returned Hash' do
      it 'includes the tag name' do
        expect(release_hash[:tag]).to eq('1.0')
      end

      it 'includes the release description' do
        expect(release_hash[:description]).to eq('This is my release')
      end

      it 'includes the project ID' do
        expect(release_hash[:project_id]).to eq(project.id)
      end

      it 'includes the created timestamp' do
        expect(release_hash[:created_at]).to eq(created_at)
      end

      it 'includes the updated timestamp' do
        expect(release_hash[:updated_at]).to eq(updated_at)
      end
    end
  end

  describe '#each_release' do
    let(:release) { double(:release) }

    before do
      allow(project).to receive(:import_source).and_return('foo/bar')

      allow(client)
        .to receive(:releases)
        .with('foo/bar')
        .and_return([release].to_enum)
    end

    it 'returns an Enumerator' do
      expect(importer.each_release).to be_an_instance_of(Enumerator)
    end

    it 'yields every release to the Enumerator' do
      expect(importer.each_release.next).to eq(release)
    end
  end

  describe '#description_for' do
    it 'returns the description when present' do
      expect(importer.description_for(release)).to eq(release.body)
    end

    it 'returns a generated description when one is not present' do
      allow(release).to receive(:body).and_return('')

      expect(importer.description_for(release)).to eq('Release for tag 1.0')
    end
  end
end
