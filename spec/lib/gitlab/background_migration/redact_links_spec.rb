require 'spec_helper'

describe Gitlab::BackgroundMigration::RedactLinks, :migration, schema: 20181014121030 do
  let(:namespaces) { table(:namespaces) }
  let(:projects) { table(:projects) }
  let(:issues) { table(:issues) }
  let(:notes) { table(:notes) }
  let(:snippets) { table(:snippets) }
  let(:users) { table(:users) }
  let(:merge_requests) { table(:merge_requests) }
  let(:namespace) { namespaces.create(name: 'gitlab', path: 'gitlab-org') }
  let(:project) { projects.create(namespace_id: namespace.id, name: 'foo') }
  let(:user) { users.create!(email: 'test@example.com', projects_limit: 100, username: 'test') }

  def create_merge_request(id, params)
    params.merge!(id: id,
                  target_project_id: project.id,
                  target_branch: 'master',
                  source_project_id: project.id,
                  source_branch: 'mr name',
                  title: "mr name#{id}")

    merge_requests.create(params)
  end

  def create_issue(id, params)
    params.merge!(id: id, title: "issue#{id}", project_id: project.id)

    issues.create(params)
  end

  def create_note(id, params)
    params[:id] = id

    notes.create(params)
  end

  def create_snippet(id, params)
    params.merge!(id: id, author_id: user.id)

    snippets.create(params)
  end

  def create_resource(model, id, params)
    send("create_#{model.name.underscore}", id, params)
  end

  shared_examples_for 'redactable resource' do
    it 'updates only matching texts' do
      matching_text = 'some text /sent_notifications/00000000000000000000000000000000/unsubscribe more text'
      redacted_text = 'some text /sent_notifications/REDACTED/unsubscribe more text'
      create_resource(model, 1, { field => matching_text })
      create_resource(model, 2, { field => 'not matching text' })
      create_resource(model, 3, { field => matching_text })
      create_resource(model, 4, { field => redacted_text })
      create_resource(model, 5, { field => matching_text })

      expected = { field => 'some text /sent_notifications/REDACTED/unsubscribe more text',
                   "#{field}_html" => nil }
      expect_any_instance_of("Gitlab::BackgroundMigration::RedactLinks::#{model}".constantize).to receive(:update_columns).with(expected).and_call_original

      subject.perform(model, field, 2, 4)

      expect(model.where(field => matching_text).pluck(:id)).to eq [1, 5]
      expect(model.find(3).reload[field]).to eq redacted_text
    end
  end

  context 'resource is Issue' do
    it_behaves_like 'redactable resource' do
      let(:model) { Issue }
      let(:field) { :description }
    end
  end

  context 'resource is Merge Request' do
    it_behaves_like 'redactable resource' do
      let(:model) { MergeRequest }
      let(:field) { :description }
    end
  end

  context 'resource is Note' do
    it_behaves_like 'redactable resource' do
      let(:model) { Note }
      let(:field) { :note }
    end
  end

  context 'resource is Snippet' do
    it_behaves_like 'redactable resource' do
      let(:model) { Snippet }
      let(:field) { :description }
    end
  end
end
