import actors/input
import actors/processor
import actors/stage
import gleam/erlang/process
import gleam/io
import gleam/otp/actor
import record

pub fn main() {
  // The backwards construction feels a little weird to me
  let assert Ok(sink) = actor.start(Nil, handle_recipient)

  let stage1 =
    stage.new([])
    |> stage.add_processor(processor.identity())
    |> stage.add_processor(processor.count_num_a_processor(
      "random_string",
      "a_count",
    ))
  let assert Ok(stage1_actor) = stage.as_actor(stage1, sink)

  let assert Ok(_) =
    input.start_random_generator(input.Constant(1000), stage1_actor)

  process.sleep_forever()
}

fn handle_recipient(
  msg: Result(record.Record, processor.ProcessorError),
  state: Nil,
) -> actor.Next(Result(record.Record, processor.ProcessorError), Nil) {
  io.debug(msg)
  actor.continue(state)
}
