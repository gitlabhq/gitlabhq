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

  it_behaves_like 'a mutation that returns top-level errors' do
    let(:match_errors) { include(/ does not represent an instance of Noteable/) }
  end
end

RSpec.shared_examples 'a Note mutation when the given resource id is not for a Note' do
  let(:note) { create(:issue) }

  it_behaves_like 'a mutation that returns top-level errors' do
    let(:match_errors) { include(/does not represent an instance of Note/) }
  end
end

RSpec.shared_examples 'a Note mutation when there are rate limit validation errors' do
  context 'with rate limiter', :freeze_time, :clean_gitlab_redis_rate_limiting do
    before do
      stub_application_setting(notes_create_limit: 3)
      3.times { post_graphql_mutation(mutation, current_user: current_user) }
    end

    it_behaves_like 'a Note mutation that does not create a Note'
    it_behaves_like 'a mutation that returns top-level errors',
      errors: ['This endpoint has been requested too many times. Try again later.']

    context 'when the user is in the allowlist' do
      before do
        stub_application_setting(notes_create_limit_allowlist: [current_user.username.to_s])
      end

      it_behaves_like 'a Note mutation that creates a Note'
    end
  end
end

RSpec.shared_examples 'a Note mutation with confidential notes' do
  it_behaves_like 'a Note mutation that creates a Note'

  it 'returns a Note with confidentiality enabled' do
    post_graphql_mutation(mutation, current_user: current_user)

    expect(mutation_response).to have_key('note')
    expect(mutation_response['note']['internal']).to eq(true)
  end
end

RSpec.shared_examples 'a Note mutation updates a note successfully' do
  it 'updates the Note' do
    post_graphql_mutation(mutation, current_user: current_user)

    expect(note.reload.note).to eq(updated_body)
  end

  it 'returns the updated Note' do
    post_graphql_mutation(mutation, current_user: current_user)

    expect(mutation_response['note']['body']).to eq(updated_body)
  end
end

RSpec.shared_examples 'a Note mutation update with errors' do
  context 'when there are ActiveRecord validation errors' do
    let(:params) { { body: '' } }

    it 'does not update the Note' do
      post_graphql_mutation(mutation, current_user: current_user)

      expect(note.reload.note).to eq(original_body)
      expect(note.confidential).to be_falsey
    end

    it 'returns the original Note' do
      post_graphql_mutation(mutation, current_user: current_user)

      expect(mutation_response['note']['body']).to eq(original_body)
      expect(mutation_response['note']['confidential']).to be_falsey
    end
  end
end

RSpec.shared_examples 'a Note mutation update only with quick actions' do
  context 'when body only contains quick actions' do
    let(:updated_body) { '/close' }

    it 'returns a nil note and empty errors' do
      post_graphql_mutation(mutation, current_user: current_user)

      expect(mutation_response).to include(
        'errors' => [],
        'note' => nil
      )
    end
  end
end
