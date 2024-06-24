import gleam/erlang/process
import gleam/int
import gleam/list
import gleam/otp/actor
import gleam/string
import record

pub type State {
  State(wait_time: RandomWait, recipient: process.Subject(record.Record))
}

pub type Message {
  Shutdown
  Generate
}

pub type RandomWait {
  Constant(Int)
  Function(fn() -> Int)
}


pub fn start_random_generator(
  wait_time: RandomWait,
  recipient: process.Subject(record.Record),
) -> Result(process.Subject(Message), actor.StartError) {
  let init = fn() {
    let subject = process.new_subject()
    let selector =
      process.new_selector() |> process.selecting(subject, fn(msg) { msg })
    // kicks off loop
    process.send(subject, Generate)

    actor.Ready(subject, selector)
  }

  let loop = fn(msg, subject) {
    case msg {
      Generate -> {
        let random_str = get_random_string()
        process.send(recipient, record.from_value("random_string", record.DString(random_str)))
        enqueue_generate(subject, wait_time)
        actor.continue(subject)
      }
      Shutdown -> actor.Stop(process.Normal)
    }
  }

  actor.start_spec(actor.Spec(init: init, loop: loop, init_timeout: 1000))
}

fn enqueue_generate(subject, wait_time: RandomWait) {
  let wait_time = case wait_time {
    Constant(val) -> val
    Function(f) -> f()
  }
  process.send_after(subject, wait_time, Generate)
}

fn get_random_string() -> String {
  let random_str_len: Int = int.random(10) + 5

  let alphabet =
    string.to_graphemes("abcdefghijklmnopqrstuvwxyz")
    |> list.shuffle
    |> string.join("")
  string.slice(alphabet, 0, random_str_len)
}
