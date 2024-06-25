import actors/input
import processors/processor
import actors/stage
import birl
import gleam/erlang/process
import gleam/float
import gleam/int
import gleam/io
import gleam/otp/actor
import record

pub type Stats {
  Stats(processed: Int, errors: Int, last_timestamp: Int)
}

pub fn main() {
  // The backwards construction feels a little weird to me
  let assert Ok(sink) = actor.start(Stats(0, 0, 0), handle_recipient)

  let stage1 =
    stage.new([])
    |> stage.add_processor(processor.identity())
    |> stage.add_processor(processor.is_get_request_processor())
    |> stage.add_processor(processor.count_num_a_processor("path", "a_count"))
  let assert Ok(stage1_actor) = stage.as_stage_runner(stage1, sink)

  let assert Ok(_) =
    input.start_random_http_generator(input.Constant(1), stage1_actor)

  process.sleep_forever()
}

fn handle_recipient(
  msg: Result(record.Record, processor.ProcessorError),
  state: Stats,
) -> actor.Next(Result(record.Record, processor.ProcessorError), Stats) {
  let new_state = case msg {
    Ok(_) -> Stats(..state, processed: state.processed + 1)
    Error(_) -> Stats(..state, errors: state.errors + 1)
  }

  // Calculate throughput every 1000 messages
  case new_state.processed % 1000 == 0 {
    True -> {
      let now = birl.now() |> birl.to_unix
      let throughput =
        int.to_float(new_state.processed)
        /. int.to_float(now - state.last_timestamp)
      io.debug("Throughput: " <> float.to_string(throughput) <> " msgs/sec")
      actor.continue(Stats(..new_state, last_timestamp: now))
    }
    False -> actor.continue(new_state)
  }

  actor.continue(new_state)
}
