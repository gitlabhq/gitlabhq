# frozen_string_literal: true

require 'spec_helper'

RSpec.describe DeployKeysProject do
  describe "Associations" do
    it { is_expected.to belong_to(:deploy_key) }
    it { is_expected.to belong_to(:project) }
  end

  describe "Validation" do
    it { is_expected.to validate_presence_of(:project_id) }
    it { is_expected.to validate_presence_of(:deploy_key) }
  end

  describe "Destroying" do
    let(:project)     { create(:project) }
    subject           { create(:deploy_keys_project, project: project) }

    let(:deploy_key)  { subject.deploy_key }

    context "when the deploy key is only used by this project" do
      context "when the deploy key is public" do
        before do
          deploy_key.update_attribute(:public, true)
        end

        it "doesn't destroy the deploy key" do
          subject.destroy!

          expect { deploy_key.reload }.not_to raise_error
        end
      end

      context "when the deploy key is private" do
        it "destroys the deploy key" do
          subject.destroy!

          expect { deploy_key.reload }.to raise_error(ActiveRecord::RecordNotFound)
        end
      end
    end

    context "when the deploy key is used by more than one project" do
      let!(:other_project) { create(:project) }

      before do
        other_project.deploy_keys << deploy_key
      end

      it "doesn't destroy the deploy key" do
        subject.destroy!

        expect { deploy_key.reload }.not_to raise_error
      end
    end
  end
end
