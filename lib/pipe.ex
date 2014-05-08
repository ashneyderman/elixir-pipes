
defmodule Pipe do
  @moduledoc """
  def inc(x), do: x + 1
  def double(x), do: x * 2
  
  1 |> inc |> double
  """
  defmacro __using__(_) do
    quote do
      import Pipe
    end
  end
  
  
  #     pipe_matching { :ok, _ }, x,
  #        ensure_protocol(protocol)
  #     |> change_debug_info(types)
  #     |> compile
  
  defmacro pipe_matching(expr, pipes) do
    quote do
      pipe_while(&(match? unquote(expr), &1), unquote pipes)
    end
  end

  #     pipe_while &(valid? &1), 
  #     json_doc |> transform |> transform

  defmacro pipe_while(test, pipes) do
    quote do
      case unquote(Enum.reduce Macro.unpipe(pipes), &(reduce_if &1, &2, test)) do
        {result, _} -> result
      end
    end
  end
  
  defp reduce_if( {x, pos}, acc, test ) do
    quote do
      {ac, _} = unquote acc
      case unquote(test).(ac) do
        true -> {unquote(Macro.pipe((quote do: ac), x, pos)), 0}
        false -> {ac, 0}
      end
    end
  end
  
  
  # a custom merge function that takes the piped function and an argument, 
  # and returns the accumulated value
  # pipe_with fn(f, acc) -> Enum.map(acc, f) end,
  #   [ 1, 2, 3] |> &(&1 + 1) |> &(&1 * 2)
  
  defmacro pipe_with(fun, pipes) do
    quote do
      case unquote(Enum.reduce Macro.unpipe(pipes), &(reduce_with &1, &2, fun)) do
        {result, _} -> result
      end
    end
  end

  defp reduce_with( {segment, pos}, acc, outer ) do
    quote do
      case unquote(acc) do
        {ac, pos} -> 
          {unquote(outer).(ac, fn(x) -> unquote Macro.pipe((quote do: x), segment, pos) end), 0}
      end
    end
  end 
end
