# frozen_string_literal: true

RSpec.shared_examples "referenced feature visibility" do |*related_features|
  let(:enable_user?) { false }
  let(:feature_fields) do
    related_features.map { |feature| (feature + "_access_level").to_sym }
  end

  before do
    link['data-project'] = project.id.to_s
  end

  context "when feature is disabled" do
    it "does not create reference" do
      set_features_fields_to(ProjectFeature::DISABLED)
      expect(subject.nodes_visible_to_user(user, [link])).to eq([])
    end
  end

  context "when feature is enabled only for team members" do
    before do
      set_features_fields_to(ProjectFeature::PRIVATE)
    end

    it "does not create reference for non member" do
      non_member = create(:user)

      expect(subject.nodes_visible_to_user(non_member, [link])).to eq([])
    end

    it "creates reference for member" do
      project.add_developer(user)

      expect(subject.nodes_visible_to_user(user, [link])).to eq([link])
    end
  end

  context "when feature is enabled" do
    # Allows implementing specs to enable finer-tuned permissions
    let(:enable_user?) { true }

    it "creates reference" do
      # The project is public
      set_features_fields_to(ProjectFeature::ENABLED)

      expect(subject.nodes_visible_to_user(user, [link])).to eq([link])
    end
  end

  def set_features_fields_to(visibility_level)
    feature_fields.each { |field| project.project_feature.update_attribute(field, visibility_level) }
  end
end
