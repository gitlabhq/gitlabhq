# frozen_string_literal: true

shared_examples 'assignee ID filter' do
  it 'returns issuables assigned to that user' do
    expect(issuables).to contain_exactly(*expected_issuables)
  end
end

shared_examples 'assignee username filter' do
  it 'returns issuables assigned to those users' do
    expect(issuables).to contain_exactly(*expected_issuables)
  end
end

shared_examples 'no assignee filter' do
  let(:params) { { assignee_id: 'None' } }

  it 'returns issuables not assigned to any assignee' do
    expect(issuables).to contain_exactly(*expected_issuables)
  end

  it 'returns issuables not assigned to any assignee' do
    params[:assignee_id] = 0

    expect(issuables).to contain_exactly(*expected_issuables)
  end

  it 'returns issuables not assigned to any assignee' do
    params[:assignee_id] = 'none'

    expect(issuables).to contain_exactly(*expected_issuables)
  end
end

shared_examples 'any assignee filter' do
  context '' do
    let(:params) { { assignee_id: 'Any' } }

    it 'returns issuables assigned to any assignee' do
      expect(issuables).to contain_exactly(*expected_issuables)
    end

    it 'returns issuables assigned to any assignee' do
      params[:assignee_id] = 'any'

      expect(issuables).to contain_exactly(*expected_issuables)
    end
  end
end
