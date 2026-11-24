defmodule Proximal.Parser do
  @moduledoc false

  alias Proximal.ParseError
  alias Proximal.State

  defmodule Binary do
    @moduledoc false

    use Proximal.Parser.Builder, streaming?: false
  end

  defmodule Stream do
    @moduledoc false

    use Proximal.Parser.Builder, streaming?: true
  end

  @doc """
  Parses an XML binary using the given `handler` and `initial_state`.
  """
  @spec parse_string(binary(), module(), term(), keyword()) ::
          {:ok, term()} | {:halt, term(), binary()} | {:error, ParseError.t()}
  def parse_string(data, handler, initial_state, options \\ [])
      when is_binary(data) and is_atom(handler) and is_list(options) do
    expand_entity = Keyword.get(options, :expand_entity, :keep)
    character_data_max_length = Keyword.get(options, :character_data_max_length, :infinity)
    cdata_as_characters = Keyword.get(options, :cdata_as_characters, true)

    state = %State{
      prolog: nil,
      handler: handler,
      user_state: initial_state,
      expand_entity: expand_entity,
      cdata_as_characters: cdata_as_characters,
      character_data_max_length: character_data_max_length
    }

    case Binary.parse_prolog(data, false, data, 0, state) do
      {:ok, state} ->
        {:ok, state.user_state}

      {:halt, state, {buffer, pos}} ->
        rest = binary_part(buffer, pos, byte_size(buffer) - pos)
        {:halt, state.user_state, rest}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc false
  def parse_error(buffer, position, _state, reason) do
    {
      :error,
      %ParseError{
        reason: reason,
        binary: buffer,
        position: position
      }
    }
  end

  @doc false
  def compute_char_len(char) do
    cond do
      char <= 0x7F -> 1
      char <= 0x7FF -> 2
      char <= 0xFFFF -> 3
      true -> 4
    end
  end

  @doc false
  def valid_pi_name?(<<l::integer, m::integer, x::integer>>)
      when x in [?X, ?x] or m in [?M, ?m] or l in [?L, ?l],
      do: false

  def valid_pi_name?(<<_::bits>>), do: true

  @doc false
  def valid_encoding?(encoding) do
    String.upcase(encoding, :ascii) == "UTF-8"
  end
end
