# frozen_string_literal: true

shared_examples 'a repo type' do
  describe "#identifier_for_subject" do
    subject { described_class.identifier_for_subject(project) }

    it { is_expected.to eq(expected_identifier) }
  end

  describe "#fetch_id" do
    it "finds an id match in the identifier" do
      expect(described_class.fetch_id(expected_identifier)).to eq(expected_id)
    end

    it 'does not break on other identifiers' do
      expect(described_class.fetch_id("wiki-noid")).to eq(nil)
    end
  end

  describe "#path_suffix" do
    subject { described_class.path_suffix }

    it { is_expected.to eq(expected_suffix) }
  end

  describe "#repository_for" do
    it "finds the repository for the repo type" do
      expect(described_class.repository_for(project)).to eq(expected_repository)
    end
  end
end
