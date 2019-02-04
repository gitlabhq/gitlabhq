shared_examples_for 'fast destroyable' do
  describe 'Forbid #destroy and #destroy_all' do
    it 'does not delete database rows and associted external data' do
      expect(external_data_counter).to be > 0
      expect(subjects.count).to be > 0

      expect { subjects.first.destroy }.to raise_error('`destroy` and `destroy_all` are forbidden. Please use `fast_destroy_all`')
      expect { subjects.destroy_all }.to raise_error('`destroy` and `destroy_all` are forbidden. Please use `fast_destroy_all`') # rubocop: disable DestroyAll

      expect(subjects.count).to be > 0
      expect(external_data_counter).to be > 0
    end
  end

  describe '.fast_destroy_all' do
    it 'deletes database rows and associted external data' do
      expect(external_data_counter).to be > 0
      expect(subjects.count).to be > 0

      expect { subjects.fast_destroy_all }.not_to raise_error

      expect(subjects.count).to eq(0)
      expect(external_data_counter).to eq(0)
    end
  end

  describe '.use_fast_destroy' do
    it 'performs cascading delete with fast_destroy_all' do
      expect(external_data_counter).to be > 0
      expect(subjects.count).to be > 0

      expect { parent.destroy }.not_to raise_error

      expect(subjects.count).to eq(0)
      expect(external_data_counter).to eq(0)
    end
  end
end
