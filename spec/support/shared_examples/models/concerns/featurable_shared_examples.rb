# frozen_string_literal: true

RSpec.shared_examples 'access level validation' do |features|
  features.each do |feature|
    it "does not allow public access level for #{feature}" do
      field = "#{feature}_access_level".to_sym
      container_features.update_attribute(field, ProjectFeature::PUBLIC)

      expect(container_features.valid?).to be_falsy, "#{field} failed"
    end
  end
end
