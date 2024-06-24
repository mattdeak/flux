/// screw this lets just make it simple
import gleam/list
import gleam/string
import record.{type Record}
import gleam/option.{Some, None}

pub type ProcessorHandler(state) = fn(Record, state) -> Result(Record, ProcessorError)

pub type ProcessorError {
  TypeMismatch
  KeyNotFound
}

pub fn identity(record: Record) -> Record {
  record
}

pub fn count_num_a(
  rec: Record,
  key: String,
  field_name: String,
) -> Result(Record, ProcessorError) {
  case record.get_field(rec, key) {
    Some(a) -> {
      case a {
        record.DString(val) -> {
          let a_count =
            val
            |> string.to_graphemes
            |> list.filter(fn(c) { c == "a" })
            |> list.length
          Ok(record.add_field(rec, field_name, record.DInt(a_count)))
        }
        _ -> Error(TypeMismatch)
      }
    }
    None -> Error(KeyNotFound)
  }
}