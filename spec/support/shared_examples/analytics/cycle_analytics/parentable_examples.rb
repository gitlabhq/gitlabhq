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

  context 'when Namespace is given' do
    it 'fails' do
      namespace = create(:namespace)
      model = build(factory_name, namespace: namespace)

      expect(model).to be_invalid

      error_message = s_('CycleAnalytics|the assigned object is not supported')
      expect(model.errors.messages_for(:namespace)).to eq([error_message])
    end
  end
end
