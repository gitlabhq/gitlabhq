# frozen_string_literal: true

RSpec.shared_examples 'a Note mutation that does not create a Note' do
  it do
    expect do
      post_graphql_mutation(mutation, current_user: current_user)
    end.not_to change { Note.count }
  end
end

RSpec.shared_examples 'a Note mutation that creates a Note' do
  it do
    expect do
      post_graphql_mutation(mutation, current_user: current_user)
    end.to change { Note.count }.by(1)
  end
end

RSpec.shared_examples 'a Note mutation when the user does not have permission' do
  it_behaves_like 'a Note mutation that does not create a Note'

  it_behaves_like 'a mutation that returns top-level errors',
                  errors: ['The resource that you are attempting to access does not exist or you don\'t have permission to perform this action']
end

RSpec.shared_examples 'a Note mutation when there are active record validation errors' do |model: Note|
  before do
    expect_next_instance_of(model) do |note|
      allow(note).to receive_message_chain(:errors, :empty?).and_return(true)
      expect(note).to receive(:valid?).at_least(:once).and_return(false)
      expect(note).to receive_message_chain(
        :errors,
        :full_messages
      ).and_return(['Error 1', 'Error 2'])
    end
  end

  it_behaves_like 'a Note mutation that does not create a Note'

  it_behaves_like 'a mutation that returns errors in the response', errors: ['Error 1', 'Error 2']

  it 'returns an empty Note' do
    post_graphql_mutation(mutation, current_user: current_user)

    expect(mutation_response).to have_key('note')
    expect(mutation_response['note']).to be_nil
  end
end

RSpec.shared_examples 'a Note mutation when the given resource id is not for a Noteable' do
  let(:noteable) { create(:label, project: project) }

  it_behaves_like 'a Note mutation that does not create a Note'

  it_behaves_like 'a mutation that returns top-level errors', errors: ['Cannot add notes to this resource']
end

RSpec.shared_examples 'a Note mutation when the given resource id is not for a Note' do
  let(:note) { create(:issue) }

  it_behaves_like 'a mutation that returns top-level errors', errors: ['Resource is not a note']
end
