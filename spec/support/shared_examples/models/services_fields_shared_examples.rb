# frozen_string_literal: true

shared_examples 'issue tracker fields' do
  let(:title) { 'custom title' }
  let(:description) { 'custom description' }
  let(:url) { 'http://issue_tracker.example.com' }

  context 'when data are stored in the properties' do
    describe '#update' do
      before do
        service.update(title: 'new_title', description: 'new description')
      end

      it 'removes title and description from properties' do
        expect(service.reload.properties).not_to include('title', 'description')
      end

      it 'stores title & description in services table' do
        expect(service.read_attribute(:title)).to eq('new_title')
        expect(service.read_attribute(:description)).to eq('new description')
      end
    end

    describe 'reading fields' do
      it 'returns correct values' do
        expect(service.title).to eq(title)
        expect(service.description).to eq(description)
      end
    end
  end
end
