import gleam/record2.{type PartialSchema, type Record}

pub type Transformation {
  Transformation(
    id: String,
    requires: Transformation,
    produced_fields: PartialSchema,
    transform: fn(Record, state) -> Result(Record, String),
  )
}

pub fn field_operation(
  field: String,
  operation: fn(Value, state) -> Result(Value, String),
) -> Transformation {
  Transformation(
    required_fields: PartialSchema(fields: Map.from_list([#(field, SAny)])),
    produced_fields: PartialSchema(fields: Map.from_list([#(field, SAny)])),
    transform: fn(record) {
      case get_value(record, field) {
        Ok(value) -> {
          case operation(value) {
            Ok(new_value) -> set_value(record, field, new_value)
            Error(e) -> Error(e)
          }
        }
        Error(e) -> Error(e)
      }
    },
  )
}
