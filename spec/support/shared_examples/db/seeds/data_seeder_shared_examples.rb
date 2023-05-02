# frozen_string_literal: true

RSpec.shared_examples 'raises an error when specifying an invalid factory' do
  it 'raises an error' do
    expect { parser.parse }.to raise_error(RuntimeError, /invalids.*to a valid registered Factory/)
  end
end

RSpec.shared_examples 'specifying invalid traits to a factory' do
  it 'raises an error', :aggregate_failures do
    expect { parser.parse }.to raise_error do |error|
      expect(error).to be_a(RuntimeError)
      expect(error.message).to include('Trait not registered: \\"invalid\\"')
      expect(error.message).to include('for Factory \\"issue\\"')
    end
  end
end

RSpec.shared_examples 'specifying invalid attributes to a factory' do
  it 'raises an error' do
    expect { parser.parse }.to raise_error(RuntimeError, /is not a valid attribute/)
  end

  it 'contains possible alternatives' do
    expect { parser.parse }.to raise_error(RuntimeError, /Did you mean/)
  end
end

RSpec.shared_examples 'an id already exists' do
  it 'raises a validation error' do
    expect { parser.parse }.to raise_error(/id `my_label` must be unique/)
  end
end

RSpec.shared_examples 'name is not specified' do
  it 'raises an error when name is not specified' do
    expect { parser.parse }.to raise_error(/Seed file must specify a name/)
  end
end

RSpec.shared_examples 'factory definitions' do
  it 'has exactly two definitions' do
    parser.parse

    expect(parser.definitions.size).to eq(2)
  end

  it 'creates the group label' do
    expect { parser.parse }.to change { GroupLabel.count }.by(1)
  end

  it 'creates the project' do
    expect { parser.parse }.to change { Project.count }.by(1)
  end
end

RSpec.shared_examples 'passes traits' do
  it 'passes traits' do
    expect_next_instance_of(Gitlab::DataSeeder::FactoryDefinitions::FactoryDefinition) do |instance|
      # `described` trait will automaticaly generate a description
      expect(instance.build(binding).description).to eq('Description of Test Label')
    end

    parser.parse
  end
end

RSpec.shared_examples 'has a name' do
  it 'has a name' do
    parser.parse

    expect(parser.name).to eq('Test')
  end
end

RSpec.shared_examples 'definition has an id' do
  it 'binds the object', :aggregate_failures do
    parser.parse

    expect(group_labels).to be_a(OpenStruct) # rubocop:disable Style/OpenStructUse
    expect(group_labels.my_label).to be_a(GroupLabel)
    expect(group_labels.my_label.title).to eq('My Label')
  end
end

RSpec.shared_examples 'id has spaces' do
  it 'binds to an underscored variable', :aggregate_failures do
    parser.parse

    expect(group_labels).to respond_to(:id_with_spaces)
    expect(group_labels.id_with_spaces.title).to eq('With Spaces')
  end

  it 'renders a warning' do
    expect { parser.parse }.to output(%(parsing id "id with spaces" as "id_with_spaces"\n)).to_stderr
  end
end

RSpec.shared_examples 'definition does not have an id' do
  it 'does not bind the object' do
    parser.parse

    expect(group_labels.to_h).to be_empty
  end
end

RSpec.shared_examples 'invalid id' do |message|
  it 'raises an error' do
    expect { parser.parse }.to raise_error(message)
  end
end
