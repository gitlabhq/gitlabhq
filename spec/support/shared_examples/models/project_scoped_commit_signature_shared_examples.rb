# frozen_string_literal: true

RSpec.shared_examples 'project-scoped commit signature' do
  it 'creates separate signatures for the same commit_sha in different projects' do
    project2 = create(:project, :repository)

    signature1 = described_class.safe_create!(attributes.merge(project: project))
    signature2 = described_class.safe_create!(attributes.merge(project: project2))

    expect(signature1).not_to eq(signature2)
    expect(signature1.project_id).to eq(project.id)
    expect(signature2.project_id).to eq(project2.id)
    expect(signature1.commit_sha).to eq(signature2.commit_sha)
  end
end
