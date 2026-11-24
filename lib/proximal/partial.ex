defmodule Proximal.Partial do
  @moduledoc ~S"""
  Supports parsing an XML document partially, chunk by chunk.
  """

  alias Proximal.ParseError
  alias Proximal.Parser
  alias Proximal.State

  @enforce_keys [:context_fun, :state]
  defstruct @enforce_keys

  @type t() :: %__MODULE__{
          context_fun: function(),
          state: term()
        }

  @doc """
  Builds up a `Proximal.Partial`, which can be used for later parsing.
  """
  @spec new(
          handler :: module(),
          initial_state :: term(),
          options :: Keyword.t()
        ) :: {:ok, partial :: t()} | {:error, exception :: ParseError.t()}
  def new(handler, initial_state, options \\ []) when is_atom(handler) do
    expand_entity = Keyword.get(options, :expand_entity, :keep)
    character_data_max_length = Keyword.get(options, :character_data_max_length, :infinity)
    cdata_as_characters = Keyword.get(options, :cdata_as_characters, true)
    continuous = Keyword.get(options, :continuous, false)

    state = %State{
      prolog: nil,
      handler: handler,
      user_state: initial_state,
      expand_entity: expand_entity,
      cdata_as_characters: cdata_as_characters,
      character_data_max_length: character_data_max_length,
      continuous: continuous
    }

    with {:halted, context_fun, state} <- Parser.Stream.parse_prolog(<<>>, true, <<>>, 0, state) do
      {:ok, %__MODULE__{context_fun: context_fun, state: state}}
    end
  end

  @doc """
  Continue parsing next chunk of the document with a partial.
  """
  @spec parse(partial :: t(), data :: binary()) ::
          {:cont, partial :: t()}
          | {:halt, state :: term()}
          | {:halt, state :: term(), rest :: binary()}
          | {:error, exception :: ParseError.t()}
  def parse(%__MODULE__{context_fun: context_fun, state: state} = partial, data)
      when is_binary(data) do
    case context_fun.(data, true, state) do
      {:halted, context_fun, state} ->
        {:cont, %{partial | context_fun: context_fun, state: state}}

      {:ok, state} ->
        {:halt, state.user_state}

      {:halt, state, {buffer, pos}} ->
        rest = binary_part(buffer, pos, byte_size(buffer) - pos)
        {:halt, state.user_state, rest}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Same as `parse/2`, but continues with a new `user_state`.
  """
  @spec parse(partial :: t(), data :: binary(), user_state :: term()) ::
          {:cont, partial :: t()}
          | {:halt, state :: term()}
          | {:halt, state :: term(), rest :: binary()}
          | {:error, exception :: ParseError.t()}
  def parse(%__MODULE__{} = partial, data, user_state) do
    partial = set_user_state(partial, user_state)
    parse(partial, data)
  end

  @doc """
  Terminates the XML document parsing.
  """
  @spec terminate(partial :: t()) ::
          {:ok, state :: term()} | {:error, exception :: ParseError.t()}
  def terminate(%__MODULE__{context_fun: context_fun, state: state}) do
    with {:ok, state} <- context_fun.(<<>>, false, state) do
      {:ok, state.user_state}
    end
  end

  @doc """
  Obtain the state set by the user.
  """
  @spec get_state(partial :: t()) :: term()
  def get_state(%__MODULE__{state: %{user_state: user_state}}), do: user_state

  defp set_user_state(%__MODULE__{state: state} = partial, user_state) do
    %{partial | state: %{state | user_state: user_state}}
  end
end
