/// screw this lets just make it simple
import gleam/list
import gleam/option.{None, Some}
import gleam/string
import record.{type Record}

/// A stage is used to process a record through a series of handlers
/// It will almost always be deployed as an actor or multiple actors
pub type Processor {
  RecordProcessor(fn(Record) -> Result(Record, ProcessorError))
}

pub type ProcessorError {
  TypeMismatch
  KeyNotFound
}

pub fn from_function(
  f: fn(Record) -> Result(Record, ProcessorError),
) -> Processor {
  RecordProcessor(f)
}

pub fn identity() -> Processor {
  RecordProcessor(fn(rec) { Ok(rec) })
}

pub fn count_num_a_processor(key: String, field_name: String) -> Processor {
  RecordProcessor(fn(rec) { count_num_a(rec, key, field_name) })
}

fn count_num_a(
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
