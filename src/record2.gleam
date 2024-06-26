pub type Schema {
  Schema(fields: Map(String, SchemaType))
}

pub type PartialSchema {
  PartialSchema(fields: Map(String, SchemaType))
}

pub type SchemaType {
  SInt
  SFloat
  SString
  SBool
  STime
  SList(SchemaType)
  SMap(Schema)
}

pub opaque type Record(s) {
  Record(schema: s, values: Map(String, Value))
}

pub type Value {
  VInt(Int)
  VFloat(Float)
  VString(String)
  VBool(Bool)
  VTime(Time)
  VList(List(Value))
  VMap(Map(String, Value))
}

pub fn get_field(record: Record, field: String) -> Result(Value, Error) {
  case record.values.get(field) {
    Some(value) -> Ok(value)
    None -> Error("Field not found")
  }
}
