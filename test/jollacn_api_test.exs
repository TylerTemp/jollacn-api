defmodule JollaCNAPITest do
  use ExUnit.Case
  doctest JollaCNAPI

  test "greets the world" do
    assert JollaCNAPI.hello() == :world
  end
end
