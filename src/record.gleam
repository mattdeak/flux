import gleam/dict
import gleam/option.{Some, None, type Option}

pub type Value {
  DInt(Int)
  DString(String)
  DFloat(Float)
  DBool(Bool)
  DMap(dict.Dict(String, Value))
  DList(List(Value))
}


pub type Record {
    Record(record: dict.Dict(String, Value))
}


pub fn from_value(name: String, value: Value) -> Record {
  Record(dict.new() |> dict.insert(name, value))
}

pub fn from_dict(dict: dict.Dict(String, Value)) -> Record {
  Record(dict)
}

pub fn add_field(record: Record, name: String, value: Value) -> Record {
  Record(dict.insert(record.record, name, value))
}

pub fn get_field(record: Record, name: String) -> Option(Value) {
  case dict.get(record.record, name) {
    Ok(value) -> Some(value)
    Error(_) -> None
  }
}

pub fn new() -> Record {
  Record(dict.new())
}