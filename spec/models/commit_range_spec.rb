require 'spec_helper'

describe CommitRange do
  describe 'modules' do
    subject { described_class }

    it { is_expected.to include_module(Referable) }
  end

  let(:sha_from) { 'f3f85602' }
  let(:sha_to)   { 'e86e1013' }

  let(:range)  { described_class.new("#{sha_from}...#{sha_to}") }
  let(:range2) { described_class.new("#{sha_from}..#{sha_to}") }

  it 'raises ArgumentError when given an invalid range string' do
    expect { described_class.new("Foo") }.to raise_error(ArgumentError)
  end

  describe '#to_s' do
    it 'is correct for three-dot syntax' do
      expect(range.to_s).to eq "#{sha_from[0..7]}...#{sha_to[0..7]}"
    end

    it 'is correct for two-dot syntax' do
      expect(range2.to_s).to eq "#{sha_from[0..7]}..#{sha_to[0..7]}"
    end
  end

  describe '#to_reference' do
    let(:project) { double('project', to_reference: 'namespace1/project') }

    before do
      range.project = project
    end

    it 'returns a String reference to the object' do
      expect(range.to_reference).to eq range.to_s
    end

    it 'supports a cross-project reference' do
      cross = double('project')
      expect(range.to_reference(cross)).to eq "#{project.to_reference}@#{range.to_s}"
    end
  end

  describe '#reference_title' do
    it 'returns the correct String for three-dot ranges' do
      expect(range.reference_title).to eq "Commits #{sha_from} through #{sha_to}"
    end

    it 'returns the correct String for two-dot ranges' do
      expect(range2.reference_title).to eq "Commits #{sha_from}^ through #{sha_to}"
    end
  end

  describe '#to_param' do
    it 'includes the correct keys' do
      expect(range.to_param.keys).to eq %i(from to)
    end

    it 'includes the correct values for a three-dot range' do
      expect(range.to_param).to eq({ from: sha_from, to: sha_to })
    end

    it 'includes the correct values for a two-dot range' do
      expect(range2.to_param).to eq({ from: sha_from + '^', to: sha_to })
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
    context 'without a project' do
      it 'returns nil' do
        expect(range.valid_commits?).to be_nil
      end
    end

    it 'accepts an optional project argument' do
      project1 = double('project1').as_null_object
      project2 = double('project2').as_null_object

      # project1 gets assigned through the accessor, but ignored when not given
      # as an argument to `valid_commits?`
      expect(project1).not_to receive(:present?)
      range.project = project1

      # project2 gets passed to `valid_commits?`
      expect(project2).to receive(:present?).and_return(false)

      range.valid_commits?(project2)
    end

    context 'with a project' do
      let(:project) { double('project', repository: double('repository')) }

      context 'with a valid repo' do
        before do
          expect(project).to receive(:valid_repo?).and_return(true)
          range.project = project
        end

        it 'is false when `sha_from` is invalid' do
          expect(project.repository).to receive(:commit).with(sha_from).and_return(false)
          expect(project.repository).not_to receive(:commit).with(sha_to)
          expect(range).not_to be_valid_commits
        end

        it 'is false when `sha_to` is invalid' do
          expect(project.repository).to receive(:commit).with(sha_from).and_return(true)
          expect(project.repository).to receive(:commit).with(sha_to).and_return(false)
          expect(range).not_to be_valid_commits
        end

        it 'is true when both `sha_from` and `sha_to` are valid' do
          expect(project.repository).to receive(:commit).with(sha_from).and_return(true)
          expect(project.repository).to receive(:commit).with(sha_to).and_return(true)
          expect(range).to be_valid_commits
        end
      end

      context 'without a valid repo' do
        before do
          expect(project).to receive(:valid_repo?).and_return(false)
          range.project = project
        end

        it 'returns false' do
          expect(range).not_to be_valid_commits
        end
      end
    end
  end
end
