require 'spec_helper'

RSpec.describe Superset::Database::List do
  subject { described_class.new }
  let(:result) do
    [
      {
        id: 1,
        database_name: 'Test 1',
        backend: 'postgres',
        expose_in_sqllab: 'true'
      },
      {
        id: 2,
        database_name: 'Test 2',
        backend: 'mysql',
        expose_in_sqllab: 'false'
      }
    ]
  end

  before do
    allow(subject).to receive(:result).and_return(result)
  end

  describe '#rows' do
    specify do
      expect(subject.rows).to match_array(
        [
          ['1', "Test 1", "postgres", "true"],
          ['2', 'Test 2', 'mysql', "false"]
        ]
      )
    end
  end

  describe '#query_params' do
    context 'for pagination' do
      context 'with defaults' do
        specify do
          expect(subject.query_params).to eq("page:0,page_size:100")
        end
      end

      context 'with specifiec page' do
        subject { described_class.new(page_num: 5) }

        specify do
          expect(subject.query_params).to eq("page:5,page_size:100")
        end
      end
    end

    context 'with title_contains filters' do
      subject { described_class.new(title_contains: 'acme') }

      specify do
        expect(subject.query_params).to eq("filters:!((col:database_name,opr:ct,value:'acme')),page:0,page_size:100")
      end
    end
  end
end
