# frozen_string_literal: true

require 'spec_helper'

RSpec.describe CommitRange do
  let(:range2) { described_class.new("#{sha_from}..#{sha_to}", project) }
  let(:range)  { described_class.new("#{sha_from}...#{sha_to}", project) }
  let(:full_sha_to)   { commit2.id }
  let(:full_sha_from) { commit1.id }
  let(:sha_to)   { commit2.short_id }
  let(:sha_from) { commit1.short_id }
  let!(:commit2) { project.commit }
  let!(:commit1) { project.commit("HEAD~2") }
  let!(:project) { create(:project, :public, :repository) }

  describe 'modules' do
    subject { described_class }

    it { is_expected.to include_module(Referable) }
  end

  it 'raises ArgumentError when given an invalid range string' do
    expect { described_class.new("Foo", project) }.to raise_error(ArgumentError)
  end

  describe '#initialize' do
    it 'does not modify strings in-place' do
      input = "#{sha_from}...#{sha_to}   "

      described_class.new(input, project)

      expect(input).to eq("#{sha_from}...#{sha_to}   ")
    end
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
    let(:cross) { create(:project, namespace: project.namespace) }

    it 'returns a String reference to the object' do
      expect(range.to_reference).to eq "#{full_sha_from}...#{full_sha_to}"
    end

    it 'returns a String reference to the object' do
      expect(range2.to_reference).to eq "#{full_sha_from}..#{full_sha_to}"
    end

    it 'supports a cross-project reference' do
      expect(range.to_reference(cross)).to eq "#{project.path}@#{full_sha_from}...#{full_sha_to}"
    end
  end

  describe '#reference_link_text' do
    let(:cross) { create(:project, namespace: project.namespace) }

    it 'returns a String reference to the object' do
      expect(range.reference_link_text).to eq "#{sha_from}...#{sha_to}"
    end

    it 'returns a String reference to the object' do
      expect(range2.reference_link_text).to eq "#{sha_from}..#{sha_to}"
    end

    it 'supports a cross-project reference' do
      expect(range.reference_link_text(cross)).to eq "#{project.path}@#{sha_from}...#{sha_to}"
    end
  end

  describe '#to_param' do
    it 'includes the correct keys' do
      expect(range.to_param.keys).to eq %i[from to]
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
