# frozen_string_literal: true

RSpec.shared_examples 'resolving an issuable in GraphQL' do |type|
  subject { mutation.resolve_issuable(type: type, parent_path: parent.full_path, iid: issuable.iid) }

  context 'when user has access' do
    before do
      parent.add_developer(user)
    end

    it 'resolves issuable by iid' do
      result = type == :merge_request ? subject.sync : subject
      expect(result).to eq(issuable)
    end

    it 'uses the correct Resolver to resolve issuable' do
      resolver_class = "Resolvers::#{type.to_s.classify.pluralize}Resolver".constantize
      resolve_method = type == :epic ? :resolve_group : :resolve_project
      resolved_parent = mutation.send(resolve_method, full_path: parent.full_path)

      allow(mutation).to receive(resolve_method)
        .with(full_path: parent.full_path)
        .and_return(resolved_parent)

      expect(resolver_class.single).to receive(:new)
        .with(object: resolved_parent, context: context, field: nil)
        .and_call_original

      subject
    end

    it 'returns nil if issuable is not found' do
      result = mutation.resolve_issuable(type: type, parent_path: parent.full_path, iid: "100")
      result = result.respond_to?(:sync) ? result.sync : result

      expect(result).to be_nil
    end

    it 'returns nil if parent path is not present' do
      result = mutation.resolve_issuable(type: type, parent_path: "", iid: issuable.iid)

      expect(result).to be_nil
    end
  end
end
