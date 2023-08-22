# frozen_string_literal: true

RSpec.shared_examples 'migrating records to the ghost user' do |record_class, fields|
  record_class_name = record_class.to_s.titleize.downcase

  let(:project) do
    case record_class
    when MergeRequest
      create(:project, :repository)
    else
      create(:project)
    end
  end

  before do
    project.add_developer(user)
  end

  context "for a #{record_class_name} the user has created" do
    let!(:record) { created_record }
    let(:migrated_fields) { fields || [:author] }

    it "does not delete the #{record_class_name}" do
      service.execute

      expect(record_class.find_by_id(record.id)).to be_present
    end

    it 'migrates all associated fields to the "Ghost user"' do
      service.execute

      migrated_record = record_class.find_by_id(record.id)

      migrated_fields.each do |field|
        expect(migrated_record.public_send(field)).to eq(Users::Internal.ghost)
      end
    end
  end
end
