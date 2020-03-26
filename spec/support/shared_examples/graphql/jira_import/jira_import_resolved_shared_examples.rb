# frozen_string_literal: true

shared_examples 'no jira import data present' do
  it 'returns none' do
    expect(resolve_imports).to eq JiraImportData.none
  end
end

shared_examples 'no jira import access' do
  it 'raises error' do
    expect do
      resolve_imports
    end.to raise_error(Gitlab::Graphql::Errors::ResourceNotAvailable)
  end
end
