# frozen_string_literal: true

RSpec.shared_examples 'can move repository storage' do
  let(:container) { raise NotImplementedError }
  let(:repository) { container.repository }

  describe '#set_repository_read_only!' do
    it 'makes the repository read-only' do
      expect { container.set_repository_read_only! }
        .to change { container.repository_read_only? }
        .from(false)
        .to(true)
    end

    it 'raises an error if the project is already read-only' do
      container.set_repository_read_only!

      expect { container.set_repository_read_only! }.to raise_error(described_class::RepositoryReadOnlyError, /already read-only/)
    end

    it 'raises an error when there is an existing git transfer in progress' do
      allow(container).to receive(:git_transfer_in_progress?) { true }

      expect { container.set_repository_read_only! }.to raise_error(described_class::RepositoryReadOnlyError, /in progress/)
    end

    context 'skip_git_transfer_check is true' do
      it 'makes the project read-only when git transfers are in progress' do
        allow(container).to receive(:git_transfer_in_progress?) { true }

        expect { container.set_repository_read_only!(skip_git_transfer_check: true) }
          .to change { container.repository_read_only? }
          .from(false)
          .to(true)
      end
    end
  end

  describe '#set_repository_writable!' do
    it 'sets repository_read_only to false' do
      expect { container.set_repository_writable! }
        .to change { container.repository_read_only? }
        .from(true).to(false)
    end

    it 'raises an error when the update fails' do
      expect(container).to receive(:update_repository_read_only_column).and_return(false)

      expect { container.set_repository_writable! }.to raise_error(ActiveRecord::RecordNotSaved, /Database update failed/)
    end
  end

  describe '#reference_counter' do
    it 'returns a Gitlab::ReferenceCounter object' do
      expect(Gitlab::ReferenceCounter).to receive(:new).with(repository.gl_repository).and_call_original

      result = container.reference_counter(type: repository.repo_type)

      expect(result).to be_a Gitlab::ReferenceCounter
    end
  end
end
