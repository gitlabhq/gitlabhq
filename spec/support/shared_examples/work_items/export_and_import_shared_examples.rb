# frozen_string_literal: true

RSpec.shared_examples_for 'a exported file that can be imported' do
  before do
    origin_project.add_reporter(user)
    target_project.add_reporter(user)
  end

  def export_work_items_for(project)
    origin_work_items = WorkItem.where(project: origin_project)
    export = described_class.new(origin_work_items, project)
    export.email(user)
    attachment = ActionMailer::Base.deliveries.last.attachments.first
    file = Tempfile.new('temp_work_item_export.csv')
    file.write(attachment.read)

    file
  end

  def import_file_for(project, file)
    uploader = FileUploader.new(project)
    uploader.store!(file)
    import_service = WorkItems::ImportCsvService.new(user, target_project, uploader)

    import_service.execute
  end

  it 'imports work item with correct attributes', :aggregate_failures do
    csv_file = export_work_items_for(origin_project)

    imported_work_items = ::WorkItems::WorkItemsFinder.new(user, project: target_project).execute
    expect { import_file_for(target_project, csv_file) }.to change { imported_work_items.count }.by 1
    imported_work_item = imported_work_items.first
    expect(imported_work_item.author).to eq(user)
    expected_matching_fields.each do |field|
      expect(imported_work_item.public_send(field)).to eq(work_item.public_send(field))
    end
  end
end
