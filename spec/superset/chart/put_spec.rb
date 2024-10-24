require 'spec_helper'
require 'shared/base_put_request_shared_examples'

RSpec.describe Superset::Chart::Put do
  describe 'behaves like a BasePutRequest' do
    it_behaves_like :base_put_request_shared_examples
  end
end
