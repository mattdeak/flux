import birl.{type Time}
import gleam/dict.{type Dict}
import gleam/dynamic.{type Dynamic}
import gleam/erlang/process.{type Subject}
import gleam/int
import gleam/option.{type Option, None, Some}
import gleam/otp/actor
import gleam/otp/supervisor.{type Children}
import gleam/result
import gleam/string

pub type Pipeline {
  Pipeline(manager: Subject(ManagerMessage))
}

pub type ManagerMessage {
  AddTransformation(Transformation)
  ProcessRecord(Record, Subject(Result(Record, Error)))
}

pub type Transformation {
  Transformation(
    name: String,
    transform: fn(Record, TransformationState) ->
      Result(#(Record, TransformationState), Error),
  )
}

pub type TransformationMessage {
  Transform(Record, Subject(Result(Record, Error)))
}

pub type TransformationState {
  TransformationState(data: Dynamic)
}

pub type Record {
  Record(fields: Dict(String, Value))
}

pub type Value {
  Int(Int)
  Float(Float)
  String(String)
  Bool(Bool)
  Time(Time)
  List(List(Value))
  Map(Dict(String, Value))
}

pub type Error {
  TransformError(String)
}

pub fn new(
  initial_transforms: List(Transformation),
) -> Result(Pipeline, supervisor.StartResult(ManagerMessage)) {
  case
    supervisor.worker(fn() {
      actor.start(Children(Nil), handle_manager_message)
    })
  {
    Ok(manager) -> Ok(Pipeline(manager))
    Error(e) -> Error(e)
  }
}

fn handle_manager_message(
  msg: ManagerMessage,
  children: Children(Nil),
) -> actor.Next(ManagerMessage, Children(Nil)) {
  case msg {
    AddTransformation(transformation) -> {
      let child_spec =
        supervisor.worker(fn() { start_transformation(transformation) })
      let updated_children = supervisor.add(children, child_spec)
      supervisor.Continue(updated_children)
    }
    ProcessRecord(record, reply_to) -> {
      process_through_transformations(record, children, [], fn(final_record) {
        actor.send(reply_to, Ok(final_record))
      })
      actor.continue(children)
      actor.send(reply_to, Ok(record))
      supervisor.continue(children)
    }
  }
}

fn start_transformation(
  transformation: Transformation,
) -> Result(Subject(TransformationMessage), actor.StartError) {
  actor.start(TransformationState(data: dynamic.from(Nil)), fn(msg, state) {
    case msg {
      Transform(record, reply) -> {
        case transformation.transform(record, state) {
          Ok(#(new_record, new_state)) -> {
            actor.send(reply, Ok(new_record))
            actor.continue(new_state)
          }
          Error(e) -> {
            actor.send(reply, Error(e))
            actor.continue(state)
          }
        }
      }
    }
  })
}

pub fn add(pipeline: Pipeline, transformation: Transformation) -> Nil {
  actor.send(pipeline.manager, AddTransformation(transformation))
}

pub fn process(pipeline: Pipeline, record: Record) -> Result(Record, Error) {
  actor.call(pipeline.manager, fn(reply) { ProcessRecord(record, reply) }, 5000)
}

fn process_through_transformations(
  record: Record,
  remaining_transformations: List(Subject(TransformationMessage)),
  processed_transformations: List(Subject(TransformationMessage)),
  on_complete: fn(Record) -> Nil,
) -> Nil {
  case remaining_transformations {
    [] -> on_complete(record)
    [next, ..rest] -> {
      actor.call(next, fn(reply) { Transform(record, reply) }, 5000)
      |> result.map(fn(new_record) {
        process_through_transformations(
          new_record,
          rest,
          [next, ..processed_transformations],
          on_complete,
        )
      })
      |> result.unwrap(on_complete(record))
    }
  }
}

// Example transformations
pub fn lowercase_field(field: String) -> Transformation {
  Transformation(name: "lowercase_" <> field, transform: fn(record, state) {
    case get_field(record, field) {
      Ok(String(value)) -> {
        let new_record =
          set_field(record, field, String(string.lowercase(value)))
        Ok(#(new_record, state))
      }
      _ -> Error(TransformError("Field is not a string: " <> field))
    }
  })
}

pub fn running_average(field: String) -> Transformation {
  Transformation(
    name: "running_average_" <> field,
    transform: fn(record, state) {
      case get_field(record, field) {
        Ok(Float(value)) -> {
          let #(count, sum) = dynamic.unsafe_coerce(state.data)
          let new_count = count + 1
          let new_sum = sum +. value
          let new_average = new_sum /. int.to_float(new_count)
          let new_record =
            set_field(record, field <> "_avg", Float(new_average))
          let new_state =
            TransformationState(data: dynamic.from(#(new_count, new_sum)))
          Ok(#(new_record, new_state))
        }
        _ -> Error(TransformError("Field is not a float: " <> field))
      }
    },
  )
}

pub type FieldNotFoundError {
  FieldNotFoundError(String)
}

pub fn get_field(
  record: Record,
  field: String,
) -> Result(Value, FieldNotFoundError) {
  dict.get(record.fields, field)
  |> result.map_error(fn(_) { FieldNotFoundError(field) })
}

pub fn set_field(record: Record, field: String, value: Value) -> Record {
  let update_fn = fn(_: Option(Value)) -> Value { value }

  Record(fields: dict.update(record.fields, field, update_fn))
}
