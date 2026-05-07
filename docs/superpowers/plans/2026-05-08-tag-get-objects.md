# Tag::GetObjects Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add `Superset::Tag::GetObjects` — a read-only GET class that fetches all objects associated with a given tag ID from the Superset API.

**Architecture:** Inherits `Superset::Request`, implements `route` and `list_attributes`. Default `result` (`response['result']`) works as-is since the API wraps the object array in `"result"`. Display and pagination are provided by the base class via `Superset::Display`.

**Tech Stack:** Ruby, RSpec, inherits from `Superset::Request` / `Superset::Display`

---

### Task 1: Implement `Superset::Tag::GetObjects`

**Files:**
- Create: `lib/superset/tag/get_objects.rb`
- Create: `spec/superset/tag/get_objects_spec.rb`

- [ ] **Step 1: Write the failing test**

Create `spec/superset/tag/get_objects_spec.rb`:

```ruby
require 'spec_helper'

RSpec.describe Superset::Tag::GetObjects do
  subject { described_class.new(tag_id) }
  let(:tag_id) { 5 }
  let(:result) do
    [
      {
        "id" => 1,
        "name" => "Sales Dashboard",
        "type" => "dashboard",
        "url" => "/dashboard/1",
        "changed_on" => "2026-05-07T22:05:09.195Z",
        "creator" => "Jon B",
        "created_by" => { "first_name" => "Jon", "id" => 9, "last_name" => "B" },
        "owners" => [],
        "tags" => [{ "id" => 5, "name" => "finance", "type" => "CustomTag" }]
      },
      {
        "id" => 42,
        "name" => "Revenue Chart",
        "type" => "chart",
        "url" => "/chart/42",
        "changed_on" => "2026-05-06T10:00:00.000Z",
        "creator" => "Jane D",
        "created_by" => { "first_name" => "Jane", "id" => 3, "last_name" => "D" },
        "owners" => [],
        "tags" => [{ "id" => 5, "name" => "finance", "type" => "CustomTag" }]
      }
    ]
  end

  before do
    allow(subject).to receive(:result).and_return(result)
  end

  describe '#rows' do
    it 'returns id, name, type, url for each tagged object' do
      expect(subject.rows).to match_array([
        ["1", "Sales Dashboard", "dashboard", "/dashboard/1"],
        ["42", "Revenue Chart", "chart", "/chart/42"]
      ])
    end
  end
end
```

- [ ] **Step 2: Run the test to verify it fails**

```bash
rspec spec/superset/tag/get_objects_spec.rb
```

Expected: FAIL with `uninitialized constant Superset::Tag::GetObjects`

- [ ] **Step 3: Write the implementation**

Create `lib/superset/tag/get_objects.rb`:

```ruby
module Superset
  module Tag
    class GetObjects < Superset::Request

      attr_reader :id

      def initialize(id)
        @id = id
      end

      def self.call(id)
        self.new(id).list
      end

      private

      def route
        "tag/get_objects/#{id}"
      end

      def list_attributes
        ['id', 'name', 'type', 'url']
      end
    end
  end
end
```

- [ ] **Step 4: Run the test to verify it passes**

```bash
rspec spec/superset/tag/get_objects_spec.rb
```

Expected: 1 example, 0 failures

- [ ] **Step 5: Run the full suite and linter**

```bash
rake
```

Expected: all specs pass, no rubocop offenses

- [ ] **Step 6: Commit**

```bash
git add lib/superset/tag/get_objects.rb spec/superset/tag/get_objects_spec.rb
git commit -m "Add Tag::GetObjects to fetch objects associated with a tag"
```
