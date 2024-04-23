class ObjectType < EnumerateIt::Base
# replicates the Superset Core code base enum for Object Types
# https://github.com/apache/superset/blob/40e77be813c789c8b01aece739f32ff5753436b4/superset/tags/models.py#L79

  associate_values(
    query:   1,
    chart:  2,
    dashboard: 3,
    dataset: 4
  )
end
