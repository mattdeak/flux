import actors/message
import actors/stage
import gleam/erlang/process

// temporary until I figure out a better way to type this
pub type InputStream =
  fn(process.Subject(message.Message)) -> Nil

pub type Pipeline {
  Pipeline(
    inputs: List(InputStream),
    stages: List(stage.Stage),
    outputs: List(fn(process.Subject(message.Message)) -> Nil),
  )
}

pub fn new() -> Pipeline {
  Pipeline([], [], [])
}

pub fn add_input(pipeline: Pipeline, input: InputStream) -> Pipeline {
  todo
}
