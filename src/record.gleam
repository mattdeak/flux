import birl
import gleam/dict
import gleam/dynamic.{type Decoder as DynamicDecoder}
import gleam/option.{type Option, None, Some}
import gleam/result

/// A value in the record. 
/// This is a little bloated but it allows us to
/// compose handlers and processors in a way that's
/// easy to reason about without worrying too much about
/// the specifics of the implementation.
pub type SingleValueDType {
  DInt(Int)
  DString(String)
  DFloat(Float)
  DBool(Bool)
  DTime(birl.Time)
}

pub type Value {
  DSingleValue(SingleValueDType)
  DMap(dict.Dict(String, Value))
  DList(List(Value))
}

pub type SingleValueSchemaType {
  SInt
  SString
  SFloat
  SBool
  STime
}

pub type SchemaValue {
  SSingleValue(SingleValueSchemaType)
  SMap(String, SchemaValue)
  SList(SchemaValue)
}

/// Defines a schema for a record. This can be used to
/// validate that a record has the correct fields and types.
/// Or maybe later to plan out processing steps.
pub type Schema =
  dict.Dict(String, SchemaValue)

type DecoderResult =
  Result(Value, List(dynamic.DecodeError))

type Decoder =
  fn(dynamic.Dynamic) -> DecoderResult

fn schema_value_to_decoder(value: SchemaValue) -> Decoder {
  case value {
    SSingleValue(schema) -> decode_single_value(schema)
    SMap(_, value) -> {
      fn(dyn) {
        dyn
        |> dynamic.dict(of: dynamic.string, to: schema_value_to_decoder(value))
        |> result.map(DMap)
      }
    }

    SList(schema) -> {
      fn(dyn) {
        dyn
        |> dynamic.list(schema_value_to_decoder(schema))
        |> result.map(DList)
      }
    }
  }
}

fn converter(
  decoder: DynamicDecoder(t),
  constructor: fn(t) -> Result(SingleValueDType, List(dynamic.DecodeError)),
) -> Decoder {
  fn(dyn) {
    dyn |> decoder |> result.try(constructor) |> result.map(DSingleValue)
  }
}

fn decode_single_value(value: SingleValueSchemaType) -> Decoder {
  case value {
    SInt -> {
      converter(dynamic.int, fn(i) { Ok(DInt(i)) })
    }
    SString -> {
      converter(dynamic.string, fn(s) { Ok(DString(s)) })
    }
    SFloat -> {
      converter(dynamic.float, fn(f) { Ok(DFloat(f)) })
    }
    SBool -> {
      converter(dynamic.bool, fn(b) { Ok(DBool(b)) })
    }
    STime -> {
      let time_parser = fn(s: String) {
        case birl.parse(s) {
          Ok(time) -> Ok(DTime(time))
          Error(_) ->
            Error([
              dynamic.DecodeError(
                expected: "birl.Time",
                found: "String",
                path: [],
              ),
            ])
        }
      }
      converter(dynamic.string, time_parser)
    }
  }
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

pub fn from_dynamic(schema: Schema, dyn: dynamic.Dynamic) -> Record {
  let record = new()

  // We only accept dynamic records that are dictionaries
  dict.each(schema, fn(name, value) {
    let decoder = schema_value_to_decoder(value)

    dynamic.field(name, decoder)
  })

  case decoded {
    Ok(value) -> from_value(name, value)
    Error(errors) -> from_value(name, value)
  }
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
