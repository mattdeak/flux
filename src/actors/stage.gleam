import actors/handler
import actors/message.{type Message}
import processors/processor
import gleam/erlang/process
import gleam/otp/actor
import record

/// A handler for a record. It is a transforming function that takes a record and returns a new record.
pub type Stage {
  Stage(handlers: List(handler.RecordHandler(Nil)))
}

pub fn new(handlers: List(handler.RecordHandler(Nil))) -> Stage {
  Stage(handlers)
}

pub fn add_handler(stage: Stage, handler: handler.RecordHandler(Nil)) -> Stage {
  Stage([handler, ..stage.handlers])
}

pub fn add_processor(stage: Stage, proc: processor.Processor(Nil)) -> Stage {
  add_handler(stage, handler.from_processor(proc))
}

/// This runs the stage as a single actor.
pub fn as_actor(stage: Stage, sink: process.Subject(Message)) {
  actor.start(Nil, fn(msg: Message, _: Nil) {
    case msg {
      Error(error) -> process.send(sink, message.from_error(error))
      Ok(rec) -> {
        run_all_handlers(rec, stage.handlers) |> process.send(sink, _)
      }
    }

    actor.continue(Nil)
  })
}

/// This spawns an actor that spawns tasks for each record
pub fn as_stage_runner(stage: Stage, sink: process.Subject(Message)) {
  actor.start(Nil, fn(msg: Message, _: Nil) {
    case msg {
      Error(error) -> {
        process.send(sink, message.from_error(error))
        Nil
      }
      Ok(rec) -> {
        process.start(
          fn() {
            run_all_handlers(rec, stage.handlers) |> process.send(sink, _)
          },
          linked: True,
        )
        Nil
      }
    }

    actor.continue(Nil)
  })
}

fn run_all_handlers(
  record: record.Record,
  handlers: List(handler.RecordHandler(Nil)),
) -> Result(record.Record, processor.ProcessorError) {
  case handlers {
    [] -> Ok(record)
    [handler, ..rest] ->
      case handler(record, Nil) {
        Error(error) -> Error(error)
        Ok(record) -> run_all_handlers(record, rest)
      }
  }
}
