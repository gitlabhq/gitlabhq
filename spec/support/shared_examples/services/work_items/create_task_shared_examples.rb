# frozen_string_literal: true

RSpec.shared_examples 'title with extra spaces' do
  context 'when title has extra spaces' do
    before do
      params[:title] = " Awesome work item "
    end

    it 'removes extra leading and trailing whitespaces from title' do
      subject

      created_work_item = WorkItem.last
      expect(created_work_item.title).to eq('Awesome work item')
    end
  end
end
