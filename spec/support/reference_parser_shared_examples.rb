RSpec.shared_examples "referenced feature visibility" do |*related_features|
  let(:feature_fields) do
    related_features.map { |feature| (feature + "_access_level").to_sym }
  end

  before { link['data-project'] = project.id.to_s }

  context "when feature is disabled" do
    it "does not create reference" do
      set_features_fields_to(ProjectFeature::DISABLED)
      expect(subject.nodes_visible_to_user(user, [link])).to eq([])
    end
  end

  context "when feature is enabled only for team members" do
    before { set_features_fields_to(ProjectFeature::PRIVATE) }

    it "does not create reference for non member" do
      non_member = create(:user)

      expect(subject.nodes_visible_to_user(non_member, [link])).to eq([])
    end

    it "creates reference for member" do
      project.team << [user, :developer]

      expect(subject.nodes_visible_to_user(user, [link])).to eq([link])
    end
  end

  context "when feature is enabled" do
    # The project is public
    it "creates reference" do
      set_features_fields_to(ProjectFeature::ENABLED)

      expect(subject.nodes_visible_to_user(user, [link])).to eq([link])
    end
  end

  def set_features_fields_to(visibility_level)
    feature_fields.each { |field| project.project_feature.update_attribute(field, visibility_level) }
  end
end
