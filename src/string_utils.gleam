import gleam/int
import gleam/list
import gleam/string

pub fn get_random_string() -> String {
  let random_str_len: Int = int.random(10) + 5

  let alphabet =
    string.to_graphemes("abcdefghijklmnopqrstuvwxyz")
    |> list.shuffle
    |> string.join("")
  string.slice(alphabet, 0, random_str_len)
}
