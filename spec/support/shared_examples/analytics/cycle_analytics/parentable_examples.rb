# frozen_string_literal: true

RSpec.shared_examples 'value stream analytics namespace models' do
  let(:factory_name) { nil }

  context 'when ProjectNamespace is given' do
    it 'is valid' do
      project_namespace = create(:project_namespace)
      model = build(factory_name, namespace: project_namespace)

      expect(model).to be_valid
      expect(model.save).to be(true)
      expect(model.namespace).to eq(project_namespace)
    end
  end

  context 'when personal namespace is given' do
    it 'is valid' do
      namespace = create(:namespace, owner: create(:user))
      model = build(factory_name, namespace: namespace)

      expect(model).to be_valid
      expect(model.save).to be(true)
      expect(model.namespace).to eq(namespace)
    end
  end
end
