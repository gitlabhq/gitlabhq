# frozen_string_literal: true

RSpec.shared_examples 'commit signature' do
  describe 'associations' do
    it { is_expected.to belong_to(:project).required }
  end

  describe 'validation' do
    subject { described_class.new }

    it { is_expected.to validate_presence_of(:commit_sha) }
    it { is_expected.to validate_presence_of(:project_id) }
  end

  describe '.safe_create!' do
    it 'finds a signature by commit sha if it existed' do
      signature

      expect(described_class.safe_create!(commit_sha: commit_sha)).to eq(signature)
    end

    it 'creates a new signature if it was not found' do
      expect { described_class.safe_create!(attributes) }.to change { described_class.count }.by(1)
    end

    it 'assigns the correct attributes when creating' do
      signature = described_class.safe_create!(attributes)

      expect(signature).to have_attributes(attributes)
    end

    it 'does not raise an error in case of a race condition' do
      expect(described_class).to receive(:find_by).and_return(nil, instance_double(described_class, persisted?: true))

      expect(described_class).to receive(:create).and_raise(ActiveRecord::RecordNotUnique)
      allow(described_class).to receive(:create).and_call_original

      described_class.safe_create!(attributes)
    end
  end

  describe '#commit' do
    it 'fetches the commit through the project' do
      expect_next_instance_of(Project) do |instance|
        expect(instance).to receive(:commit).with(commit_sha).and_return(commit)
      end

      signature.commit
    end
  end
end
