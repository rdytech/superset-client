require 'spec_helper'
require 'superset/services/duplicate_dashboard'

RSpec.describe Superset::Services::DuplicateDashboard do
  subject { described_class.new(
              source_dashboard_id: source_dashboard_id, 
              target_schema:       target_schema, 
              target_database_id:  target_database_id) }
  
  let(:source_dashboard_id) { 1 }
  let(:target_schema) { 'schema_one' }
  let(:target_database_id) { 6 }
  let(:target_database_available_schemas) { ['schema_one', 'schema_two', 'schema_three'] }

  let(:new_dashboard) { double('new_dashboard', id: 2) }

  before do
    allow(subject).to receive(:target_database_available_schemas).and_return(target_database_available_schemas)
    allow(subject).to receive(:new_dashboard).and_return(new_dashboard)
  end

  describe '#perform' do
    context 'with valid params' do


    end

    context 'with invalid params' do
      context 'source_dashboard_id is empty' do
        let(:source_dashboard_id) { nil }
        
        specify do
          expect { subject.perform }.to raise_error(RuntimeError, "Error: source_dashboard_id integer is required")
        end
      end
  
      context 'target_schema is empty' do
        let(:target_schema) { nil }

        specify do
          expect { subject.perform }.to raise_error(RuntimeError, "Error: target_schema string is required")
        end
      end

      context 'target_database_id is empty' do
        let(:target_database_id) { nil }
        
        specify do
          expect { subject.perform }.to raise_error(RuntimeError, "Error: target_database_id integer is required")
        end
      end

      context 'target_schema is invalid' do
        let(:target_schema) { 'schema_four' }

        specify do
          expect { subject.perform }.to raise_error(RuntimeError, "Error: Schema schema_four does not exist in target database: 6")
        end
      end

      context 'source dashboard datasets use multiple schemas' do
        before do
          allow(subject).to receive(:source_dashboard_schemas).and_return(['schema_one', 'schema_five'])
        end
   
        specify do
          expect { subject.perform }.to raise_error(RuntimeError, "Error: The souce_dashboard_id #{source_dashboard_id} datasets point to more than one schema. Schema list is schema_one,schema_five")
        end
      end
    end
  end
end