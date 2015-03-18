# == Schema Information
#
# Table name: deploy_keys_projects
#
#  id            :integer          not null, primary key
#  deploy_key_id :integer          not null
#  project_id    :integer          not null
#  created_at    :datetime
#  updated_at    :datetime
#

require 'spec_helper'

describe DeployKeysProject do
  describe "Associations" do
    it { is_expected.to belong_to(:deploy_key) }
    it { is_expected.to belong_to(:project) }
  end

  describe "Validation" do
    it { is_expected.to validate_presence_of(:project_id) }
    it { is_expected.to validate_presence_of(:deploy_key_id) }
  end

  describe "Destroying" do
    let(:project)     { create(:project) }
    subject           { create(:deploy_keys_project, project: project) }
    let(:deploy_key)  { subject.deploy_key }

    context "when the deploy key is only used by this project" do
      it "destroys the deploy key" do
        subject.destroy

        expect {
          deploy_key.reload
        }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context "when the deploy key is used by more than one project" do

      let!(:other_project) { create(:project) }

      before do
        other_project.deploy_keys << deploy_key
      end

      it "doesn't destroy the deploy key" do
        subject.destroy

        expect {
          deploy_key.reload
        }.not_to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end
end
