# frozen_string_literal: true

RSpec.shared_examples 'can housekeep repository' do
  context 'with a clean redis state', :clean_gitlab_redis_shared_state do
    describe '#pushes_since_gc' do
      context 'without any pushes' do
        it 'returns 0' do
          expect(resource.pushes_since_gc).to eq(0)
        end
      end

      context 'with a number of pushes' do
        it 'returns the number of pushes' do
          3.times { resource.increment_pushes_since_gc }

          expect(resource.pushes_since_gc).to eq(3)
        end
      end
    end

    describe '#increment_pushes_since_gc' do
      it 'increments the number of pushes since the last GC' do
        3.times { resource.increment_pushes_since_gc }

        expect(resource.pushes_since_gc).to eq(3)
      end
    end

    describe '#reset_pushes_since_gc' do
      it 'resets the number of pushes since the last GC' do
        3.times { resource.increment_pushes_since_gc }

        resource.reset_pushes_since_gc

        expect(resource.pushes_since_gc).to eq(0)
      end
    end

    describe '#pushes_since_gc_redis_shared_state_key' do
      it 'returns the proper redis key format' do
        expect(resource.send(:pushes_since_gc_redis_shared_state_key)).to eq("#{resource_key}/#{resource.id}/pushes_since_gc")
      end
    end

    describe '#git_garbage_collect_worker_klass' do
      it 'defines a git gargabe collect worker' do
        expect(resource.git_garbage_collect_worker_klass).to eq(expected_worker_class)
      end
    end
  end
end
