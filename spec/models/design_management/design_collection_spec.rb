# frozen_string_literal: true
require 'spec_helper'

describe DesignManagement::DesignCollection do
  include DesignManagementTestHelpers

  let_it_be(:issue, reload: true) { create(:issue) }

  subject(:collection) { described_class.new(issue) }

  describe ".find_or_create_design!" do
    it "finds an existing design" do
      design = create(:design, issue: issue, filename: 'world.png')

      expect(collection.find_or_create_design!(filename: 'world.png')).to eq(design)
    end

    it "creates a new design if one didn't exist" do
      expect(issue.designs.size).to eq(0)

      new_design = collection.find_or_create_design!(filename: 'world.png')

      expect(issue.designs.size).to eq(1)
      expect(new_design.filename).to eq('world.png')
      expect(new_design.issue).to eq(issue)
    end

    it "only queries the designs once" do
      create(:design, issue: issue, filename: 'hello.png')
      create(:design, issue: issue, filename: 'world.jpg')

      expect do
        collection.find_or_create_design!(filename: 'hello.png')
        collection.find_or_create_design!(filename: 'world.jpg')
      end.not_to exceed_query_limit(1)
    end
  end

  describe "#versions" do
    it "includes versions for all designs" do
      version_1 = create(:design_version)
      version_2 = create(:design_version)
      other_version = create(:design_version)
      create(:design, issue: issue, versions: [version_1])
      create(:design, issue: issue, versions: [version_2])
      create(:design, versions: [other_version])

      expect(collection.versions).to contain_exactly(version_1, version_2)
    end
  end

  describe "#repository" do
    it "builds a design repository" do
      expect(collection.repository).to be_a(DesignManagement::Repository)
    end
  end

  describe '#designs_by_filename' do
    let(:designs) { create_list(:design, 5, :with_file, issue: issue) }
    let(:filenames) { designs.map(&:filename) }
    let(:query) { subject.designs_by_filename(filenames) }

    it 'finds all the designs with those filenames on this issue' do
      expect(query).to have_attributes(size: 5)
    end

    it 'only makes a single query' do
      designs.each(&:id)
      expect { query }.not_to exceed_query_limit(1)
    end

    context 'some are deleted' do
      before do
        delete_designs(*designs.sample(2))
      end

      it 'takes deletion into account' do
        expect(query).to have_attributes(size: 3)
      end
    end
  end
end
