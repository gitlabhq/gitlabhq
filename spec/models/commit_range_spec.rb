require 'spec_helper'

describe CommitRange, models: true do
  describe 'modules' do
    subject { described_class }

    it { is_expected.to include_module(Referable) }
  end

  let!(:project) { create(:project, :public) }
  let!(:commit1) { project.commit("HEAD~2") }
  let!(:commit2) { project.commit }

  let(:sha_from) { commit1.short_id }
  let(:sha_to)   { commit2.short_id }

  let(:full_sha_from) { commit1.id }
  let(:full_sha_to)   { commit2.id }

  let(:range)  { described_class.new("#{sha_from}...#{sha_to}", project) }
  let(:range2) { described_class.new("#{sha_from}..#{sha_to}", project) }

  it 'raises ArgumentError when given an invalid range string' do
    expect { described_class.new("Foo", project) }.to raise_error(ArgumentError)
  end

  describe '#to_s' do
    it 'is correct for three-dot syntax' do
      expect(range.to_s).to eq "#{full_sha_from}...#{full_sha_to}"
    end

    it 'is correct for two-dot syntax' do
      expect(range2.to_s).to eq "#{full_sha_from}..#{full_sha_to}"
    end
  end

  describe '#to_reference' do
    let(:cross) { create(:project) }

    it 'returns a String reference to the object' do
      expect(range.to_reference).to eq "#{full_sha_from}...#{full_sha_to}"
    end

    it 'returns a String reference to the object' do
      expect(range2.to_reference).to eq "#{full_sha_from}..#{full_sha_to}"
    end

    it 'supports a cross-project reference' do
      expect(range.to_reference(cross)).to eq "#{project.to_reference}@#{full_sha_from}...#{full_sha_to}"
    end
  end

  describe '#reference_link_text' do
    let(:cross) { create(:project) }

    it 'returns a String reference to the object' do
      expect(range.reference_link_text).to eq "#{sha_from}...#{sha_to}"
    end

    it 'returns a String reference to the object' do
      expect(range2.reference_link_text).to eq "#{sha_from}..#{sha_to}"
    end

    it 'supports a cross-project reference' do
      expect(range.reference_link_text(cross)).to eq "#{project.to_reference}@#{sha_from}...#{sha_to}"
    end
  end

  describe '#reference_title' do
    it 'returns the correct String for three-dot ranges' do
      expect(range.reference_title).to eq "Commits #{full_sha_from} through #{full_sha_to}"
    end

    it 'returns the correct String for two-dot ranges' do
      expect(range2.reference_title).to eq "Commits #{full_sha_from}^ through #{full_sha_to}"
    end
  end

  describe '#to_param' do
    it 'includes the correct keys' do
      expect(range.to_param.keys).to eq %i(from to)
    end

    it 'includes the correct values for a three-dot range' do
      expect(range.to_param).to eq({ from: full_sha_from, to: full_sha_to })
    end

    it 'includes the correct values for a two-dot range' do
      expect(range2.to_param).to eq({ from: full_sha_from + '^', to: full_sha_to })
    end
  end

  describe '#exclude_start?' do
    it 'is false for three-dot ranges' do
      expect(range.exclude_start?).to eq false
    end

    it 'is true for two-dot ranges' do
      expect(range2.exclude_start?).to eq true
    end
  end

  describe '#valid_commits?' do
    context 'with a valid repo' do
      before do
        expect(project).to receive(:valid_repo?).and_return(true)
      end

      it 'is false when `sha_from` is invalid' do
        expect(project).to receive(:commit).with(sha_from).and_return(nil)
        expect(project).to receive(:commit).with(sha_to).and_call_original

        expect(range).not_to be_valid_commits
      end

      it 'is false when `sha_to` is invalid' do
        expect(project).to receive(:commit).with(sha_from).and_call_original
        expect(project).to receive(:commit).with(sha_to).and_return(nil)

        expect(range).not_to be_valid_commits
      end

      it 'is true when both `sha_from` and `sha_to` are valid' do
        expect(range).to be_valid_commits
      end
    end

    context 'without a valid repo' do
      before do
        expect(project).to receive(:valid_repo?).and_return(false)
      end

      it 'returns false' do
        expect(range).not_to be_valid_commits
      end
    end
  end
end
