require 'spec_helper'

describe NamespaceValidator do
  let(:validator) { described_class.new(attributes: [:path]) }
  describe 'RESERVED' do
    it 'includes all the top level namespaces' do
      all_top_level_routes = Rails.application.routes.routes.routes.
                               map { |r| r.path.spec.to_s }.
                               select { |p| p !~ %r{^/[:*]} }.
                               map { |p| p.split('/')[1] }.
                               compact.
                               map { |p| p.split('(', 2)[0] }.
                               uniq

      expect(described_class::RESERVED).to include(*all_top_level_routes)
    end
  end

  describe 'WILDCARD_ROUTES' do
    it 'includes all paths that can be used after a namespace/project path' do
      all_wildcard_paths = Rails.application.routes.routes.routes.
                             map { |r| r.path.spec.to_s }.
                             select { |p| p =~ %r{^/\*namespace_id/:(project_)?id/[^:*]} }.
                             map { |p| p.split('/')[3].split('(', 2)[0] }.
                             uniq

      expect(described_class::WILDCARD_ROUTES).to include(*all_wildcard_paths)
    end
  end

  describe '#validation_type' do
    it 'uses top level validation for groups without parent' do
      group = build(:group)

      type = validator.validation_type(group)

      expect(type).to eq(:top_level)
    end

    it 'uses wildcard validation for groups with a parent' do
      group = build(:group, parent: create(:group))

      type = validator.validation_type(group)

      expect(type).to eq(:wildcard)
    end

    it 'uses wildcard validation for a project' do
      project = build(:project)

      type = validator.validation_type(project)

      expect(type).to eq(:wildcard)
    end

    it 'uses strict validation for everything else' do
      type = validator.validation_type(double)

      expect(type).to eq(:strict)
    end
  end
end
