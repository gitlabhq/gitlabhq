# frozen_string_literal: true

shared_examples 'no Jira import data present' do
  it 'returns none' do
    expect(resolve_imports).to eq JiraImportState.none
  end
end

shared_examples 'no Jira import access' do
  it 'raises error' do
    expect do
      resolve_imports
    end.to raise_error(Gitlab::Graphql::Errors::ResourceNotAvailable)
  end
end
