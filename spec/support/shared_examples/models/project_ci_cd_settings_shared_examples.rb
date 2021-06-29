# frozen_string_literal: true

RSpec.shared_examples 'ci_cd_settings delegation' do
  let(:exclude_attributes) { [] }

  context 'when ci_cd_settings is destroyed but project is not' do
    it 'allows methods delegated to ci_cd_settings to be nil', :aggregate_failures do
      project = create(:project)
      attributes = project.ci_cd_settings.attributes.keys - %w(id project_id) - exclude_attributes
      project.ci_cd_settings.destroy!
      project.reload
      attributes.each do |attr|
        method = project.respond_to?("ci_#{attr}") ? "ci_#{attr}" : attr
        expect(project.send(method)).to be_nil, "#{attr} was not nil"
      end
    end
  end
end

RSpec.shared_examples 'a ci_cd_settings predicate method' do |prefix: ''|
  using RSpec::Parameterized::TableSyntax

  let_it_be(:project) { create(:project) }

  context 'when ci_cd_settings is nil' do
    before do
      allow(project).to receive(:ci_cd_settings).and_return(nil)
    end

    it 'returns false' do
      expect(project.send("#{prefix}#{delegated_method}")).to be(false)
    end
  end

  context 'when ci_cd_settings is not nil' do
    where(:delegated_method_return, :subject_return) do
      true  | true
      false | false
    end

    with_them do
      let(:ci_cd_settings_double) { double('ProjectCiCdSetting') }

      before do
        allow(project).to receive(:ci_cd_settings).and_return(ci_cd_settings_double)
        allow(ci_cd_settings_double).to receive(delegated_method).and_return(delegated_method_return)
      end

      it 'returns the expected boolean value' do
        expect(project.send("#{prefix}#{delegated_method}")).to be(subject_return)
      end
    end
  end
end
