---
title: Tag::GetObjects
date: 2026-05-08
status: approved
---

# Tag::GetObjects Design

## Summary

Add `Superset::Tag::GetObjects` — a read-only GET class that fetches all objects (dashboards, charts, datasets, queries) associated with a given tag ID.

## API Endpoint

```
GET /api/v1/tag/get_objects/{id}
```

Response shape:
```json
{
  "result": [
    {
      "id": 0,
      "name": "string",
      "type": "string",
      "url": "string",
      "changed_on": "...",
      "creator": "string",
      "created_by": { "first_name": "string", "id": 0, "last_name": "string" },
      "owners": [...],
      "tags": [...]
    }
  ]
}
```

## Implementation

### `lib/superset/tag/get_objects.rb`

Inherits `Superset::Request`. Implements `route` and `list_attributes`. Uses default `result` (`response['result']`) and display/pagination from the base class.

- `initialize(id)` — accepts the tag ID
- `self.call(id)` — convenience class method
- `route` — returns `"tag/get_objects/#{id}"`
- `list_attributes` — `['id', 'name', 'type', 'url']`

No custom validation (consistent with `Tag::Get`).

## Testing

### `spec/superset/tag/get_objects_spec.rb`

- Stubs `result` with a sample array of mixed-type objects
- Asserts `rows` returns `[id, name, type, url]` tuples for each object
- Follows the same pattern as `spec/superset/tag/get_spec.rb`
