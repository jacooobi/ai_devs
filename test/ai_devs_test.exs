defmodule AiDevsTest do
  use ExUnit.Case
  doctest AiDevs

  test "greets the world" do
    assert AiDevs.hello() == :world
  end
end
