# == Schema Information
#
# Table name: services
#
#  id                    :integer          not null, primary key
#  type                  :string(255)
#  title                 :string(255)
#  project_id            :integer
#  created_at            :datetime
#  updated_at            :datetime
#  active                :boolean          default(FALSE), not null
#  properties            :text
#  template              :boolean          default(FALSE)
#  push_events           :boolean          default(TRUE)
#  issues_events         :boolean          default(TRUE)
#  merge_requests_events :boolean          default(TRUE)
#  tag_push_events       :boolean          default(TRUE)
#  note_events           :boolean          default(TRUE), not null
#

require 'spec_helper'
require 'composer'

describe ComposerService, models: true do
  describe 'Associations' do
    it { is_expected.to belong_to :project }
    it { is_expected.to have_one :service_hook }
  end

  describe 'Validations' do
    context 'active' do
      before do
        subject.active = true
      end

      it { is_expected.to validate_presence_of :package_mode }
      it { is_expected.to validate_presence_of :package_type }

    end
  end

  describe 'path and filename methods' do
    let(:project) { create(:project) }

    before do
      @service = ComposerService.new
      allow(@service).to receive_messages(
        project: project,
        project_id: project.id,
        service_hook: true,
        package_mode: 'default',
        package_type: 'library',
        export_branches: '0',
        branch_filters: '',
        export_tags: '0',
        tag_filters: ''
      )
    end

    after do
      @service.destroy!
    end

    it :output_dir do
      expect(@service.instance_eval { output_dir }).to eq(Rails.public_path)
    end

    it :provider_dir do
      expect(@service.instance_eval { provider_dir }).to eq(Rails.public_path.to_s + "/p")
    end

    it :root_filename do
      expect(@service.instance_eval { root_filename }).to eq("packages.json")
    end

    it :root_path do
      expect(@service.instance_eval { root_path }).to eq(Rails.public_path.to_s + "/packages.json")
    end

    it :repo_filename do
      expect(@service.instance_eval { repo_filename }).to eq("project-#{project.id}.json")
    end

    it :repo_path do
      expect(@service.instance_eval { repo_path }).to eq(Rails.public_path.to_s + "/p/project-#{project.id}.json")
    end


  end

end
