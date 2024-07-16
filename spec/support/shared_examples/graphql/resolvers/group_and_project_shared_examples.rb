# frozen_string_literal: true

RSpec.shared_examples 'a resolver that batch resolves by full path' do
  describe '#resolve' do
    it 'batch-resolves entities by full path' do
      paths = [entity1.full_path, entity2.full_path]
      result = batch_sync(max_queries: 3) do
        paths.map { |path| send(resolve_method, path) }
      end
      expect(result).to contain_exactly(entity1, entity2)
    end

    it 'resolves an unknown full_path to nil' do
      result = batch_sync { send(resolve_method, 'unknown/entity') }

      expect(result).to be_nil
    end

    it 'treats entity full path as case insensitive' do
      result = batch_sync { send(resolve_method, entity1.full_path.upcase) }
      expect(result).to eq entity1
    end
  end
end
