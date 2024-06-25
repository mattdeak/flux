/// screw this lets just make it simple
import gleam/list
import gleam/option.{None, Some}
import gleam/string
import record.{type Record}

/// A stage is used to process a record through a series of handlers
/// It will almost always be deployed as an actor or multiple actors
pub type Processor(state) {
  RecordProcessor(fn(Record, state) -> Result(Record, ProcessorError))
  Aggregator(fn(List(Record), state) -> Result(Record, ProcessorError))
}

pub type ProcessorError {
  TypeMismatch
  KeyNotFound
}

pub fn from_fn_stateless(
  f: fn(Record) -> Result(Record, ProcessorError),
) -> Processor(Nil) {
  RecordProcessor(fn(rec, _) { f(rec) })
}

pub fn from_fn_stateful(
  f: fn(Record, state) -> Result(Record, ProcessorError),
) -> Processor(state) {
  RecordProcessor(fn(rec, state) { f(rec, state) })
}


pub fn identity() -> Processor(Nil) {
  RecordProcessor(fn(rec, _) { Ok(rec) })
}

pub fn count_num_a_processor(key: String, field_name: String) -> Processor(Nil) {
  RecordProcessor(fn(rec, _) { count_num_a(rec, key, field_name) })
}

pub fn is_get_request_processor() -> Processor(Nil) {
  RecordProcessor(fn(rec, _) { is_get_request(rec) })
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

fn is_get_request(rec: Record) -> Result(Record, ProcessorError) {
  case record.get_field(rec, "method") {
    Some(record.DString(val)) -> {
      Ok(record.add_field(rec, "is_get", record.DBool(val == "GET")))
    }
    _ -> Error(KeyNotFound)
  }
}
