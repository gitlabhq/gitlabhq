# frozen_string_literal: true

RSpec.shared_examples 'pipeline schedules checking variables permission' do
  let(:params) do
    {
      description: 'desc',
      ref: 'patch-x',
      active: false,
      cron: '*/1 * * * *',
      cron_timezone: 'UTC',
      variables_attributes: variables_attributes
    }
  end

  shared_examples 'success response' do
    it 'saves values with passed params' do
      result = service.execute

      expect(result.status).to eq(:success)
      expect(result.payload).to have_attributes(
        description: 'desc',
        ref: "#{Gitlab::Git::BRANCH_REF_PREFIX}patch-x",
        active: false,
        cron: '*/1 * * * *',
        cron_timezone: 'UTC'
      )
    end
  end

  shared_examples 'failure response' do
    it 'does not save' do
      result = service.execute

      expect(result.status).to eq(:error)
      expect(result.reason).to eq(:forbidden)
      expect(result.message).to match_array(
        ['The current user is not authorized to set pipeline schedule variables']
      )
    end
  end

  context 'when sending variables' do
    let(:variables_attributes) do
      [{ key: 'VAR2', secret_value: 'secret 2' }]
    end

    shared_examples 'success response with variables' do
      it_behaves_like 'success response'

      it 'saves variables' do
        result = service.execute

        variables = result.payload.variables.map { |v| [v.key, v.value] }

        expect(variables).to include(
          ['VAR2', 'secret 2']
        )
      end
    end

    context 'when user is maintainer' do
      it_behaves_like 'success response with variables'
    end

    context 'when user is developer' do
      before_all do
        project.add_developer(user)
      end

      it_behaves_like 'success response with variables'
    end

    context 'when restrict_user_defined_variables is true' do
      before_all do
        project.update!(restrict_user_defined_variables: true, ci_pipeline_variables_minimum_override_role: :maintainer)
      end

      it_behaves_like 'success response with variables'

      context 'when user is developer' do
        before_all do
          project.add_developer(user)
        end

        it_behaves_like 'failure response'
      end
    end
  end

  context 'when not sending variables' do
    let(:variables_attributes) { [] }

    context 'when user is maintainer' do
      it_behaves_like 'success response'
    end

    context 'when user is developer' do
      before_all do
        project.add_developer(user)
      end

      it_behaves_like 'success response'
    end

    context 'when restrict_user_defined_variables is true' do
      before_all do
        project.update!(restrict_user_defined_variables: true)
      end

      it_behaves_like 'success response'

      context 'when user is developer' do
        before_all do
          project.add_developer(user)
        end

        it_behaves_like 'success response'
      end
    end
  end
end
